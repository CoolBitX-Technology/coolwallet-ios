//
//  CwExRetryTxSignLogout.h
//  CoolWallet
//
//  Created by wen on 2017/10/25.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import "CwExRetryModel.h"

@interface CwExRetryTxSignLogout : CwExRetryModel

@property (strong, nonatomic) NSData *txLoginHandle;
@property (strong, nonatomic) NSData *nonce;

@end
