//
//  CwExTx.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/30.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+RMArchivable.h"

@class CwTx, CwBtc, CwAddress;
@interface CwExTx : NSObject

@property (assign, nonatomic) NSString *orderId;
@property (assign, nonatomic) NSNumber *accountId;
@property (strong, nonatomic) NSString *okToken;
@property (strong, nonatomic) NSString *unblockToken;
@property (strong, nonatomic) NSData *loginHandle;
@property (strong, nonatomic) NSString *receiveAddress;
@property (strong, nonatomic) CwAddress *changeAddress;
@property (strong, nonatomic) CwBtc *amount;
@property (strong, nonatomic) CwTx *unsignedTx;
@property (strong, nonatomic) NSString *rawTx;
@property (strong, nonatomic) NSString *receipt;

@property (strong, nonatomic) NSString *trxId;
@property (strong, nonatomic, readonly) NSData *nonce;

-(instancetype) initWithOrderId:(NSString *)orderId accountId:(NSNumber *)accountId;

@end
