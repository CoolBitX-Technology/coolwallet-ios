//
//  CwExchange.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/12.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CwExAPI.h"

#import <AFNetworking/AFNetworking.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@class CwCard, CwAccount, CwExUnblock, CwExchange, CwExSellOrder, CwAddress;

@interface CwExchangeManager : NSObject

@property (readonly, nonatomic) CwCard *card;
@property (readonly, assign) ExSessionStatus sessionStatus;
@property (readonly, nonatomic) BOOL cardInfoSynced;
@property (readonly, nonatomic) CwExchange *exchange;

+(id)sharedInstance;

-(BOOL) isCardLoginEx:(NSString *)cardId;

-(void) loginExSession;
-(void) syncCardInfo;
-(void) requestOpenOrders;
-(void) requestPendingOrders;
-(void) requestMatchedOrder:(NSString *)orderId;
-(void) blockWithOrderID:(NSString *)hexOrderID withOTP:(NSString *)otp withSuccess:(void(^)(void))successCallback error:(void(^)(NSError *error))errorCallback finish:(void(^)(void))finishCallback;
-(void) prepareTransactionFromSellOrder:(CwExSellOrder *)sellOrder withChangeAddress:(CwAddress *)changeAddress;
-(void) completeTransactionWith:(CwExSellOrder *)sellOrder;
-(void) unblockOrderWithOrderId:(NSString *)orderId;

-(RACSignal *)signalCancelOrder:(NSString *)orderId;

-(AFHTTPRequestOperationManager *) defaultJsonManager;

@end
