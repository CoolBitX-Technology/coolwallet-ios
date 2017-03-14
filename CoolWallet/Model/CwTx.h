//
//  CWTx.h
//  BCDC
//
//  Created by LIN CHIH-HUNG on 2014/8/22.
//  Copyright (c) 2014年 LIN CHIH-HUNG. All rights reserved.
//
#pragma once

#import <Foundation/Foundation.h>
#import "CwBtc.h"

#import <RMMapper/RMMapper.h>
#import "NSObject+RMArchivable.h"

typedef enum{TypeUnsignedTx,TypeSignedTx,TypeUnspentTx,TypeHistoryTx} TxType;

@interface CwTx : NSObject <RMMapping>

@property TxType txType;

@property (nonatomic) NSString *tx;
@property (nonatomic) NSDate* historyTime_utc;
@property (nonatomic) NSNumber *confirmations;
@property (nonatomic) NSNumber *amount_btc;
@property (nonatomic) NSNumber *amount_multisig;

@property (nonatomic, readonly) NSData* tid;
@property NSMutableArray* inputs;        //CWTxin[]
@property NSMutableArray* outputs;       //CWTxout[]
@property NSData* rawTx;
@property CwBtc *txFee;
@property CwBtc *totalInput;
@property CwBtc *dustAmount;

@property (nonatomic, readonly) CwBtc* historyAmount;      //bitcoin value changed after this tx


//@property NSUInteger confirmations;

@property (nonatomic, readonly) BOOL isCompleted;

@end
