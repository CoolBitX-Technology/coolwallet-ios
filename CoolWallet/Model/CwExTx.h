//
//  CwExTx.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/30.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CwTx, CwBtc, CwAddress;
@interface CwExTx : NSObject

@property (assign, nonatomic) NSInteger accountId;
@property (strong, nonatomic) NSData *loginHandle;
@property (strong, nonatomic) NSString *receiveAddress;
@property (strong, nonatomic) CwAddress *changeAddress;
@property (strong, nonatomic) CwBtc *amount;
@property (strong, nonatomic) CwTx *unsignedTx;

@property (strong, nonatomic) NSString *trxId;
@property (strong, nonatomic, readonly) NSData *nonce;

@end
