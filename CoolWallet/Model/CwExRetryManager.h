//
//  CwExRetryManager.h
//  CoolWallet
//
//  Created by wen on 2017/10/25.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+RMArchivable.h"

@class CwExRetryTxSignLogout, CwExSellOrder, CwTx;

@interface CwExRetryManager : NSObject

+(instancetype) sharedInstance;

-(void) saveRetryTxSignLogout:(CwExRetryTxSignLogout *)retryTxSignLogout;
-(void) saveReceiptFrom:(CwExSellOrder *)sellOrder;
-(void) saveTx:(CwTx *)tx;

-(void) startRetry;

-(void) clear;

@end
