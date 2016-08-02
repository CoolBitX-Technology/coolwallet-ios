//
//  CwExSellOrder.h
//  CoolWallet
//
//  Created by wen on 2016/1/25.
//  Copyright (c) 2016年 MAC-BRYAN. All rights reserved.
//

#import "CwExOrderBase.h"

@interface CwExSellOrder : CwExOrderBase

//hex string: trxId(4B) + accId(4B) + amount(8B) + mac1(32B) + nonce(16B)
@property (strong, nonatomic) NSString *blockData;
@property (strong, nonatomic) NSData *trxHandle;

@end
