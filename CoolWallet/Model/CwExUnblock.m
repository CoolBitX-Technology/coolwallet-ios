//
//  CwExUnblock.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/3/9.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "CwExUnblock.h"
#import "NSString+HexToData.h"

#import <RMMapper/RMMapper.h>

@interface CwExUnblock()

@property (readwrite) NSData *nonce;

@end

@implementation CwExUnblock

- (NSDictionary *)rm_dataKeysForClassProperties
{
    return @{
             @"orderID" : @"orderId",
             @"okToken" : @"okToken",
             @"unblockToken" : @"unblockTkn",
             @"mac": @"mac"
             };
}

-(void) setOrderID:(NSData *)orderID
{
    if ([orderID isKindOfClass:[NSString class]]) {
        _orderID = [NSString hexstringToData:(NSString *)orderID];
    } else {
        _orderID = orderID;
    }
}

-(void) setOkToken:(NSData *)okToken
{
    if ([okToken isKindOfClass:[NSString class]]) {
        _okToken = [NSString hexstringToData:(NSString *)okToken];
    } else {
        _okToken = okToken;
    }
}

-(void) setUnblockToken:(NSData *)unblockToken
{
    if ([unblockToken isKindOfClass:[NSString class]]) {
        _unblockToken = [NSString hexstringToData:(NSString *)unblockToken];
    } else {
        _unblockToken = unblockToken;
    }
}

-(void) setMac:(NSData *)mac
{
    if ([mac isKindOfClass:[NSString class]]) {
        _mac = [NSString hexstringToData:(NSString *)mac];
    } else {
        _mac = mac;
    }
}

-(NSData *)nonce
{
    if (self.mac) {
        _nonce = [NSData dataWithBytes:[self.mac bytes] length:16];
    }
    
    return _nonce;
}

@end
