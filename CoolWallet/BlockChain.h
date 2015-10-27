//
//  BlockChain.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/10/26.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CwBtcNetworkError.h"

@interface BlockChain : NSObject

-(GetBalanceByAddrErr) getBalanceByAccountID:(NSInteger)accountID;

@end
