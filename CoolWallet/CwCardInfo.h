//
//  CwCardInfo.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/10/21.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+RMArchivable.h"
#import "CwCard.h"

@class CwCard;

@interface CwCardInfo : NSObject

#pragma mark - CwProperties - Basic Info
@property (copy, nonatomic) NSNumber *mode;
@property (copy, nonatomic) NSNumber *state;
@property (copy, nonatomic) NSString *fwVersion;
@property (copy, nonatomic) NSString *uid;

#pragma mark - CwProperties - Host Info
@property (copy, nonatomic) NSString *devCredential; //Query and input from the UIDevice
@property (copy, nonatomic) NSNumber *hostId;
@property (copy, nonatomic) NSNumber *hostConfirmStatus;
@property (copy, nonatomic) NSString *hostOtp;

@property NSMutableDictionary *cwHosts;

#pragma mark - CwProperties - Securityp Policy
@property (copy, nonatomic) NSNumber *securityPolicy_OtpEnable;
@property (copy, nonatomic) NSNumber *securityPolicy_BtnEnable;
@property (copy, nonatomic) NSNumber *securityPolicy_DisplayAddressEnable;
@property (copy, nonatomic) NSNumber *securityPolicy_WatchDogEnable;
//@property NSNumber *securityPolicy_WatchDogScale;

#pragma mark - CwProperties - Card Info
@property (copy, nonatomic) NSString *cardName;
@property (copy, nonatomic) NSString *cardId;
@property (copy, nonatomic) NSString *currId;
@property (copy, nonatomic) NSDecimalNumber *currRate;

#pragma mark - CwProperties - HDW Info
@property (copy, nonatomic) NSNumber *hdwStatus;
@property (copy, nonatomic) NSString *hdwName;
@property (copy, nonatomic) NSNumber *hdwAcccountPointer;

@property (copy, nonatomic) NSMutableDictionary *cwAccounts;

-(id) initFromCwCard:(CwCard *)card;

@end
