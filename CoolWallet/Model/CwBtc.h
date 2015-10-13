//
//  CWBTC.h
//  BCDC
//
//  Created by LIN CHIH-HUNG on 2014/8/28.
//  Copyright (c) 2014年 LIN CHIH-HUNG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CwBtc : NSObject

@property (nonatomic,readonly) NSNumber* currAmount;
@property (nonatomic) NSNumber* currRate;

@property (nonatomic) NSNumber* satoshi;
@property (nonatomic) NSNumber* muBTC;
@property (nonatomic) NSNumber* mBTC;
@property (nonatomic) NSNumber* BTC;

+ (id)BTCWithBTC:(NSNumber*)BTC;
+ (id)BTCWithMBTC:(NSNumber*)mBTC;
+ (id)BTCWithMuBTC:(NSNumber*)muBTC;
+ (id)BTCWithSatoshi:(NSNumber*)satoshi;

- (void)setSatoshi:(NSNumber*)satoshi;
- (void)setMuBTC:(NSNumber*)muBTC;
- (void)setMBTC:(NSNumber*)mBTC;
- (void)setBTC:(NSNumber*)BTC;
- (void)setCurrRate:(NSNumber*)currRate;

- (CwBtc*)add:(CwBtc*)btc;
- (CwBtc*)sub:(CwBtc*)btc;

- (bool)greater:(CwBtc*)btc;

-(NSString *) getBTCDisplayFromUnit;

@end
