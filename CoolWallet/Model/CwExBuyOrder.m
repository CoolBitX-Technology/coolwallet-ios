//
//  CwExBuyOrder.m
//  CoolWallet
//
//  Created by wen on 2016/1/25.
//  Copyright (c) 2016年 MAC-BRYAN. All rights reserved.
//

#import "CwExBuyOrder.h"

@implementation CwExBuyOrder

- (NSDictionary *)rm_dataKeysForClassProperties
{
    return @{
             @"orderId" : @"orderId",
             @"cwOrderId" : @"cwOrderId",
             @"address" : @"addr",
             @"amountBTC" : @"amount",
             @"price" : @"price",
             @"accountId" : @"account",
             @"expirationUTC" : @"expiration",
             };
}

@end
