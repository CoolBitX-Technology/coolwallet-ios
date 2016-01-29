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

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface CwExchange()

@property (readwrite, assign) ExSessionStatus sessionStatus;

@property (readwrite, nonatomic) CwCard *card;
@property (strong, nonatomic) NSString *loginSession;

@property (strong, nonatomic) NSMutableArray *syncedAccount;
@property (assign, nonatomic) BOOL cardInfoSynced;

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
        
        if (self.sessionStatus != ExSessionFail) {
            [self logoutExSession];
        }
        self.sessionStatus = ExSessionNone;
        self.loginSession = nil;
    }];
}

-(void) loginExSession
{
    self.sessionStatus = ExSessionNone;
    
    @weakify(self);
    RACSignal *createSignal = [self signalCreateExSession];
    
    [[[[createSignal flattenMap:^RACStream *(NSDictionary *response) {
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
    }] subscribeNext:^(id cardResponse) {
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
    
    NSString *url = [NSString stringWithFormat:@"%@%@", ExBaseUrl, ExSessionLogout];
    
    AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
        
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

-(RACSignal*)signalCreateExSession {
    NSString *url = [NSString stringWithFormat:@"%@%@/%@", ExBaseUrl, ExSession, self.card.cardId];
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        self.sessionStatus = ExSessionProcess;
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            self.loginSession = [operation.response.allHeaderFields objectForKey:@"Set-Cookie"];
            
            NSString *hexString = [responseObject objectForKey:@"challenge"];
            if (hexString.length == 0) {
                [subscriber sendError:[NSError errorWithDomain:@"Not exchange site member." code:900 userInfo:nil]];
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
            NSError *error = [NSError errorWithDomain:@"Card Cmd Error" code:errorCode userInfo:nil];
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal*)signalEstablishExSessionWithChallenge:(NSData *)challenge andResponse:(NSData *)response {
    NSString *url = [NSString stringWithFormat:@"%@%@/%@", ExBaseUrl, ExSession, self.card.cardId];
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
    NSString *url = [NSString stringWithFormat:@"%@%@", ExBaseUrl, self.card.cardId];
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:[APPData sharedInstance].deviceToken forKey:@"token"];
    
    NSMutableArray *accountDatas = [NSMutableArray new];
    for (CwAccount *account in [self.card.cwAccounts allValues]) {
        [accountDatas addObject:[self getAccountInfo:account]];
    }
    [dict setObject:accountDatas forKey:@"card"];
    
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
    NSString *url = [NSString stringWithFormat:@"%@%@/%ld", ExBaseUrl, self.card.cardId, (long)account.accId];
    
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
