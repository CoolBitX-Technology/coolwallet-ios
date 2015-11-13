//
//  CWUnspendTxIndex.h
//  BCDC
//
//  Created by LIN CHIH-HUNG on 2014/8/28.
//  Copyright (c) 2014年 LIN CHIH-HUNG. All rights reserved.
//

#import "CwBtc.h"

@interface CwUnspentTxIndex : NSObject

@property NSData *tid;
@property NSUInteger n;
@property NSUInteger kcId;
@property NSUInteger kId;
@property CwBtc* amount;
@property NSData *scriptPub;
@property NSNumber *confirmations;

@end
