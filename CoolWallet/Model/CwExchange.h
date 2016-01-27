//
//  CwExchange.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/12.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CwExAPI.h"

#import <AFNetworking/AFNetworking.h>

@class CwCard;

@interface CwExchange : NSObject

@property (readonly, nonatomic) CwCard *card;
@property (readonly, assign) ExSessionStatus sessionStatus;

+(id)sharedInstance;
-(void) loginExSession;
-(void) syncCardInfo;

-(AFHTTPRequestOperationManager *) defaultJsonManager;

@end
