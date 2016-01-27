//
//  NSDate+Localize.m
//  CoolWallet
//
//  Created by wen on 2015/10/17.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "NSDate+Localize.h"

@implementation NSDate(Localize)

-(NSString *) localizeDateString:(NSString *)format
{
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:format];
    
    //Create a date string in the local timezone
//    df.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:[NSTimeZone localTimeZone].secondsFromGMT];
    
    return [df stringFromDate:self];
}

-(NSString *) cwDateString
{
    return [self localizeDateString:@"dd MMM yyyy hh:mm a"];
}

-(NSString *) exDateString
{
    return [self localizeDateString:@"hh:mm aaa dd MMM"];
}

@end
