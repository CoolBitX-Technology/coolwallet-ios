//
//  ExMatchOrderVM.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/27.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "ExMatchOrderVM.h"
#import "CwExchange.h"
#import "CwCard.h"
#import "CwExSellOrder.h"
#import "CwExBuyOrder.h"

#import <RMMapper/RMMapper.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation ExMatchOrderVM

-(instancetype)init
{
    self = [super init];
    
    return self;
}

- (NSDictionary *)rm_dataKeysForClassProperties
{
    // country_code is json key, countryCode is class property
    return @{
             @"matchedSellOrders" : @"sell",
             @"matchedBuyOrders" : @"buy",
             };
}

-(Class)rm_itemClassForArrayProperty:(NSString *)property {
    if ([property isEqualToString:@"matchedSellOrders"]) {
        return [CwExSellOrder class];
    } else if ([property isEqualToString:@"matchedBuyOrders"]) {
        return [CwExBuyOrder class];
    }
    
    return nil;
}

-(void) requestMatchedOrders
{
    CwExchange *exchange = [CwExchange sharedInstance];
    NSString *url = [NSString stringWithFormat:ExGetMatchedOrders, exchange.card.cardId];
    AFHTTPRequestOperationManager *manager = [exchange defaultJsonManager];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
        [RMMapper populateObject:self fromDictionary:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        
    }];
}


@end
