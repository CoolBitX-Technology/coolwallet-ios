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

typedef enum{TypeUnsignedTx,TypeSignedTx,TypeUnspentTx,TypeHistoryTx} TxType;

@interface CwTx : NSObject

@property TxType txType;

@property NSData* tid;
@property NSMutableArray* inputs;        //CWTxin[]
@property NSMutableArray* outputs;       //CWTxout[]
@property NSData* rawTx;

@property NSData* unspentScriptPub;
@property NSUInteger unspentN;
@property NSString* unspentAddr;
@property CwBtc* unspentAmount;

@property CwBtc* historyAmount;      //bitcoin value changed after this tx
@property NSDate* historyTime_utc;

@property NSUInteger confirmations;

@end
