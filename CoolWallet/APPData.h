//
//  APPData.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/29.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APPData : NSObject

@property (strong, nonatomic) NSString *deviceToken;
@property (readonly, nonatomic) NSString *version;

+(instancetype) sharedInstance;

@end
