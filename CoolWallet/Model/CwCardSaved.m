//
//  CwCardSaved.m
//  CwTest
//
//  Created by Coolbitx on 2015/7/1.
//  Copyright (c) 2015年 CoolBitX Technology Ltd. All rights reserved.
//

#import "CwCardSaved.h"

@implementation CwCardSaved

- (void) encodeWithCoder:(NSCoder *)encoder {
    //[encoder encodeObject:self.cwHosts forKey:@"CwHosts"];
    [encoder encodeBool:self.securityPolicy_OtpEnable forKey:@"CwSpOtp"];
    [encoder encodeBool:self.securityPolicy_BtnEnable forKey:@"CwSpBtn"];
    [encoder encodeBool:self.securityPolicy_DisplayAddressEnable forKey:@"CwSpAddr"];
    [encoder encodeBool:self.securityPolicy_WatchDogEnable forKey:@"CwSpDog"];
    [encoder encodeBool:self.securityPolicy_WatchDogScale forKey:@"CwSpDogScale"];
    
    [encoder encodeObject:self.cardId forKey:@"CwCardId"];
    [encoder encodeObject:self.cardName forKey:@"CwCarName"];
    [encoder encodeObject:self.currId forKey:@"currId"];
    [encoder encodeObject:self.currRate forKey:@"currRate"];
    [encoder encodeInteger:self.hdwStatus forKey:@"HdwStatus"];
    [encoder encodeObject:self.hdwName forKey:@"HdwName"];
    [encoder encodeInteger:self.hdwAcccountPointer forKey:@"HdwAccPtr"];
    [encoder encodeObject:self.cwAccounts forKey:@"CwAccounts"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    //self.cwHosts = [decoder decodeObjectForKey:@"CwHosts"];
    
    self.securityPolicy_OtpEnable = [decoder decodeBoolForKey:@"CwSpOtp"];
    self.securityPolicy_BtnEnable =[decoder decodeBoolForKey:@"CwSpBtn"];
    
    self.securityPolicy_DisplayAddressEnable = [decoder decodeBoolForKey:@"CwSpAddr"];
    self.securityPolicy_WatchDogEnable = [decoder decodeBoolForKey:@"CwSpDog"];
    self.securityPolicy_WatchDogScale = [decoder decodeBoolForKey:@"CwSpDogScale"];
    
    self.cardId = [decoder decodeObjectForKey:@"CwCardId"];
    self.cardName = [decoder decodeObjectForKey:@"CwCarName"];
    self.currId = [decoder decodeObjectForKey:@"currId"];
    self.currRate = [decoder decodeObjectForKey:@"currRate"];
    self.hdwStatus = [decoder decodeIntegerForKey:@"HdwStatus"];
    self.hdwName = [decoder decodeObjectForKey:@"HdwName"];
    self.hdwAcccountPointer = [decoder decodeIntegerForKey:@"HdwAccPtr"];
    self.cwAccounts = [decoder decodeObjectForKey:@"CwAccounts"];

    return self;
}

@end
