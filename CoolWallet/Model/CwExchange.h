//
//  CwExchange.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/12.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CwExchange : NSObject

@property (assign, nonatomic) BOOL loginSessionFinish;
@property (strong, nonatomic) NSData *loginSession;

+(id)sharedInstance;
-(void) loginExSession;
-(void) syncCardInfo;

@end
