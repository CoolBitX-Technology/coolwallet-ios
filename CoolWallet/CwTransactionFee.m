//
//  CwTransactionFee.m
//  CoolWallet
//
//  Created by wen on 2017/5/9.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import "CwTransactionFee.h"
#import "NSUserDefaults+RMSaveCustomObject.h"
#import "CwBtc.h"

#import <RMMapper/RMMapper.h>

static double SATOSHI_RATE = 0.00000001;

@implementation CwTransactionFee

+(CwTransactionFee *) sharedInstance
{
    static dispatch_once_t cwtxfee;
    static CwTransactionFee *sharedInstance = nil;
    
    dispatch_once(&cwtxfee, ^{
        CwTransactionFee *cached = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:[CwTransactionFee preferenceKey]];
        if (cached) {
            sharedInstance = cached;
        } else {
            sharedInstance = [[CwTransactionFee alloc] init];
        }
    });
    
    return sharedInstance;
}

+(NSString *) preferenceKey
{
    return @"CwTransactionFee";
}

+(void) saveData
{
    [[NSUserDefaults standardUserDefaults] rm_setCustomObject:[CwTransactionFee sharedInstance] forKey:[CwTransactionFee preferenceKey]];
}

#pragma properties
-(NSNumber *) fastestFee
{
    if (!_fastestFee) {
        _fastestFee = [NSNumber numberWithInteger:90];
    }
    
    return _fastestFee;
}

-(NSNumber *)halfHourFee
{
    if (!_halfHourFee) {
        _halfHourFee = [NSNumber numberWithInteger:80];
    }
    
    return _halfHourFee;
}

-(NSNumber *)hourFee
{
    if (!_hourFee) {
        _hourFee = [NSNumber numberWithInteger:70];
    }
    
    return _hourFee;
}

-(NSNumber *)manualFee
{
    if (!_manualFee) {
        _manualFee = [NSNumber numberWithFloat:0.0002];
    }
    
    return _manualFee;
}

-(NSNumber *)enableAutoFee
{
    if (!_enableAutoFee) {
        _enableAutoFee = [NSNumber numberWithBool:YES];
    }
    
    return _enableAutoFee;
}

-(void) clearData
{
    _fastestFee = nil;
    _halfHourFee = nil;
    _hourFee = nil;
    _manualFee = nil;
    _enableAutoFee = nil;
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[CwTransactionFee preferenceKey]];
}

-(NSString *) getEstimatedTransactionFeeString
{
    NSString *estimated = @"Estimated transaction fee:\nMedian transaction size 226 bytes x %ld (in satoshis per byte)\n= %ld satoshi\n= %@ BTC";
    
    NSInteger recommendedFee = self.fastestFee.integerValue;
    NSInteger estimatedFeeSatoshi = recommendedFee * 226;
    
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    [fmt setPositiveFormat:@"0.########"];
    [fmt setLocale:[NSLocale currentLocale]];
    NSString *estimatedFeeBTC = [fmt stringFromNumber:[NSNumber numberWithDouble:(double)estimatedFeeSatoshi * SATOSHI_RATE]];
    
    estimated = [NSString stringWithFormat:estimated, recommendedFee, estimatedFeeSatoshi, estimatedFeeBTC];
    
    return estimated;
}

-(CwBtc *) estimateRecommendFeeByTxSize:(NSInteger)txSize
{
    NSInteger recommendFee = txSize * self.fastestFee.integerValue;
    return [CwBtc BTCWithSatoshi:[NSNumber numberWithInteger:recommendFee]];
}

@end
