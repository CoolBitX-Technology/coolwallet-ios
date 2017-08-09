//
//  CwExchange.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/3/14.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CwExOpenOrder, CwExSellOrder, CwExBuyOrder, CwExUnblock;

@interface CwExchange : NSObject

@property (strong, nonatomic) NSMutableArray<CwExOpenOrder *> *openOrders;

@property (strong, nonatomic) NSMutableArray<CwExSellOrder *> *pendingSellOrders;
@property (strong, nonatomic) NSMutableArray<CwExBuyOrder *> *pendingBuyOrders;
@property (strong, nonatomic) NSMutableArray<CwExUnblock *> *unblockOrders;

@end
