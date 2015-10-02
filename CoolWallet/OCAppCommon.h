//
//  OCAppCommon.h
//  NSPhoneLite
//
//  Created by Sean on 13/8/13.
//  Copyright (c) 2013年  Netstock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppGlobal.h"

@interface OCAppCommon : NSObject{
    @public
        bool SW;
        bool menuToggle;
        NSMutableDictionary *MySymbolsDictionary;
}

@property(nonatomic, strong)NSString *BitcoinUnit;
@property(nonatomic, strong)NSString *Currency;

@property(nonatomic, strong)NSMutableArray *ShopinfoList;
@property(strong, nonatomic)NSMutableDictionary *ShopinfoDictionary;
@property(strong, nonatomic)NSMutableDictionary *SysconfigDictionary;
@property(strong, nonatomic)NSMutableDictionary *TakeNumberDictionary;

@property(nonatomic, strong)NSArray *MenuArray;
@property(nonatomic, strong)NSArray *WalletArray;

@property(nonatomic, strong)NSString *RootPath;
@property(nonatomic, strong)NSString *SysconfigFullPath;
@property(nonatomic, strong)NSString *QRcodeFullPath;
@property(nonatomic, strong)NSString *HistoryFullPath;

+(OCAppCommon*)getInstance;

- (void) initSetting;
- (NSString *) convertBTCStringformUnit:(int64_t)Bitcoin;
- (NSString *) convertFiatMoneyString:(int64_t)Bitcoin currRate:(NSDecimalNumber *)currRate;
- (NSString *) convertBTCFromFiatMoney:(double)Fiatmoney currRate:(NSDecimalNumber *)currRate;
- (NSString *) convertBTCtoSatoshi:(NSString *)btc;

@end

