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
#import "NSDate+Localize.h"

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
//        responseObject = [self testDataWithMatchedOrders];
        [RMMapper populateObject:self fromDictionary:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        
    }];
}

-(NSDictionary *) testDataWithMatchedOrders
{
    NSDate *expireDate = [NSDate dateWithTimeIntervalSinceNow:12*60*60];
    NSString *expire = [expireDate localizeDateString:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    return @{
             @"sell": @[
                     @{
                         @"orderId": @"15847930",
                         @"addr": @"123456789012345678901234567890abcd",
                         @"amount": @"0.0002",
                         @"price": @"4",
                         @"account": @"1",
                         @"expiration": expire
                         },
                     @{
                         @"orderId": @"15847931",
                         @"addr": @"123456789012345678901234567890abcd",
                         @"amount": @"0.0001",
                         @"price": @"2",
                         @"account": @"1",
                         @"expiration": expire
                         },
                     @{
                         @"orderId": @"15847932",
                         @"addr": @"123456789012345678901234567890abcd",
                         @"amount": @"0.001",
                         @"price": @"10",
                         @"account": @"1",
                         @"expiration": expire
                         },
                     ],
             @"buy": @[
                     @{
                         @"orderId": @"25847930",
                         @"addr": @"abcd123456789012345678901234567890",
                         @"amount": @"0.0002",
                         @"price": @"4",
                         @"account": @"2",
                         @"expiration": expire
                         },
                     @{
                         @"orderId": @"25847931",
                         @"addr": @"0000123456789012345678901234567890",
                         @"amount": @"0.0005",
                         @"price": @"8",
                         @"expiration": expire
                         },
                     ]
             };
}


@end
