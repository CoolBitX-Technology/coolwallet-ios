//
//  CwExRetryManager.m
//  CoolWallet
//
//  Created by wen on 2017/10/25.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import "CwExRetryManager.h"
#import "CwExchangeManager.h"
#import "CwExRetryTxSignLogout.h"
#import "CwCard.h"
#import "CwExSellOrder.h"
#import "CwExchangeManager.h"
#import "CwBtcNetWork.h"
#import "CwManager.h"

#import <NSUserDefaults+RMSaveCustomObject.h>

@interface CwExRetryManager ()

@property (strong, nonatomic) CwCard *card;

@property (strong, nonatomic) NSOperationQueue *queuetx;
@property (strong, nonatomic) NSString *keyOfTxSignLogout;
@property (strong, nonatomic) NSString *keyOfReceipt;
@property (strong, nonatomic) NSString *keyOfTx;

@end

@implementation CwExRetryManager

static NSString const *prefixKeyOfRetryTxSignLogout = @"RetryTxSignLogout_";
static NSString const *prefixKeyOfRetryReceipt = @"RetryReceipt_";
static NSString const *prefixKeyOfRetryTx = @"RetryTx_";

+(instancetype) sharedInstance
{
    static dispatch_once_t onceToken;
    static CwExRetryManager *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CwExRetryManager alloc] init];
    });
    
    return sharedInstance;
}

-(void) clear
{
    [self.queuetx cancelAllOperations];
    
    _keyOfTxSignLogout = nil;
    _keyOfReceipt = nil;
    _keyOfTx = nil;
}

-(CwCard *) card
{
    CwManager *manager = [CwManager sharedManager];
    
    if (!_card || ![_card.cardId isEqualToString:manager.connectedCwCard.cardId]) {
        _card = manager.connectedCwCard;
        [self clear];
    }
    
    return _card;
}

-(NSOperationQueue *) queuetx
{
    if (!_queuetx) {
        _queuetx = [NSOperationQueue new];
    }
    
    return _queuetx;
}

-(NSString *) keyOfTxSignLogout
{
    if (!_keyOfTxSignLogout) {
        _keyOfTxSignLogout = [NSString stringWithFormat:@"%@%@", prefixKeyOfRetryTxSignLogout, self.card.cardId];;
    }
    
    return _keyOfTxSignLogout;
}

-(NSString *) keyOfReceipt
{
    if (!_keyOfReceipt) {
        _keyOfReceipt = [NSString stringWithFormat:@"%@%@", prefixKeyOfRetryReceipt, self.card.cardId];;
    }
    
    return _keyOfReceipt;
}

-(NSString *) keyOfTx
{
    if (!_keyOfTx) {
        _keyOfTx = [NSString stringWithFormat:@"%@%@", prefixKeyOfRetryTx, self.card.cardId];;
    }
    
    return _keyOfTx;
}

-(void) saveRetryTxSignLogout:(CwExRetryTxSignLogout *)retryTxSignLogout
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSArray *values = [userDefaults rm_customObjectForKey:self.keyOfTxSignLogout];
    NSMutableArray *results = [NSMutableArray new];
    if (values) {
        results = [NSMutableArray arrayWithArray:values];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.cardId == %@ AND SELF.txLoginHandle = %@", retryTxSignLogout.cardId, retryTxSignLogout.txLoginHandle];
        NSArray *matchs = [results filteredArrayUsingPredicate:predicate];
        [results removeObjectsInArray:matchs];
    }
    [results addObject:retryTxSignLogout];
    
    [userDefaults rm_setCustomObject:results forKey:self.keyOfTxSignLogout];
    
    [self runRetryTxSignLogout:retryTxSignLogout];
}

-(void) removeReryTxSignLout:(CwExRetryTxSignLogout *)retryTxSignLogout
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *values = [userDefaults rm_customObjectForKey:self.keyOfTxSignLogout];
    NSMutableArray *results = [NSMutableArray new];
    if (values) {
        results = [NSMutableArray arrayWithArray:values];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.cardId == %@ AND SELF.txLoginHandle = %@", retryTxSignLogout.cardId, retryTxSignLogout.txLoginHandle];
        NSArray *matchs = [results filteredArrayUsingPredicate:predicate];
        [results removeObjectsInArray:matchs];
    }
    
    [userDefaults rm_setCustomObject:results forKey:self.keyOfTxSignLogout];
}

-(void) runRetryTxSignLogout:(CwExRetryTxSignLogout *)retryTxSignLogout
{
    if (![retryTxSignLogout.cardId isEqualToString:self.card.cardId]) {
        return;
    }
    
    if (retryTxSignLogout.retryStatus.integerValue == CwExStopRetry) {
        return;
    }
    
    __block CwExRetryTxSignLogout *blockRetryTxSignLogout = retryTxSignLogout;
    
    @weakify(self)
    [self.card exTrxSignLogoutWithTrxHandle:retryTxSignLogout.txLoginHandle nonce:retryTxSignLogout.nonce complete:^(NSData *receipt) {
        @strongify(self)
        blockRetryTxSignLogout.retryStatus = @(CwExStopRetry);
        [self removeReryTxSignLout:blockRetryTxSignLogout];
    } error:^(NSInteger errorCode) {
        @strongify(self)
        [self performSelector:@selector(runRetryTxSignLogout:) withObject:blockRetryTxSignLogout afterDelay:60];
    }];
}

-(void) saveReceiptFrom:(CwExSellOrder *)sellOrder
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSArray *values = [userDefaults rm_customObjectForKey:self.keyOfReceipt];
    NSMutableArray *results = [NSMutableArray new];
    if (values) {
        results = [NSMutableArray arrayWithArray:values];
        NSArray *matches = [results filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.orderId = %@", sellOrder.orderId]];
        [results removeObjectsInArray:matches];
    }
    [results addObject:sellOrder];
    
    [userDefaults rm_setCustomObject:results forKey:self.keyOfReceipt];
    
    [self runResendReceipt:sellOrder];
}

-(void) removeReceiptFrom:(CwExSellOrder *)sellOrder
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSArray *values = [userDefaults rm_customObjectForKey:self.keyOfReceipt];
    NSMutableArray *results = [NSMutableArray new];
    if (values) {
        results = [NSMutableArray arrayWithArray:values];
        NSArray *matches = [results filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.orderId = %@", sellOrder.orderId]];
        [results removeObjectsInArray:matches];
    }
    
    [userDefaults rm_setCustomObject:results forKey:self.keyOfReceipt];
}

-(void) runResendReceipt:(CwExSellOrder *)sellOrder
{
    @weakify(self)
    CwExchangeManager *manager = [CwExchangeManager sharedInstance];
    AFHTTPRequestOperation *operation = [manager postReceiptToServer:sellOrder];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        @strongify(self)
        [self removeReceiptFrom:sellOrder];
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        @strongify(self)
        if (!operation.isCancelled) {
            [self runResendReceipt:sellOrder];
        }
    }];
}

-(void) saveTx:(CwTx *)tx
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSArray *values = [userDefaults rm_customObjectForKey:self.keyOfReceipt];
    NSMutableArray *results = [NSMutableArray new];
    if (values) {
        results = [NSMutableArray arrayWithArray:values];
        NSArray *matches = [results filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.tid = %@", tx.tid]];
        [results removeObjectsInArray:matches];
    }
    [results addObject:tx];
    
    [userDefaults rm_setCustomObject:results forKey:self.keyOfTx];
    
    [self runResendTx:tx];
}

-(void) removeTx:(CwTx *)tx
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSArray *values = [userDefaults rm_customObjectForKey:self.keyOfReceipt];
    NSMutableArray *results = [NSMutableArray new];
    if (values) {
        results = [NSMutableArray arrayWithArray:values];
        NSArray *matches = [results filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.tid = %@", tx.tid]];
        [results removeObjectsInArray:matches];
    }
    
    [userDefaults rm_setCustomObject:results forKey:self.keyOfTx];
}

-(void) runResendTx:(CwTx *)tx
{
    @weakify(self)
    __block NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        @strongify(self)
        CwBtcNetWork *btcNet = [CwBtcNetWork sharedManager];
        NSData *result;
        NSError *error;
        [btcNet publish:tx result:&result error:&error];
        if (error && !operation.isCancelled) {
            [self runResendTx:tx];
        }
    }];
    
    [self.queuetx addOperation:operation];
}

-(void) startRetry
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    @weakify(self)
    
    NSArray *retryTxSignLogouts = [userDefaults rm_customObjectForKey:self.keyOfTxSignLogout];
    [retryTxSignLogouts enumerateObjectsUsingBlock:^(CwExRetryTxSignLogout *txSignLogout, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self)
        [self runRetryTxSignLogout:txSignLogout];
    }];
    
    NSArray *receipts = [userDefaults rm_customObjectForKey:self.keyOfReceipt];
    [receipts enumerateObjectsUsingBlock:^(CwExSellOrder *sellOrder, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self)
        [self runResendReceipt:sellOrder];
    }];
    
    NSArray *txs = [userDefaults rm_customObjectForKey:self.keyOfTx];
    [txs enumerateObjectsUsingBlock:^(CwTx *tx, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self)
        [self runResendTx:tx];
    }];
}

@end
