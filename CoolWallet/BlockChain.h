//
//  BlockChain.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/10/26.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CwBtcNetworkError.h"

#ifdef DEBUG
#define BlockChainBaseURL @"https://testnet.blockchain.info/"
//#define BlockChainBaseURL @"https://blockchain.info"
#else
#define BlockChainBaseURL @"https://blockchain.info"
#endif

#define MultiAddrAPI @"multiaddr"
#define UnspentAPI @"unspent"
#define ExchangeRateAPI @"ticker"

@interface BlockChain : NSObject

-(GetBalanceByAddrErr) getBalanceByAccountID:(NSInteger)accountID;
-(NSDictionary *) getCurrencyRates;

@end
