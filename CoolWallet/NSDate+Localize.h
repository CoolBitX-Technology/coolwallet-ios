//
//  NSDate+Localize.h
//  CoolWallet
//
//  Created by wen on 2015/10/17.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate(Localize)

-(NSString *) localizeDateString:(NSString *)format;
-(NSString *) cwDateString;
-(NSString *) exDateString;

@end
