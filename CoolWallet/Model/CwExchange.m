//
//  CwExchange.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/12.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "CwExchange.h"
#import "CwCard.h"
#import "CwManager.h"
#import "NSString+HexToData.h"
#import "APPData.h"
#import "CwExTx.h"
#import "CwBtc.h"
#import "CwTxin.h"

@interface CwExchange()

@property (readwrite, assign) ExSessionStatus sessionStatus;

@property (readwrite, nonatomic) CwCard *card;
@property (strong, nonatomic) NSString *loginSession;

@property (strong, nonatomic) NSMutableArray *syncedAccount;
@property (readwrite, nonatomic) BOOL cardInfoSynced;

@property (strong, nonatomic) NSString *txReceiveAddress;
@property (strong, nonatomic) NSData *txLoginHandle;

@end

@implementation CwExchange

+(id)sharedInstance
{
    static dispatch_once_t pred;
    static CwExchange *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[CwExchange alloc] init];
        
    });
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

-(void) observeConnectedCard
{
    @weakify(self)
    CwManager *manager = [CwManager sharedManager];
    RAC(self, card) = [RACObserve(manager, connectedCwCard) filter:^BOOL(CwCard *card) {
        @strongify(self)
        return ![card.cardId isEqualToString:self.card.cardId];
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
    }];
}

-(void) loginExSession
{
    self.sessionStatus = ExSessionProcess;
    
    @weakify(self);
    [[self loginSignal] subscribeNext:^(id cardResponse) {
        @strongify(self);
        self.sessionStatus = ExSessionLogin;
        
        [self syncCardInfo];
    } error:^(NSError *error) {
        @strongify(self);
        NSLog(@"error(%ld): %@", (long)error.code, error);
        self.sessionStatus = ExSessionFail;
        [self logoutExSession];
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

-(void) blockWithOrderID:(NSString *)hexOrderID withOTP:(NSString *)otp withComplete:(void(^)(void))completeCallback error:(void(^)(NSError *error))errorCallback
{
    RACSignal *blockSignal = [self signalRequestOrderBlockWithOrderID:hexOrderID withOTP:otp];
    
    [[[blockSignal flattenMap:^RACStream *(NSString *blockData) {
        return [self signalBlockBTCFromCard:blockData];
    }] flattenMap:^RACStream *(NSDictionary *data) {
        NSData *okToken = [data objectForKey:@"okToken"];
        NSData *unblockToken = [data objectForKey:@"unblockToken"];
        
        return [self signalWriteOKTokenToServer:okToken unblockToken:unblockToken withOrder:hexOrderID];
    }] subscribeNext:^(id value) {
        if (completeCallback) {
            completeCallback();
        }
    } error:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
    }];
}

-(void) prepareTransactionWithAmount:(NSNumber *)amountBTC withChangeAddress:(NSString *)changeAddress fromAccountId:(NSInteger)accountId
{
    CwExTx *exTx = [CwExTx new];
    exTx.accountId = accountId;
    exTx.amount = [CwBtc BTCWithBTC:amountBTC];
    exTx.changeAddress = changeAddress;
    
    @weakify(self)
    [[[[self signalGetTrxInfo] flattenMap:^RACStream *(NSDictionary *response) {
        NSLog(@"response: %@", response);
        @strongify(self)
        NSString *loginData = [response objectForKey:@"loginblk"];
        exTx.receiveAddress = [response objectForKey:@"out1addr"];
        
        if (!loginData) {
            return [RACSignal error:[NSError errorWithDomain:@"Exchange site error." code:1001 userInfo:@{@"error": @"Fail to get transaction data from exchange site."}]];
        }
        
        return [self signalTrxLogin:loginData];
    }] flattenMap:^RACStream *(NSData *trxHandle) {
        exTx.loginHandle = trxHandle;
        CwTx *unsignedTx = [self.card getUnsignedTransaction:exTx.amount.satoshi.longLongValue Address:exTx.receiveAddress Change:exTx.changeAddress AccountId:exTx.accountId];
        if (unsignedTx == nil) {
            return [RACSignal error:[NSError errorWithDomain:@"Check unsigned data error." code:1002 userInfo:@{@"error": @"No unsigned transaction."}]];
        } else {
            return [self signalTrxPrepareDataFrom:unsignedTx andExTx:exTx];
        }
    }] subscribeNext:^(id value) {
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

-(void) completeTransactionWithOrderId:(NSString *)orderId TxId:(NSString *)txId
{
    NSString *url = [NSString stringWithFormat:ExTrx, self.card.cardId];
    NSDictionary *dict = @{@"bcTrxId": txId, @"orderId": orderId};
    
    AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
    [manager POST:url parameters:dict success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
        NSLog(@"Success send txId to ex site.");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        NSLog(@"Fail send txId to ex site.");
        // TODO: should resend to exchange site?
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
            [self observeAccount:account];
            [self observeHdwAccountAddrCount:account];
        }
    }];
}

-(void) observeAccount:(CwAccount *)account
{
    if (self.sessionStatus != ExSessionLogin) {
        return;
    }
    
    @weakify(self);
    RACDisposable *disposable = [[[RACObserve(account, infoSynced) distinctUntilChanged] filter:^BOOL(NSNumber *synced) {
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
    
    RACDisposable *disposable = [[signal flattenMap:^RACStream *(NSArray *counter) {
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

// signals

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
    NSString *url = [NSString stringWithFormat:ExSession, self.card.cardId];
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
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
    NSString *url = [NSString stringWithFormat:ExSession, self.card.cardId];
    NSDictionary *dict = @{@"challenge": [NSString dataToHexstring:challenge], @"response": [NSString dataToHexstring:response]};
    
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
    NSString *url = [NSString stringWithFormat:@"%@/%@", ExBaseUrl, self.card.cardId];
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:@"ios" forKey:@"dev_type"];
    [dict setObject:[APPData sharedInstance].deviceToken forKey:@"token"];
    
    NSMutableArray *accountDatas = [NSMutableArray new];
    for (CwAccount *account in [self.card.cwAccounts allValues]) {
        [accountDatas addObject:[self getAccountInfo:account]];
    }
    [dict setObject:accountDatas forKey:@"account"];
    
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
    NSString *url = [NSString stringWithFormat:@"%@/%@/%ld", ExBaseUrl, self.card.cardId, (long)account.accId];
    
    NSDictionary *dict = [self getAccountInfo:account];
    
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
    NSString *url = [NSString stringWithFormat:ExRequestOrderBlock, hexOrder, otp];
    
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

-(RACSignal *)signalWriteOKTokenToServer:(NSData *)okToken unblockToken:(NSData *)unblockToken withOrder:(NSString *)orderId
{
    NSString *url = [NSString stringWithFormat:ExWriteOKToken, orderId];
    NSDictionary *dict = @{
                           @"okToken": [NSString dataToHexstring:okToken],
                           @"unblockToken": [NSString dataToHexstring:unblockToken],
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

-(RACSignal *)signalTrxLogin:(NSString *)logingData
{
    @weakify(self)
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        [self.card exTrxSignLogin:logingData withComplete:^(NSData *loginHandle) {
            [subscriber sendNext:loginHandle];
            [subscriber sendCompleted];
        } error:^(NSInteger errorCode) {
            [subscriber sendError:[self cardCmdError:errorCode errorMsg:@"Transaction login fail."]];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal*)signalGetTrxInfo
{
    NSString *url = [NSString stringWithFormat:ExGetTrxInfo, self.card.cardId];
    
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

-(RACSignal *)signalTrxPrepareDataFrom:(CwTx *)unsignedTx andExTx:(CwExTx *)exTx
{
    NSString *url = ExGetTrxPrepareBlocks;
    
    NSMutableArray *inputBlocks = [NSMutableArray new];
    for (int index=0; index < unsignedTx.inputs.count; index++) {
        CwTxin *txin = unsignedTx.inputs[index];
        NSData *inputData = [self composePrepareInputData:index KeyChainId:txin.kcId AccountId:txin.accId KeyId:txin.kId receiveAddress:exTx.receiveAddress changeAddress:exTx.changeAddress SignatureMateiral:txin.hashForSign];
        [inputBlocks addObject:@{@"ids": @(index), @"blk": [NSString dataToHexstring:inputData]}];
    }
    NSDictionary *dict = @{@"blks": inputBlocks};
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager POST:url parameters:dict success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            NSArray *blocks = [responseObject objectForKey:@"blks"];
            for (NSDictionary *blockData in blocks) {
                NSInteger index = (NSInteger)[blockData objectForKey:@"idx"];
                NSString *block = [blockData objectForKey:@"blk"];
                NSMutableData *inputData = [NSMutableData dataWithData:exTx.loginHandle];
                [inputData appendData:[NSString hexstringToData:block]];
                
                [self.card exTrxSignPrepareWithInputId:index withInputData:inputData];
            }
            
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
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

-(RACSignal *)signalCancelOrders:(NSString *)orderId
{
    NSString *url = [NSString stringWithFormat:ExCancelOrder, orderId];
    NSLog(@"cancel order: %@", url);
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(NSData *) composePrepareInputData:(NSInteger)inputId KeyChainId:(NSInteger)keyChainId AccountId:(NSInteger)accountId KeyId:(NSInteger)keyId receiveAddress:(NSString *)receiveAddress changeAddress:(NSString *)changeAddress SignatureMateiral:(NSData *)signatureMaterial
{
    NSData *out1Address = [NSString hexstringToData:receiveAddress];
    NSData *out2Address = [NSString hexstringToData:changeAddress];
    
    NSMutableData *inputData = [[NSMutableData alloc] init];
    [inputData appendBytes:&accountId length:4];
    [inputData appendBytes:&keyChainId length:1];
    [inputData appendBytes: &keyId length: 4];
    [inputData appendData:out1Address];
    [inputData appendData:out2Address];
    [inputData appendData:signatureMaterial];
    
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
                                   @"pub": account.externalKeychain.hexPublicKey,
                                   @"chaincode": account.externalKeychain.hexChainCode
                                   },
                           @"intn": @{
                                   @"num": intKeyPointer,
                                   @"pub": account.internalKeychain.hexPublicKey,
                                   @"chaincode": account.internalKeychain.hexChainCode
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
