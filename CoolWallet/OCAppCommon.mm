//
//  OCAppCommon.m
//  NSPhoneLite
//
//  Created by Sean on 13/8/13.
//  Copyright (c) 2013年  Netstock. All rights reserved.
//

#import "OCAppCommon.h"
//#import "DDXMLDocument.h"
//#import "DDXMLElement.h"
//#import "DDXMLElementAdditions.h"
//#import "ShopDetailInfo.h"

@implementation OCAppCommon

@synthesize MenuArray;
@synthesize WalletArray;
@synthesize BitcoinUnit;
@synthesize Currency;

static OCAppCommon *instance =nil;

UInt32 big5 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5_HKSCS_1999); //
// kCFStringEncodingBig5            /* Big-5 (has variants) */
// kCFStringEncodingBig5_E          /* Taiwan Big-5E standard */
// kCFStringEncodingBig5_HKSCS_1999 /* Big-5 with Hong Kong special char set supplement*/

+(OCAppCommon *)getInstance
{
    @synchronized(self)
    {
        if(instance==nil)
        {
            instance= [OCAppCommon new];
        }
    }
    return instance;
}

- (void) initSetting
{
    //MenuArray  = [[NSArray alloc]initWithObjects: @"Home" ,@"New Wallet",@"Address Book",@"Setting",@"Backup",@"Logout", nil];
    //WalletArray = [[NSArray alloc]initWithObjects: @"Home", nil];
    
    NSUserDefaults *profile = [NSUserDefaults standardUserDefaults];
    NSString *unit = [profile objectForKey:@"BitcoinUnit"];
    if(unit == nil) {
        BitcoinUnit = @"BTC";
        [profile setObject:BitcoinUnit forKey:@"BitcoinUnit"];
    }else{
        BitcoinUnit = unit;
    }
    Currency = @"USD";
}

- (NSString *) convertBTCStringformUnit:(int64_t)Bitcoin
{
    NSLog(@"%lld, %@", Bitcoin, BitcoinUnit);
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    [fmt setPositiveFormat:@"0.########"];
    NSString *btcstr = nil;
    if([BitcoinUnit compare:@"BTC"] == 0) {
        double btc = (double)Bitcoin/100000000;
        //btcstr = [NSString stringWithFormat:@"%f", btc ];
        btcstr = [fmt stringFromNumber:[NSNumber numberWithDouble:btc]];
    }else if([BitcoinUnit compare:@"mBTC"] == 0) {
        double btc = (double)Bitcoin/100000;
        btcstr = [fmt stringFromNumber:[NSNumber numberWithDouble:btc]];
    }else if([BitcoinUnit compare:@"µBTC"] == 0) {
        double btc = (double)Bitcoin/100;
        btcstr = [fmt stringFromNumber:[NSNumber numberWithDouble:btc]];
    }
    
   return btcstr;
}

- (NSString *) convertFiatMoneyString:(int64_t)satoshi currRate:(NSDecimalNumber *)currRate
{
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    [fmt setPositiveFormat:@"0.##"];
    NSString *FiatMoneyStr = nil;
    double btc = (double)satoshi/100000000;
    if([Currency compare:@"USD"] == 0) {
        double fiatmoney = (double) btc * ([currRate doubleValue]/100);
        //NSLog(@"%.8f %f %f",fiatmoney, (double) btc, [currRate doubleValue]/100);
        FiatMoneyStr = [fmt stringFromNumber:[NSNumber numberWithDouble:fiatmoney]];
    }else{
        double fiatmoney = (double) btc * ([currRate doubleValue]/100);
        FiatMoneyStr = [fmt stringFromNumber:[NSNumber numberWithDouble:fiatmoney]];
    }
    
    return FiatMoneyStr;
}

- (NSString *) convertBTCFromFiatMoney:(double)Fiatmoney currRate:(NSDecimalNumber *)currRate
{
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    [fmt setPositiveFormat:@"0.########"];
    
    NSString *btcstr = nil;
    double btc = Fiatmoney / ([currRate doubleValue]/100);
    btcstr = [fmt stringFromNumber:[NSNumber numberWithDouble:btc ]];
    //int64_t amount = btc * 100000000 ;
    //satoshi = [fmt stringFromNumber:[NSNumber numberWithLongLong: amount ]];
    
    return btcstr;
}

- (NSString *) convertBTCtoSatoshi:(NSString *)btc
{
    NSString *satoshi = nil;
    
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    [fmt setPositiveFormat:@"0.##"];
    if([btc compare:@""] != 0)
    {
        int64_t amount = (int64_t)([btc doubleValue] * 1e8 + ([btc doubleValue] < 0.0 ? -.5:.5));
        satoshi = [fmt stringFromNumber:[NSNumber numberWithLongLong: amount ]];
        
    }else{
        satoshi = @"0";
    }
    
    return satoshi;
}

@end