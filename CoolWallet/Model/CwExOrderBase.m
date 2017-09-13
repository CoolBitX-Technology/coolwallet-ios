//
//  CwExOrderBase.m
//  CoolWallet
//
//  Created by wen on 2016/1/25.
//  Copyright (c) 2016年 MAC-BRYAN. All rights reserved.
//

#import "CwExOrderBase.h"
#import "CwManager.h"

#import <RMMapper/RMMapper.h>

@interface CwExOrderBase()

@property (readwrite, nonatomic) NSDate *expiration;
@property (readwrite, nonatomic) CwAccount *cwAccount;

@end

@implementation CwExOrderBase

- (NSDictionary *)rm_dataKeysForClassProperties
{
    return @{
             @"orderId" : @"orderId",
             @"amountBTC" : @"amount",
             @"price" : @"price",
             @"accountId" : @"account",
             };
}

-(void)setExpirationUTC:(NSString *)expirationUTC
{
    _expirationUTC = expirationUTC;
    
    NSDateFormatter *dateformat = [[NSDateFormatter alloc]init];
    [dateformat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [dateformat setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    _expiration = [dateformat dateFromString:expirationUTC];
}

-(CwAccount *) cwAccount
{
    if (!_cwAccount || _cwAccount.accId != self.accountId.integerValue) {
        CwManager *cwManager = [CwManager sharedManager];
        _cwAccount = [cwManager.connectedCwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)self.accountId.integerValue]];
    }
    
    return _cwAccount;
}

@end
