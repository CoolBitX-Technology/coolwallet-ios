//
//  ExMatchOrderVM.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/27.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CwExSellOrder.h"
#import "CwExBuyOrder.h"

@interface ExMatchOrderVM : NSObject

@property (strong, nonatomic) NSMutableArray *matchedSellOrders;
@property (strong, nonatomic) NSMutableArray *matchedBuyOrders;

-(void) requestMatchedOrders;

@end
