//
//  CwManager.h
//  CwTest
//
//  Created by CP Hsiao on 2014/12/5.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CwManagerDelegate.h"

@interface CwManager : NSObject

@property (nonatomic, assign) id<CwManagerDelegate> delegate;
@property (strong, nonatomic) CwCard *connectedCwCard;

//used for Singleton
+(id) sharedManager;

-(void) scanCwCards; //didScanCwCards
-(void) stopScan;
-(void) connectCwCard: (CwCard *)cwCard; //didConnectCwCard
-(void) disconnectCwCard; //didDisconnectCwCard

@end
