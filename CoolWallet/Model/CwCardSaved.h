//
//  CwCardSaved.h
//  CwTest
//
//  Created by Coolbitx on 2015/7/1.
//  Copyright (c) 2015年 CoolBitX Technology Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CwCardSaved : NSObject <NSCoding>

//@property NSMutableDictionary *cwHosts;

@property BOOL securityPolicy_OtpEnable;
@property BOOL securityPolicy_BtnEnable;
@property BOOL securityPolicy_DisplayAddressEnable;
@property BOOL securityPolicy_WatchDogEnable;
@property NSInteger securityPolicy_WatchDogScale;

@property NSString *cardId;
@property NSString *cardName;
@property NSString *currId;
@property NSDecimalNumber *currRate;

@property NSInteger hdwStatus;
@property NSString *hdwName;
@property NSInteger hdwAcccountPointer;

@property NSMutableDictionary *cwAccounts;

@end
