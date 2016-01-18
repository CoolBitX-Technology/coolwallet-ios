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

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <AFNetworking/AFNetworking.h>

#define ExBaseUrl @"http://xsm.coolbitx.com:8080/api/res/cw/"
#define ExSession @"session"

@interface CwExchange()

@property (strong, nonatomic) CwCard *card;
@property (strong, nonatomic) NSData *sessionSvrChlng;
@property (strong, nonatomic) NSData *sessionResponse;
@property (strong, nonatomic) NSData *sessionChlng;
@property (strong, nonatomic) NSData *sessionSvrResponse;

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
        CwManager *manager = [CwManager sharedManager];
        self.card = manager.connectedCwCard;
        self.syncedAccount = [NSMutableArray new];
        self.cardInfoSynced = NO;
    }
    
    return self;
}

-(void) loginExSession
{
    self.loginSessionFinish = NO;
    
    @weakify(self);
    RACSignal *createSignal = [self signalCreateExSession];
    
    [[[createSignal flattenMap:^RACStream *(id response) {
        @strongify(self);
        return [self signalInitSessionFromCard:self.sessionSvrChlng];
    }] flattenMap:^RACStream *(id value) {
        @strongify(self);
        NSLog(@"value: %@", value);
        return [self signalEstablishExSessionWithChallenge:self.sessionChlng andResponse:self.sessionResponse];
    }] subscribeNext:^(id response) {
        @strongify(self);
        NSLog(@"response: %@", response);
        self.loginSession = [NSData init];
        self.loginSessionFinish = YES;
    } error:^(NSError *error) {
        @strongify(self);
        NSLog(@"error(%ld): %@", error.code, error);
        self.loginSession = nil;
        self.loginSessionFinish = YES;
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

-(void) observeAccount:(CwAccount *)account
{
    self.loginSession = [NSData new];
    if (!self.loginSessionFinish || self.loginSession == nil) {
        return;
    }
    
    @weakify(self);
    RACDisposable *disposable = [[RACObserve(account, infoSynced) distinctUntilChanged] subscribeNext:^(NSNumber *synced) {
        @strongify(self);
        NSLog(@"account: %ld, synced: %d, self.syncAccountCount = %lu", account.accId, synced.boolValue, (unsigned long)self.syncedAccount.count);
        if ([self.syncedAccount containsObject:account] || !synced.boolValue) {
            return;
        }
        
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

-(void) observeHdwAccountPointer
{
    @weakify(self);
    [[RACObserve(self.card, hdwAcccountPointer) distinctUntilChanged] subscribeNext:^(NSNumber *counter) {
        @strongify(self);
        NSLog(@"observeHdwAccountPointer: %@", counter);
        for (int index = (int)self.syncedAccount.count; index < counter.intValue; index++) {
            CwAccount *account = [self.card.cwAccounts objectForKey:[NSString stringWithFormat:@"%d", index]];
            [self observeAccount:account];
            [self observeHdwAccountAddrCount:account];
        }
    }];
}

-(void) observeHdwAccountAddrCount:(CwAccount *)account
{
    RACSignal *signal = [[RACSignal combineLatest:@[RACObserve(account, extKeyPointer), RACObserve(account, intKeyPointer)]
                                          reduce:^(NSNumber *extCount, NSNumber *intCount) {
                                              BOOL skip = !self.cardInfoSynced || (extCount.intValue == 0 && intCount.intValue ==0);
                                              
                                              return [NSNumber numberWithBool:skip];
                                          }] skipWhileBlock:^BOOL(NSNumber *skip) {
                                              return skip.boolValue;
                                          }];
    
    @weakify(self)
    [[[signal distinctUntilChanged] flattenMap:^RACStream *(NSNumber *skip) {
        @strongify(self)
        return [self signalSyncAccountInfo:account];
    }] subscribeNext:^(id response) {
        NSLog(@"sync account %ld completed: %@", account.accId, response);
    } error:^(NSError *error) {
        NSLog(@"sync account error: %@", error);
    }];
}

-(RACSignal*)signalCreateExSession {
    NSString *url = [NSString stringWithFormat:@"%@%@/%@", ExBaseUrl, ExSession, self.card.cardId];
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            
            @strongify(self);
            self.sessionSvrChlng = [NSString hexstringToData:[responseObject objectForKey:@"challenge"]];
            
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
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
        
        [self.card exSessionInit:self.sessionSvrChlng withComplete:^(NSData *seResp, NSData *seChlng) {
            NSLog(@"seResp: %@, seChlng: %@", seResp, seChlng);
            self.sessionResponse = seResp;
            self.sessionChlng = seChlng;
            
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

-(RACSignal*)signalEstablishExSessionWithChallenge:(NSData *)challenge andResponse:(NSData *)response {
    NSString *url = [NSString stringWithFormat:@"%@%@/%@", ExBaseUrl, ExSession, self.card.cardId];
    NSDictionary *dict = @{@"challenge": challenge, @"response": response};
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        AFHTTPRequestOperationManager *manager = [self defaultJsonManager];
        [manager POST:url parameters:dict success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            NSLog(@"%@", responseObject);
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
    
    return signal;
}

-(RACSignal*)signalSyncCardInfo {
    NSString *url = [NSString stringWithFormat:@"%@%@", ExBaseUrl, self.card.cardId];
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:@"notify token" forKey:@"token"];
    
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
    NSString *url = [NSString stringWithFormat:@"%@%@/%ld", ExBaseUrl, self.card.cardId, account.accId];
    
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
    
    return manager;
}

- (void)dealloc
{
    // implement -dealloc & remove abort() when refactoring for
    // non-singleton use.
    abort();
}

@end
