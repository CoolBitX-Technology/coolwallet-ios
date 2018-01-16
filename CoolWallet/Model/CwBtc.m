//
//  CWBTC.m
//  BCDC
//
//  Created by LIN CHIH-HUNG on 2014/8/28.
//  Copyright (c) 2014年 LIN CHIH-HUNG. All rights reserved.
//

#import "CwBtc.h"
#import "OCAppCommon.h"

@implementation CwBtc

- (void)refresh
{
    _muBTC = [NSNumber numberWithDouble:[_satoshi doubleValue] / 1e2];
    _mBTC  = [NSNumber numberWithDouble:[_satoshi doubleValue] / 1e5];
    _BTC   = [NSNumber numberWithDouble:[_satoshi doubleValue] / 1e8];
    
    _currAmount = [NSNumber numberWithDouble:[_BTC doubleValue]*[_currRate doubleValue]];
}

+ (id)BTCWithBTC:(NSNumber*)BTC
{
    CwBtc *_newBTC = [[CwBtc alloc]init];
    [_newBTC setBTC:BTC];
    [_newBTC setCurrRate:[NSNumber numberWithDouble:0]];
    return _newBTC;
}
+ (id)BTCWithMBTC:(NSNumber*)mBTC
{
    CwBtc *_newBTC = [[CwBtc alloc]init];
    [_newBTC setMBTC:mBTC];
    //Test
//    [_newBTC setMBTC:[NSNumber numberWithLongLong:2300000000]];
    [_newBTC setCurrRate:[NSNumber numberWithDouble:0]];
    return _newBTC;
}
+ (id)BTCWithMuBTC:(NSNumber*)muBTC
{
    CwBtc *_newBTC = [[CwBtc alloc]init];
    [_newBTC setMuBTC:muBTC];
    [_newBTC setCurrRate:[NSNumber numberWithDouble:0]];
    return _newBTC;
}
+ (id)BTCWithSatoshi:(NSNumber*)satoshi
{
    CwBtc *_newBTC = [[CwBtc alloc]init];
    [_newBTC setSatoshi:satoshi];
    [_newBTC setCurrRate:[NSNumber numberWithDouble:0]];
    return _newBTC;
}

- (void)setSatoshi:(NSNumber *)satoshi
{
    _satoshi = satoshi;
    [self refresh];
}
- (void)setMuBTC:(NSNumber *)muBTC
{
    _satoshi = [NSNumber numberWithLongLong:(int64_t)([muBTC doubleValue] * 1e2)];
    [self refresh];
}
- (void)setMBTC:(NSNumber *)mBTC
{
    _satoshi = [NSNumber numberWithLongLong:(int64_t)([mBTC doubleValue] * 1e5)];
    [self refresh];
}

- (void)setBTC:(NSNumber *)BTC
{
    int64_t amount = (int64_t)(BTC.doubleValue * 1e8 + (BTC.doubleValue < 0.0 ? -.5:.5));
    _satoshi = [NSNumber numberWithLongLong:amount];

    [self refresh];
}

- (void)setCurrRate:(NSNumber *)currRate
{
    _currRate = [NSNumber numberWithDouble:[currRate doubleValue]];
    [self refresh];
}

- (CwBtc*)add:(CwBtc*)btc
{
    NSNumber *newSatoshi = [NSNumber numberWithLongLong:[_satoshi longLongValue]+[[btc satoshi]longLongValue]];
    //_satoshi = [NSNumber numberWithLongLong:[_satoshi longLongValue]+[[btc satoshi]longLongValue]];
    CwBtc *_newBtc = [CwBtc BTCWithSatoshi:newSatoshi];
    return _newBtc;
}

- (CwBtc*)sub:(CwBtc*)btc
{
    NSNumber *newSatoshi = [NSNumber numberWithLongLong:[_satoshi longLongValue]-[[btc satoshi]longLongValue]];
    //_satoshi = [NSNumber numberWithLongLong:[_satoshi longLongValue]-[[btc satoshi]longLongValue]];
    CwBtc *_newBtc = [CwBtc BTCWithSatoshi:newSatoshi];
    return _newBtc;
}

- (bool)greater:(CwBtc*)btc
{
    if([_satoshi longLongValue] > [[btc satoshi] longLongValue])
        return YES;
    else
        return NO;
}

-(NSString *) getBTCDisplayFromUnit
{
    return [[OCAppCommon getInstance] convertBTCStringformUnit: self.satoshi.longLongValue];
}

@end
