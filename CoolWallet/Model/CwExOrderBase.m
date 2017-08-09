//
//  CwExOrderBase.m
//  CoolWallet
//
//  Created by wen on 2016/1/25.
//  Copyright (c) 2016年 MAC-BRYAN. All rights reserved.
//

#import "CwExOrderBase.h"

#import <RMMapper/RMMapper.h>

@interface CwExOrderBase()

@property (readwrite, nonatomic) NSDate *expiration;

@end

@implementation CwExOrderBase

- (NSDictionary *)rm_dataKeysForClassProperties
{
    return @{
             @"orderId" : @"orderId",
//             @"cwOrderId" : @"cwOrderId",
//             @"address" : @"addr",
             @"amountBTC" : @"amount",
             @"price" : @"price",
             @"accountId" : @"account",
//             @"expirationUTC" : @"expiration",
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

@end
