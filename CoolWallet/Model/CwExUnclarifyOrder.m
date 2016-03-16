//
//  CwExUnclarifyOrder.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/3/8.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "CwExUnclarifyOrder.h"

#import <RMMapper/RMMapper.h>

@implementation CwExUnclarifyOrder

- (NSDictionary *)rm_dataKeysForClassProperties
{
    return @{
             @"orderId" : @"orderId",
             @"amountBTC" : @"amount",
             @"price" : @"price",
             @"accountId" : @"account",
             };
}

@end
