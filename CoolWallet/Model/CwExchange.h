//
//  CwExchange.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/12.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM (int, ExSessionStatus) {
    ExSessionNone,
    ExSessionProcess,
    ExSessionLogin,
    ExSessionFail
};

@interface CwExchange : NSObject

@property (readonly, assign) ExSessionStatus sessionStatus;

+(id)sharedInstance;
-(void) loginExSession;
-(void) syncCardInfo;

@end
