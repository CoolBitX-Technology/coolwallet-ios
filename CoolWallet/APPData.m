//
//  APPData.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/29.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "APPData.h"

@interface APPData()

@property (readwrite, nonatomic) NSString *version;

@end

@implementation APPData

+(instancetype) sharedInstance
{
    static dispatch_once_t pred;
    static APPData *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[APPData alloc] init];
        
    });
    return sharedInstance;
}

-(id) init
{
    self = [super init];
    if (self) {
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        self.version = [NSString stringWithFormat:@"V%@", version];
#if DEBUG
        self.version = [self.version stringByAppendingFormat:@"(%@)", [infoDictionary objectForKey:@"CFBundleVersion"]];
#endif
    }
    
    return self;
}

-(NSString *) deviceToken
{
    if (_deviceToken) {
        return _deviceToken;
    } else {
        return @"";
    }
}

@end
