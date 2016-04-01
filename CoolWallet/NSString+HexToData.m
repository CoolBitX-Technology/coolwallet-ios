//
//  NSString+HexToBytes.m
//  test.corebitcoin
//
//  Created by 鄭斐文 on 2015/11/17.
//  Copyright © 2015年 CoolBitx. All rights reserved.
//

#import "NSString+HexToData.h"

@implementation NSString(HexToData)

+ (NSData*) hexstringToData:(NSString*)hexStr
{
    NSMutableData *data = [[NSMutableData alloc]initWithCapacity:32];
    Byte byte;
    
    for (int i=0; 2*i<[hexStr length]; i++)
    {
        NSRange range = {2*i ,2};
        byte = strtol([[hexStr substringWithRange:range] UTF8String], NULL, 16);
        [data appendBytes:&byte length:1];
        
    }
    return data;
}

+ (NSString*) dataToHexstring:(NSData*)data
{
    NSString *hexStr = [NSString stringWithFormat:@"%@",data];
    NSRange range = {1,[hexStr length]-2};
    hexStr = [[hexStr substringWithRange:range] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    return hexStr;
}

+ (unsigned int)intFromHexString:(NSString *)hexStr
{
    unsigned int hexInt = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    
    // Tell scanner to skip the # character
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
    
    // Scan hex value
    [scanner scanHexInt:&hexInt];
    
    return hexInt;
}

@end
