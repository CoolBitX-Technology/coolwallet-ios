//
//  CwExchange.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/3/14.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "CwExchange.h"
#import "CwExSellOrder.h"
#import "CwExBuyOrder.h"

#import <RMMapper/RMMapper.h>

@implementation CwExchange

- (NSDictionary *)rm_dataKeysForClassProperties
{
    return @{
             @"pendingSellOrders" : @"sell",
             @"pendingBuyOrders" : @"buy",
             };
}

-(Class)rm_itemClassForArrayProperty:(NSString *)property {
    if ([property isEqualToString:@"pendingSellOrders"]) {
        return [CwExSellOrder class];
    } else if ([property isEqualToString:@"pendingBuyOrders"]) {
        return [CwExBuyOrder class];
    }
    
    return nil;
}

@end
