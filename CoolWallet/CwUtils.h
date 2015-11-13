//
//  CwUtils.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/11/11.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CwUtils : NSObject

+ (NSData*) hexstringToData:(NSString*)hexStr;
+ (NSString*) dataToHexstring:(NSData*)data;

@end
