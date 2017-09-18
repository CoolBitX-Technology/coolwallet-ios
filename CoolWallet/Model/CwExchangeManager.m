//
//  CwExchange.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/12.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "CwExchangeManager.h"
#import "CwExchangeSettings.h"
#import "CwCard.h"
#import "CwManager.h"
#import "NSString+HexToData.h"
#import "APPData.h"
#import "CwExTx.h"
#import "CwBtc.h"
#import "CwTx.h"
#import "CwTxin.h"
#import "CwAddress.h"
#import "CwExUnblock.h"
#import "CwExOpenOrder.h"
#import "CwExchange.h"
#import "CwExSellOrder.h"
#import "CwExBuyOrder.h"
#import "CwBase58.h"
#import "CwBlockInfo.h"

#import "NSUserDefaults+RMSaveCustomObject.h"

@interface CwExchangeManager()

@property (readwrite, assign) ExSessionStatus sessionStatus;

@property (readwrite, nonatomic) CwCard *card;
@property (strong, nonatomic) NSString *loginSession;

@property (readwrite, nonatomic) CwExchange *exchange;

@property (strong, nonatomic) NSMutableArray *syncedAccount;
@property (readwrite, nonatomic) BOOL cardInfoSynced;

@property (strong, nonatomic) NSString *txReceiveAddress;
@property (strong, nonatomic) NSData *txLoginHandle;

@end

@implementation CwExchangeManager

+(id)sharedInstance
{
    static dispatch_once_t pred;
    static CwExchangeManager *sharedInstance = nil;
    if (enableExchangeSite) {
        dispatch_once(&pred, ^{
            sharedInstance = [[CwExchangeManager alloc] init];
        });
    }
    return sharedInstance;
}

-(id) init
{
    self = [super init];
    if (self) {
        [self observeConnectedCard];
    }
    
    return self;
}

-(BOOL) isCardLoginEx:(NSString *)cardId
{
    return self.sessionStatus == ExSessionLogin && self.card.cardId == cardId;
}

-(void) observeConnectedCard
{
    @weakify(self)
    CwManager *manager = [CwManager sharedManager];
    RAC(self, card) = [RACObserve(manager, connectedCwCard) filter:^BOOL(CwCard *card) {
        @strongify(self)
        BOOL changed = ![card.cardId isEqualToString:self.card.cardId];
        
        if (changed && self.card.cardId != nil && self.exchange != nil) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults rm_setCustomObject:self.exchange forKey:[NSString stringWithFormat:@"exchange_%@", self.card.cardId]];
        }
        
        return changed;
    }];
    
    [[RACObserve(self, card) distinctUntilChanged] subscribeNext:^(CwCard *card) {
        @strongify(self)
        self.syncedAccount = [NSMutableArray new];
        self.cardInfoSynced = NO;
        
        if (self.sessionStatus != ExSessionNone && self.sessionStatus != ExSessionFail) {
            [self logoutExSession];
        }
        self.sessionStatus = ExSessionNone;
        self.loginSession = nil;
        self.exchange = nil;
    }];
}

-(void) loginExSession
{
    @weakify(self);
    [[self loginSignal] subscribeNext:^(id cardResponse) {
        @strongify(self);
        self.sessionStatus = ExSessionLogin;
    } error:^(NSError *error) {
        @strongify(self);
        NSLog(@"error(%ld): %@", (long)error.code, error);
        self.sessionStatus = ExSessionFail;
        [self logoutExSession];
    }];
    
    __block RACDisposable *disposable = [[[[RACObserve(self, sessionStatus) filter:^BOOL(NSNumber *status) {
        return status.intValue == ExSessionLogin || status.intValue == ExSessionFail;
    }] take:1] delay:0.2] subscribeNext:^(NSNumber *status) {
        if (status.intValue == ExSessionLogin) {
            self.exchange = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:[NSString stringWithFormat:@"exchange_%@", self.card.cardId]];
            if (self.exchange == nil) {
                self.exchange = [CwExchange new];
            }
            
            [self syncCardInfo];
        } else {
            [disposable dispose];
        }
    } error:^(NSError *error) {
        
    }];
}

-(void) logoutExSession
{
    if (self.card.mode.integerValue == CwCardModeNormal || self.card.mode.integerValue == CwCardModeAuth) {
        [self.card exSessionLogout];
    }
    
    AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
    [manager GET:ExSessionLogout parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        
    }];
}

-(void) syncCardInfo
{
    self.cardInfoSynced = NO;
    
    [self observeHdwAccountPointer];
    for (CwAccount *account in [self.card.cwAccounts allValues]) {
        if (!account.infoSynced) {
            [self.card getAccountInfo:account.accId];
        }
    }
}

-(void) requestOpenOrders
{
    NSString *url = [NSString stringWithFormat:ExGetOrders, self.card.cardId];
    AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSArray *responseObject) {
        NSArray *openOrders = [RMMapper arrayOfClass:[CwExOpenOrder class] fromArrayOfDictionary:responseObject];
        
        self.exchange.openOrders = [NSMutableArray arrayWithArray:openOrders];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        
    }];
}

-(void) requestPendingOrders
{
    NSString *url = [NSString stringWithFormat:ExGetPendingOrders, self.card.cardId];
    AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
        [RMMapper populateObject:self.exchange fromDictionary:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        
    }];
}

-(void) requestMatchedOrder:(NSString *)orderId
{
    NSString *url = [NSString stringWithFormat:ExGetPendingOrders, self.card.cardId];
    [url stringByAppendingFormat:@"/%@", orderId];
    
    AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
        if ([responseObject objectForKey:@"sell"] != nil) {
            CwExSellOrder *sell = [CwExSellOrder new];
            [RMMapper populateObject:sell fromDictionary:[responseObject objectForKey:@"sell"]];
            [self.exchange.pendingSellOrders addObject:sell];
        } else if ([responseObject objectForKey:@"buy"] != nil) {
            CwExBuyOrder *buy = [CwExBuyOrder new];
            [RMMapper populateObject:buy fromDictionary:[responseObject objectForKey:@"buy"]];
            [self.exchange.pendingBuyOrders addObject:buy];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        
    }];
}

-(void) blockWithOrderID:(NSString *)hexOrderID withOTP:(NSString *)otp withSuccess:(void(^)(void))successCallback error:(void(^)(NSError *error))errorCallback finish:(void(^)(void))finishCallback
{
    RACSignal *blockSignal = [self signalRequestOrderBlockWithOrderID:hexOrderID withOTP:otp];
    
    [[[[[blockSignal flattenMap:^RACStream *(NSString *blockData) {
        return [self signalBlockBTCFromCard:blockData];
    }] flattenMap:^RACStream *(NSDictionary *data) {
        NSString *okToken = [data objectForKey:@"okToken"];
        NSString *unblockToken = [data objectForKey:@"unblockToken"];
        
        return [self signalWriteOKTokenToServer:okToken unblockToken:unblockToken withOrder:hexOrderID];
    }] finally:^() {
        if (finishCallback) {
            finishCallback();
        }
    }] deliverOnMainThread]
     subscribeNext:^(id value) {
        if (successCallback) {
            successCallback();
        }
    } error:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
    }];
}

-(void) prepareTransactionFromSellOrder:(CwExSellOrder *)sellOrder withChangeAddress:(CwAddress *)changeAddress
{
    sellOrder.exTrx.changeAddress = changeAddress;
    
    @weakify(self)
    [[[[[[self signalGetTrxInfoFromOrder:sellOrder.orderId] flattenMap:^RACStream *(NSDictionary *response) {
        NSLog(@"response: %@", response);
        @strongify(self)
        NSString *loginData = [response objectForKey:@"loginblk"];
        sellOrder.exTrx.receiveAddress = [response objectForKey:@"out1addr"];
        
        if (!loginData) {
            return [RACSignal error:[NSError errorWithDomain:@"Exchange site error." code:1001 userInfo:@{@"error": @"Fail to get transaction data from exchange site."}]];
        }
        
        return [self signalTrxLogin:loginData];
    }] flattenMap:^RACStream *(NSData *trxHandle) {
        NSString *changeAddress = sellOrder.exTrx.changeAddress.address;
        
        sellOrder.exTrx.loginHandle = trxHandle;
        sellOrder.exTrx.unsignedTx = [self.card getUnsignedTransaction:sellOrder.exTrx.amount.satoshi.longLongValue Address:sellOrder.exTrx.receiveAddress Change:changeAddress AccountId:sellOrder.exTrx.accountId];
        if (sellOrder.exTrx.unsignedTx == nil) {
            return [RACSignal error:[NSError errorWithDomain:@"Exchange site error." code:1002 userInfo:@{@"error": @"Check unsigned data error."}]];
        } else {
            return [self signalTrxPrepareDataFrom:sellOrder];
        }
    }] finally:^() {
        [self logoutTransactionWith:sellOrder];
        
        CwAccount *account = [self.card.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", sellOrder.exTrx.accountId]];
        account.tempUnblockAmount = 0;
    }] deliverOnMainThread]
     subscribeNext:^(id value) {
        NSLog(@"Ex Trx prepairing...");
    } error:^(NSError *error) {
        NSLog(@"Ex Trx prepaire fail: %@", error);
        if ([self.card.delegate respondsToSelector:@selector(didPrepareTransactionError:)]) {
            if (error.userInfo) {
                [self.card.delegate didPrepareTransactionError:[error.userInfo objectForKey:@"error"]];
            } else {
                [self.card.delegate didPrepareTransactionError:@"Fail to get transaction data from exchange site."];
            }
        }
    }];
}

-(void) completeTransactionWith:(CwExSellOrder *)sellOrder
{
    if (!sellOrder.exTrx.loginHandle) {return;}
    
    [self.card exTrxSignLogoutWithTrxHandle:sellOrder.exTrx.loginHandle Nonce:sellOrder.exTrx.nonce withComplete:^(NSData *receipt) {
        NSString *url = [NSString stringWithFormat:ExTrx, sellOrder.orderId];
        NSDictionary *dict = @{@"inputs": [NSNumber numberWithInteger:sellOrder.exTrx.unsignedTx.inputs.count],
                               @"bcTrxId": sellOrder.exTrx.trxId,
                               @"changeAddr": sellOrder.exTrx.changeAddress.address,
                               @"trxReceipt": [NSString dataToHexstring:receipt],
                               @"uid": self.card.uid,
                               @"nonce": [NSString dataToHexstring:sellOrder.exTrx.nonce]};
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager POST:url parameters:dict success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            NSLog(@"Success send txId to ex site.");
            
            if (self.exchange.pendingSellOrders != nil && self.exchange.pendingSellOrders.count > 0) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.orderId == %@", sellOrder.orderId];
                NSArray *result = [self.exchange.pendingSellOrders filteredArrayUsingPredicate:predicate];
                if (result.count > 0) {
                    for (CwExSellOrder *sellOrder in result) {
                        sellOrder.submitted = [NSNumber numberWithBool:YES];
                    }
                }
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            NSLog(@"Fail send txId to ex site.");
            // TODO: should resend to exchange site?
        }];
    } error:^(NSInteger errorCode) {
        
    }];
}

-(void) logoutTransactionWith:(CwExSellOrder *)sellOrder
{
    if (!sellOrder.exTrx.loginHandle) {return;}
    
    [self.card exTrxSignLogoutWithTrxHandle:sellOrder.exTrx.loginHandle Nonce:sellOrder.exTrx.nonce withComplete:^(NSData *receipt) {
        
    } error:^(NSInteger errorCode) {
        
    }];
}

-(void) unblockOrderWithOrderId:(NSString *)orderId
{
    RACSignal *unblockSignal = [self signalRequestUnblockInfoWithOrderId:orderId];
    
    [[unblockSignal flattenMap:^RACStream *(CwExUnblock *unblock) {
        return [self signalUnblock:unblock];
    }] subscribeNext:^(id value) {
        
    } error:^(NSError *error) {
        
    }];
}

-(void) cancelOrderWithOrderId:(NSString *)orderId withSuccess:(void(^)(void))successCallback error:(void(^)(NSError *error))errorCallback
{
    @weakify(self);
    [[[[[self signalGetTrxInfoFromOrder:orderId]
     flattenMap:^RACStream *(NSDictionary *response) {
        @strongify(self)
        NSString *loginData = [response objectForKey:@"loginblk"];
        NSData *okToken = [NSString hexstringToData:[loginData substringWithRange:NSMakeRange(8, 8)]];
        
        if (!loginData) {
            return [RACSignal error:[NSError errorWithDomain:@"Exchange site error." code:1001 userInfo:@{@"error": @"Fail to get transaction data from exchange site."}]];
        }
        
        return [self signalCardBlockInfo:okToken];
    }]
    flattenMap:^RACStream *(CwBlockInfo *blockInfo) {
        if (blockInfo.blockStatus == BlockWithoutLogin) {
            return [self signalCancelOrder:orderId];
        } else if (blockInfo.blockStatus == BlockWithLogin) {
            return [self signalCancelTrx:orderId];
        } else {
            return [RACSignal empty];
        }
    }] deliverOnMainThread]
    subscribeNext:^(id x) {
        if (successCallback) {
            successCallback();
        }
    } error:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
    } completed:^{
        [self requestPendingOrders];
    }];
}

-(void) observeHdwAccountPointer
{
    RACSignal *accountNumberSignal = [[RACObserve(self, card) map:^id(CwCard *card) {
        return RACObserve(card, hdwAcccountPointer);
    }] switchToLatest];
    
    @weakify(self);
    [[[accountNumberSignal distinctUntilChanged] skipUntilBlock:^BOOL(NSNumber *counter) {
        @strongify(self)
        return self.sessionStatus == ExSessionLogin;
    }] subscribeNext:^(NSNumber *counter) {
        @strongify(self);
        NSLog(@"observeHdwAccountPointer: %@", counter);
        for (int index = (int)self.syncedAccount.count; index < counter.intValue; index++) {
            CwAccount *account = [self.card.cwAccounts objectForKey:[NSString stringWithFormat:@"%d", index]];
            if (account) {
                [self observeAccount:account];
                [self observeHdwAccountAddrCount:account];
            }
        }
    }];
}

-(void) observeAccount:(CwAccount *)account
{
    if (self.sessionStatus != ExSessionLogin) {
        return;
    }
    
    @weakify(self);
    __block RACDisposable *disposable = [[[RACObserve(account, infoSynced) distinctUntilChanged] filter:^BOOL(NSNumber *synced) {
        @strongify(self);
        return synced.boolValue && ![self.syncedAccount containsObject:account];
    }] subscribeNext:^(NSNumber *synced) {
        @strongify(self);
        NSLog(@"account: %ld, synced: %d, self.syncAccountCount = %lu", (long)account.accId, synced.boolValue, (unsigned long)self.syncedAccount.count);
        
        [self.syncedAccount addObject:account];
        
        if (self.syncedAccount.count == self.card.cwAccounts.count) {
            [[self signalSyncCardInfo] subscribeNext:^(NSDictionary *response) {
                NSLog(@"sync: %@", response);
                self.cardInfoSynced = YES;
            } error:^(NSError *error) {
                NSLog(@"sync error: %@", error);
                [self.syncedAccount removeAllObjects];
            }];
        }
        
        [disposable dispose];
    }];
}

-(void) observeHdwAccountAddrCount:(CwAccount *)account
{
    @weakify(self)
    RACSignal *signal = [[[RACSignal combineLatest:@[RACObserve(account, extKeyPointer), RACObserve(account, intKeyPointer)]
                                          reduce:^(NSNumber *extCount, NSNumber *intCount) {
                                              int counter = (extCount.intValue + intCount.intValue);
                                              return @(counter);
                                          }] skipWhileBlock:^BOOL(NSNumber *counter) {
                                              @strongify(self)
                                              return counter.intValue * self.cardInfoSynced <= 0;
                                          }] distinctUntilChanged];
    
    __block RACDisposable *disposable = [[signal flattenMap:^RACStream *(NSArray *counter) {
        @strongify(self)
        return [self signalSyncAccountInfo:account];
    }] subscribeNext:^(id response) {
        NSLog(@"sync account %ld completed: %@", (long)account.accId, response);
    } error:^(NSError *error) {
        NSLog(@"sync account error: %@", error);
    }];
    
    [account.rac_willDeallocSignal subscribeNext:^(id value) {
        NSLog(@"%@ will dealloc", value);
        [disposable dispose];
    }];
}

# pragma mark - signals

-(RACSignal *)loginSignal
{
    @weakify(self);
    RACSignal *signal = [[[[self signalCreateExSession] flattenMap:^RACStream *(NSDictionary *response) {
        @strongify(self);
        NSString *hexString = [response objectForKey:@"challenge"];
        
        return [self signalInitSessionFromCard:[NSString hexstringToData:hexString]];
    }] flattenMap:^RACStream *(NSDictionary *cardResponse) {
        @strongify(self);
        NSData *seResp = [cardResponse objectForKey:@"seResp"];
        NSData *seChlng = [cardResponse objectForKey:@"seChlng"];
        
        return [self signalEstablishExSessionWithChallenge:seChlng andResponse:seResp];
    }] flattenMap:^RACStream *(NSDictionary *response) {
        @strongify(self);
        NSString *hexString = [response objectForKey:@"response"];
        
        return [self signalEstablishSessionFromCard:[NSString hexstringToData:hexString]];
    }];
    
    return signal;
}

-(RACSignal*)signalCreateExSession {
    __block NSString *url = [NSString stringWithFormat:ExSession, self.card.cardId];
    
    @weakify(self);
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            self.loginSession = [operation.response.allHeaderFields objectForKey:@"Set-Cookie"];
            
            NSString *hexString = [responseObject objectForKey:@"challenge"];
            if (hexString.length == 0) {
                [subscriber sendError:[NSError errorWithDomain:@"Not exchange site member." code:NotRegistered userInfo:nil]];
            } else {
                [subscriber sendNext:responseObject];
                [subscriber sendCompleted];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }] doNext:^(id value) {
        self.sessionStatus = ExSessionProcess;
    }];
    
    return signal;
}

-(RACSignal *)signalInitSessionFromCard:(NSData *)srvChlng
{
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        [self.card exSessionInit:srvChlng withComplete:^(NSData *seResp, NSData *seChlng) {
            NSLog(@"seResp: %@, seChlng: %@", seResp, seChlng);
            
            [subscriber sendNext:@{@"seResp": seResp, @"seChlng": seChlng}];
            [subscriber sendCompleted];
        } withError:^(NSInteger errorCode) {
            [subscriber sendError:[self cardCmdError:errorCode errorMsg:@"Card init session fail."]];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal*)signalEstablishExSessionWithChallenge:(NSData *)challenge andResponse:(NSData *)response {
    __block NSString *url = [NSString stringWithFormat:ExSession, self.card.cardId];
    __block NSDictionary *dict = @{@"challenge": [NSString dataToHexstring:challenge], @"response": [NSString dataToHexstring:response]};
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager POST:url parameters:dict success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal *)signalEstablishSessionFromCard:(NSData *)svrResp
{
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        [self.card exSessionEstab:svrResp withComplete:^() {
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        } withError:^(NSInteger errorCode) {
            NSError *error = [NSError errorWithDomain:@"Card Cmd Error" code:errorCode userInfo:nil];
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal*)signalSyncCardInfo {
    __block NSString *url = [NSString stringWithFormat:ExSyncCardInfo, self.card.cardId];
    
    __block NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:@"ios" forKey:@"devType"];
    [dict setObject:[APPData sharedInstance].deviceToken forKey:@"token"];
    
    NSMutableArray *accountDatas = [NSMutableArray new];
    for (CwAccount *account in [self.card.cwAccounts allValues]) {
        [accountDatas addObject:[self getAccountInfo:account]];
    }
    [dict setObject:accountDatas forKey:@"accounts"];
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager POST:url parameters:dict success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal*)signalSyncAccountInfo:(CwAccount *)account {
    __block NSString *url = [NSString stringWithFormat:ExSyncAccountInfo, self.card.cardId, (long)account.accId];
    
    __block NSDictionary *dict = [self getAccountInfo:account];
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager POST:url parameters:dict success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal *)signalRequestOrderBlockWithOrderID:(NSString *)hexOrder withOTP:(NSString *)otp
{
    __block NSString *url = [NSString stringWithFormat:ExTrxOrderBlock, hexOrder, otp];
    
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            
            NSString *blockData = [responseObject objectForKey:@"block_btc"];
            [subscriber sendNext:blockData];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal *)signalBlockBTCFromCard:(NSString *)blockData
{
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        [self.card exBlockBtc:blockData withComplete:^(NSData *okToken, NSData *unblockToken) {
            NSDictionary *data = @{
                                   @"okToken": [NSString dataToHexstring:okToken],
                                   @"unblockToken": [NSString dataToHexstring:unblockToken],
                                   };
            [subscriber sendNext:data];
            [subscriber sendCompleted];
        } error:^(NSInteger errorCode) {
            [subscriber sendError:[self cardCmdError:errorCode errorMsg:@"Block fail."]];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal *)signalWriteOKTokenToServer:(NSString *)okToken unblockToken:(NSString *)unblockToken withOrder:(NSString *)orderId
{
    __block NSString *url = [NSString stringWithFormat:ExWriteOKToken, orderId];
    __block NSDictionary *dict = @{
                           @"okToken": okToken,
                           @"unblockToken": unblockToken,
                           };
    
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager POST:url parameters:dict success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal *)signalTrxLogin:(NSString *)loginData
{
    @weakify(self)
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        NSData *okToken = [NSString hexstringToData:[loginData substringWithRange:NSMakeRange(8, 8)]];
        NSData *accountData = [NSString hexstringToData:[loginData substringWithRange:NSMakeRange(48, 8)]];
        NSInteger accId = *(int32_t *)[accountData bytes];
        
        [self.card exBlockInfo:okToken withComplete:^(CwBlockInfo *blockInfo) {
            CwAccount *account = [self.card.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", accId]];
            account.tempUnblockAmount = blockInfo.blockAmount.longLongValue;
            
            [subscriber sendNext:loginData];
            [subscriber sendCompleted];
        } withError:^(NSInteger errorCode) {
            [subscriber sendError:[self cardCmdError:errorCode errorMsg:@"Get block info fail."]];
        }];
        
        return nil;
    }] flattenMap:^RACStream *(NSString *loginHexData) {
        RACSignal *loginSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            @strongify(self);
            [self.card exTrxSignLogin:loginHexData withComplete:^(NSData *loginHandle) {
                [subscriber sendNext:loginHandle];
                [subscriber sendCompleted];
            } error:^(NSInteger errorCode) {
                [subscriber sendError:[self cardCmdError:errorCode errorMsg:@"Transaction login fail."]];
            }];
            
            return nil;
        }];
        
        return loginSignal;
    }];
    
    return signal;
}

-(RACSignal*)signalGetTrxInfoFromOrder:(NSString *)orderId
{
    __block NSString *url = [NSString stringWithFormat:ExGetTrxInfo, orderId];
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal *)signalTrxPrepareDataFrom:(CwExSellOrder *)sellOrder
{
    __block NSString *url = [NSString stringWithFormat:ExGetTrxPrepareBlocks, sellOrder.orderId];
    
    CwTx *unsignedTx = sellOrder.exTrx.unsignedTx;
    NSMutableArray *inputBlocks = [NSMutableArray new];
    for (int index=0; index < unsignedTx.inputs.count; index++) {
        CwTxin *txin = unsignedTx.inputs[index];
        NSData *inputData = [self composePrepareInputData:index
                                               KeyChainId:txin.kcId
                                                AccountId:txin.accId
                                                    KeyId:txin.kId
                                           receiveAddress:sellOrder.exTrx.receiveAddress
                                            changeAddress:sellOrder.exTrx.changeAddress.address
                                        SignatureMateiral:txin.hashForSign];
        [inputBlocks addObject:@{@"idx": @(index), @"blk": [NSString dataToHexstring:inputData]}];
    }
    
    __block NSDictionary *dict = @{
                                   @"changeKid": @(sellOrder.exTrx.changeAddress.keyId),
                                   @"blks": inputBlocks
                                   };
    NSLog(@"%@, dict: %@", url, dict);
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager POST:url parameters:dict success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            NSArray *blocks = [responseObject objectForKey:@"blks"];
            for (NSDictionary *blockData in blocks) {
                NSNumber *index = [blockData objectForKey:@"idx"];
                NSString *block = [blockData objectForKey:@"blk"];
                NSMutableData *inputData = [NSMutableData dataWithData:sellOrder.exTrx.loginHandle];
                [inputData appendData:[NSString hexstringToData:block]];
                
                [self.card exTrxSignPrepareWithInputId:index.integerValue withInputData:inputData];
            }
            
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            NSMutableDictionary *errorDict = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
            [errorDict setObject:@"Preparing Transaction fail with Exchange Site" forKey:@"error"];
            NSLog(@"error: %@", errorDict);
            error = [NSError errorWithDomain:error.domain code:error.code userInfo:errorDict];
            
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal *)signalRequestUnblockInfoWithOrderId:(NSString *)orderId
{
    __block NSString *url = [NSString stringWithFormat:ExUnblockOrders, orderId];
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([responseObject isKindOfClass:[NSArray class]]) {
                NSArray *unblockOrders = [RMMapper arrayOfClass:[CwExUnblock class] fromArrayOfDictionary:responseObject];
                
                [subscriber sendNext:unblockOrders];
                [subscriber sendCompleted];
            } else if ([responseObject isKindOfClass:[NSDictionary class]]) {
                CwExUnblock *unblock = [RMMapper objectWithClass:[CwExUnblock class] fromDictionary:responseObject];
                if (unblock.orderID == nil) {
                    unblock.orderID = [NSString hexstringToData:orderId];
                }
                
                [subscriber sendNext:unblock];
                [subscriber sendCompleted];
            } else {
                NSError *error = [NSError errorWithDomain:@"Exchange Site Error." code:1003 userInfo:@{@"error": @"Can't recognize unblock info."}];
                [subscriber sendError:error];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal *)signalUnblock:(CwExUnblock *)unblock
{
    @weakify(self);
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        [self.card exBlockCancel:unblock.orderID OkTkn:unblock.okToken EncUblkTkn:unblock.unblockToken Mac1:unblock.mac Nonce:unblock.nonce withComplete:^() {
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        } withError:^(NSInteger errorCode) {
            NSError *error = [self cardCmdError:errorCode errorMsg:@"CoolWallet card unblock fail."];
            [subscriber sendError:error];
        }];
        
        return nil;
    }] flattenMap:^RACStream *(id value) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            @strongify(self);
            
            NSString *url = [ExUnblockOrders stringByAppendingFormat:@"/%@", [NSString dataToHexstring:unblock.orderID]];
            
            AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
            [manager DELETE:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error){
                [subscriber sendError:error];
            }];
            
            return nil;
        }];
    }];
        
    return signal;
}

-(RACSignal *)signalGetOpenOrderCount
{
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager GET:ExOpenOrderCount parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            NSNumber *count = [responseObject objectForKey:@"open"];
            
            [subscriber sendNext:count];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal *)signalCancelOrder:(NSString *)orderId
{
    __block NSString *url = [NSString stringWithFormat:ExCancelOrder, orderId];
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager DELETE:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            NSNumber *responseCode = [responseObject objectForKey:@"Code"];
            if (responseCode.integerValue == 200) {
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            } else {
                NSError *error = [NSError errorWithDomain:@"Exchange site error." code:1004 userInfo:@{@"error": @"Failed to cancel order, please try again"}];
                [subscriber sendError:error];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal *)signalCancelTrx:(NSString *)orderId
{
    __block NSString *url = [NSString stringWithFormat:ExCancelTrx, orderId];
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager DELETE:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            NSNumber *responseCode = [responseObject objectForKey:@"Code"];
            if (responseCode.integerValue == 200) {
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            } else {
                NSError *error = [NSError errorWithDomain:@"Exchange site error." code:1004 userInfo:@{@"error": @"Failed to cancel order, please try again"}];
                [subscriber sendError:error];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal *)signalCardBlockInfo:(NSData *)okToken
{
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        [self.card exBlockInfo:okToken withComplete:^(CwBlockInfo *blockInfo) {
            [subscriber sendNext:blockInfo];
            [subscriber sendCompleted];
        } withError:^(NSInteger errorCode) {
            [subscriber sendError:[self cardCmdError:errorCode errorMsg:@"Get block info fail."]];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(NSData *) composePrepareInputData:(NSInteger)inputId KeyChainId:(NSInteger)keyChainId AccountId:(NSInteger)accountId KeyId:(NSInteger)keyId receiveAddress:(NSString *)receiveAddress changeAddress:(NSString *)changeAddress SignatureMateiral:(NSData *)signatureMaterial
{
    NSData *out1Address = [CwBase58 base58ToData:receiveAddress];
    NSData *out2Address = [CwBase58 base58ToData:changeAddress];
    
    NSMutableData *inputData = [[NSMutableData alloc] init];
    [inputData appendBytes:&accountId length:4];
    [inputData appendBytes:&keyChainId length:1];
    [inputData appendBytes: &keyId length: 4];
    [inputData appendBytes:[out1Address bytes] length:25];
    [inputData appendBytes:[out2Address bytes] length:25];
    [inputData appendBytes:[signatureMaterial bytes] length:32];
    
    return inputData;
}

-(NSError *) cardCmdError:(NSInteger)errorCode errorMsg:(NSString *)errorMsg
{
    NSError *error = [NSError errorWithDomain:@"Card Cmd Error" code:errorCode userInfo:@{@"error": errorMsg}];
    
    return error;
}

-(NSDictionary *) getAccountInfo:(CwAccount *)account
{
    NSNumber *accId = [NSNumber numberWithInteger:account.accId];
    NSNumber *extKeyPointer = [NSNumber numberWithInteger:account.extKeyPointer];
    NSNumber *intKeyPointer = [NSNumber numberWithInteger:account.intKeyPointer];
    
    NSDictionary *data = @{
                           @"id": accId,
                           @"extn": @{
                                   @"num": extKeyPointer,
                                   @"pub": account.externalKeychain.hexPublicKey == nil ? @"" : account.externalKeychain.hexPublicKey,
                                   @"chaincode": account.externalKeychain.hexChainCode == nil ? @"" : account.externalKeychain.hexChainCode
                                   },
                           @"intn": @{
                                   @"num": intKeyPointer,
                                   @"pub": account.internalKeychain.hexPublicKey == nil ? @"" : account.internalKeychain.hexPublicKey,
                                   @"chaincode": account.internalKeychain.hexChainCode == nil ? @"" : account.internalKeychain.hexChainCode
                                   }
                           };
    return data;
}

-(AFHTTPRequestOperationManager *) defaultJsonManager
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer=[AFJSONRequestSerializer serializer];
    if (self.loginSession != nil) {
        [manager.requestSerializer setValue:self.loginSession forHTTPHeaderField:@"Set-Cookie"];
    }
    
    return manager;
}

- (void)dealloc
{
    // implement -dealloc & remove abort() when refactoring for
    // non-singleton use.
    abort();
}

@end
