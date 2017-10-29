//
//  CWBTCNetWork.h
//  BCDC
//
//  Created by LIN CHIH-HUNG on 2014/8/22.
//  Copyright (c) 2014年 LIN CHIH-HUNG. All rights reserved.
//
#pragma once

#import <Foundation/Foundation.h>
#import "CwBtcNetworkError.h"
#import "CwTx.h"
#import "CwBtc.h"
#import "CwBtcNetworkDelegate.h"
#import "CwAddress.h"
#import "CwAccount.h"

@interface CwBtcNetWork : NSObject

@property (nonatomic, assign) id<CwBtcNetworkDelegate> delegate;

//used for Singleton
+(id) sharedManager;

- (GetTransactionByAccountErr) getBalanceAndTransactionByAccount:(NSInteger)accId;
- (GetTransactionByAccountErr) getTransactionByAccount: (NSInteger)accId;
- (RegisterNotifyByAddrErr) registerNotifyByAccount: (NSInteger)accId;
- (void) registerNotifyByAddress:(CwAddress *)addr;
- (NSDictionary *) queryHistoryTxs:(NSArray *)addresses;
- (GetUnspentTxsByAddrErr) getUnspentTxsByAddr: (NSString*)addr unspentTxs:(NSMutableArray**)unspentTxs;
-(void) syncAccountTransactions:(NSDictionary *)historyTxData account:(CwAccount *)account;
-(void) refreshTxsFromAccountAddresses:(CwAccount *)account;
-(GetAllTxsByAddrErr) updateHistoryTxs:(NSString *)tid;
- (int64_t) getBalance:(NSNumber *)accountId;

- (void) publish:(CwTx*)tx result:(NSData **)result;
- (DecodeErr) decode:(CwTx*)tx result:(NSData **)result;

- (NSDictionary *) getCurrRate; //key: CurrId, value: rate
- (void) updateTransactionFees;

@end
