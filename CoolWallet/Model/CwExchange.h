//
//  CwExchange.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/3/14.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CwExchange : NSObject

@property (strong, nonatomic) NSMutableArray *unclarifyOrders; // class CwExUnclarifyOrder
@property (strong, nonatomic) NSMutableArray *matchedSellOrders; // class CwExSellOrder
@property (strong, nonatomic) NSMutableArray *matchedBuyOrders; // class CwExBuyOrder
@property (strong, nonatomic) NSMutableArray *unblockOrders; // class CwExUnblock

@end
