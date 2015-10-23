//
//  CwCardInfo.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/10/21.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import "CwCardInfo.h"
#import "CwCard.h"

@implementation CwCardInfo

-(id) init
{
    self = [super init];
    
    if (!self) {
        self.securityPolicy_OtpEnable = [NSNumber numberWithBool:NO];
        self.securityPolicy_BtnEnable = [NSNumber numberWithBool:YES];
        self.securityPolicy_DisplayAddressEnable = [NSNumber numberWithBool:NO];
        self.securityPolicy_WatchDogEnable = [NSNumber numberWithBool:NO];
        
        self.cwHosts = [NSMutableDictionary new];
        self.cwAccounts = [NSMutableDictionary new];
    }
    
    return self;
}

-(id) initFromCwCard:(CwCard *)card
{
    self = [self init];
    
    self.mode = card.mode;
    self.state = card.state;
    self.fwVersion = card.fwVersion;
    self.uid = card.uid;
    self.devCredential = card.devCredential;
    self.hostId = card.hostId;
    self.hostOtp = card.hostOtp;
    self.hostConfirmStatus = card.hostConfirmStatus;
    self.securityPolicy_BtnEnable = card.securityPolicy_BtnEnable;
    self.securityPolicy_OtpEnable = card.securityPolicy_OtpEnable;
    self.securityPolicy_DisplayAddressEnable = card.securityPolicy_DisplayAddressEnable;
    self.securityPolicy_WatchDogEnable = card.securityPolicy_WatchDogScale;
    self.cardName = card.cardName;
    self.cardId = card.cardId;
    self.currId = card.currId;
    self.currRate = card.currRate;
    self.hdwAcccountPointer = card.hdwAcccountPointer;
    self.hdwName = card.hdwName;
    self.hdwStatus = card.hdwStatus;
    self.cwAccounts = card.cwAccounts;
    self.cwHosts = card.cwHosts;
    
    return self;
}

-(void) setSecurityPolicy_OtpEnable:(NSNumber *)securityPolicy_OtpEnable
{
    if (!securityPolicy_OtpEnable.boolValue && !self.securityPolicy_BtnEnable.boolValue) {
        _securityPolicy_BtnEnable = [NSNumber numberWithBool:YES];
    }
    
    _securityPolicy_OtpEnable = securityPolicy_OtpEnable;
}

-(void) setSecurityPolicy_BtnEnable:(NSNumber *)securityPolicy_BtnEnable
{
    if (!securityPolicy_BtnEnable && !self.securityPolicy_OtpEnable) {
        _securityPolicy_OtpEnable = [NSNumber numberWithBool:YES];
    }
    
    _securityPolicy_BtnEnable = securityPolicy_BtnEnable;
}

@end
