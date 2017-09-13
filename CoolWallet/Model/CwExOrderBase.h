//
//  CwExOrderBase.h
//  CoolWallet
//
//  Created by wen on 2016/1/25.
//  Copyright (c) 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CwAccount;

@interface CwExOrderBase : NSObject

@property (strong, nonatomic) NSString *orderId;
@property (strong, nonatomic) NSString *cwOrderId;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) NSNumber *amountBTC;
@property (strong, nonatomic) NSNumber *price;
@property (strong, nonatomic) NSNumber *accountId;
@property (strong, nonatomic) NSString *expirationUTC;

@property (readonly, nonatomic) NSDate *expiration;

@property (readonly, nonatomic) CwAccount *cwAccount;

@end
