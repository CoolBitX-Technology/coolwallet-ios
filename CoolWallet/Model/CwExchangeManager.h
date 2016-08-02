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

@class CwCard, CwAccount, CwExUnblock, CwExchange, CwExSellOrder;

@interface CwExchangeManager : NSObject

@property (readonly, nonatomic) CwCard *card;
@property (readonly, assign) ExSessionStatus sessionStatus;
@property (readonly, nonatomic) BOOL cardInfoSynced;
@property (readonly, nonatomic) CwExchange *exchange;

+(id)sharedInstance;

-(BOOL) isCardLoginEx:(NSString *)cardId;

-(void) loginExSession;
-(void) syncCardInfo;
-(void) requestUnclarifyOrders;
-(void) requestMatchedOrders;
-(void) requestMatchedOrder:(NSString *)orderId;
-(void) blockWithOrderID:(NSString *)hexOrderID withOTP:(NSString *)otp withSuccess:(void(^)(void))successCallback error:(void(^)(NSError *error))errorCallback finish:(void(^)(void))finishCallback;
-(void) prepareTransactionFromSellOrder:(CwExSellOrder *)sellOrder withChangeAddress:(NSString *)changeAddress andAccountId:(NSInteger)accountId;
-(void) completeTransactionWithOrderId:(NSString *)orderId TxId:(NSString *)txId Handle:(NSData *)trxHandle;
-(void) unblockOrders;
-(void) unblockOrderWithOrderId:(NSString *)orderId;

-(AFHTTPRequestOperationManager *) defaultJsonManager;

@end
