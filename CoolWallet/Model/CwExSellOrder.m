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
        _exTrx = [CwExTx new];
        _exTrx.accountId = self.accountId.integerValue;
        _exTrx.amount = [CwBtc BTCWithBTC:self.amountBTC];
    }
    
    return _exTrx;
}

@end
