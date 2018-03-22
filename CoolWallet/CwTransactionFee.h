//
//  CwTransactionFee.h
//  CoolWallet
//
//  Created by wen on 2017/5/9.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+RMArchivable.h"

@class CwTx, CwBtc;

@interface CwTransactionFee : NSObject

// fastestFee, halfHourFee and hourFee is coming from https://bitcoinfees.21.co/api/v1/fees/recommended
// the unit is satoshi
@property (strong, nonatomic) NSNumber *fastestFee;
@property (strong, nonatomic) NSNumber *halfHourFee;
@property (strong, nonatomic) NSNumber *hourFee;

// the unit for manualFee is BTC
@property (strong, nonatomic) NSNumber *manualFee;
@property (strong, nonatomic) NSNumber *enableAutoFee;

+(CwTransactionFee *) sharedInstance;
+(NSString *) preferenceKey;
+(void) saveData;

-(NSString *) getEstimatedTransactionFeeString;
-(NSInteger *) getEstimatedTransactionFee;

-(CwBtc *) estimateRecommendFeeByTxSize:(NSInteger)txSize;

@end
