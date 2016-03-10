//
//  CwExUnclarifyOrder.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/3/8.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CwExUnclarifyOrder : NSObject

@property (strong, nonatomic) NSString *orderID;
@property (strong, nonatomic) NSNumber *amount; // satoshi
@property (strong, nonatomic) NSNumber *price;

@end
