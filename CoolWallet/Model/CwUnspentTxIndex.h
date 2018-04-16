//
//  CWUnspendTxIndex.h
//  BCDC
//
//  Created by LIN CHIH-HUNG on 2014/8/28.
//  Copyright (c) 2014年 LIN CHIH-HUNG. All rights reserved.
//

#import "CwBtc.h"

@interface CwUnspentTxIndex : NSObject

@property NSData *tid; //tx_hash_big_endian
@property NSUInteger n; //tx_output_n
@property NSUInteger kcId; //external or internal
@property NSUInteger kId; //address index
@property CwBtc* amount;
@property NSData *scriptPub;
@property NSNumber *confirmations;

@end
