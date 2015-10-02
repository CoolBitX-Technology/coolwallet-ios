//
//  CwManagerDelegate.h
//  CwTest
//
//  Created by CP Hsiao on 2014/12/5.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#ifndef CwTest_CwManagerDelegate_h
#define CwTest_CwManagerDelegate_h

#import <Foundation/Foundation.h>
#import "CwCard.h"

@class CwManager;

@protocol CwManagerDelegate <NSObject>

@optional

//scan cw
-(void) didCwManagerReady;
-(void) didScanCwCards: (NSMutableArray *) cwCards;

-(void) didConnectCwCard: (CwCard *) cwCard;
-(void) didConnectCwCardFail: (NSError *)error;
-(void) didDisconnectCwCard: (NSString *) cwCardName;

@end

#endif
