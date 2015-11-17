//
//  NSString+HexToBytes.h
//  test.corebitcoin
//
//  Created by 鄭斐文 on 2015/11/17.
//  Copyright © 2015年 CoolBitx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(HexToData)

+ (NSData*) hexstringToData:(NSString*)hexStr;
+ (NSString*) dataToHexstring:(NSData*)data;

@end
