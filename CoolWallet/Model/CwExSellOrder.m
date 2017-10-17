//
//  CwExSellOrder.m
//  CoolWallet
//
//  Created by wen on 2016/1/25.
//  Copyright (c) 2016年 MAC-BRYAN. All rights reserved.
//

#import "CwExSellOrder.h"
#import "CwExTx.h"
#import "CwBtc.h"

static NSString *KEYSELLORDER = @"sellOrders";

@implementation CwExSellOrder

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
             @"submitted": @"submitted"
             };
}

- (CwExTx *)exTrx
{
    if (!_exTrx) {
        _exTrx = [[CwExTx alloc] initWithOrderId:self.orderId accountId:self.accountId];
        _exTrx.amount = [CwBtc BTCWithBTC:self.amountBTC];
    }
    
    return _exTrx;
}

- (void) storeOrderWithCardId:(NSString *)cardId
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *allSellOrders = [userDefaults rm_customObjectForKey:KEYSELLORDER];
    if (!allSellOrders) {
        NSDictionary *cardOrders = @{cardId: @[self]};
        [userDefaults rm_setCustomObject:cardOrders forKey:KEYSELLORDER];
        return;
    }
    
    NSMutableDictionary *storedOrders = [NSMutableDictionary dictionaryWithDictionary:allSellOrders];
    NSArray *storedCardOrders = [storedOrders objectForKey:cardId];
    NSMutableArray *cardOrders = [NSMutableArray new];
    if (storedCardOrders) {
        cardOrders = [NSMutableArray arrayWithArray:storedCardOrders];
        NSArray *matchedOrders = [cardOrders filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"orderId == %@", self.orderId]];
        if (matchedOrders) {
            [cardOrders removeObjectsInArray:matchedOrders];
        }
    }
    
    [cardOrders addObject:self];
    [storedOrders setObject:cardOrders forKey:cardId];
    
    [userDefaults rm_setCustomObject:storedOrders forKey:KEYSELLORDER];
}

+ (NSArray *) getStoredOrdersWithCardId:(NSString *)cardId
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *allSellOrders = [userDefaults rm_customObjectForKey:KEYSELLORDER];
    if (allSellOrders) {
        return [allSellOrders objectForKey:cardId];
    } else {
        return nil;
    }
}

@end
