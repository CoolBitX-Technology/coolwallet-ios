//
//  CwBtcNetworkDelegate.h
//  CoolWallet
//
//  Created by Coolbitx on 2015/9/29.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#ifndef CwBtcNetworkDelegate_h
#define CwBtcNetworkDelegate_h

@protocol CwBtcNetworkDelegate <NSObject>

//@required

@optional

-(void) didGetTransactionByAccount: (NSInteger) accId;

@end

#endif /* CwBtcNetworkDelegate_h */
