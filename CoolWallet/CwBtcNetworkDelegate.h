//
//  CwBtcNetworkDelegate.h
//  CoolWallet
//
//  Created by Coolbitx on 2015/9/29.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#ifndef CwBtcNetworkDelegate_h
#define CwBtcNetworkDelegate_h

@class CwTx;

@protocol CwBtcNetworkDelegate <NSObject>

//@required

@optional

-(void) didGetTransactionByAccount: (NSInteger) accId;
-(void) didPublishTransactionWith:(CwTx *)tx result:(NSData *)result error:(NSError *)error;

@end

#endif /* CwBtcNetworkDelegate_h */
