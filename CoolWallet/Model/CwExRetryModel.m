//
//  CwExRetryModel.m
//  CoolWallet
//
//  Created by wen on 2017/10/25.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import "CwExRetryModel.h"

@implementation CwExRetryModel

-(NSArray *) rm_excludedProperties
{
    return @[@"operation"];
}

-(instancetype _Nonnull) initWithCardId:(NSString *_Nonnull)cardId
{
    self = [super init];
    if (self) {
        self.cardId = cardId;
    }
    
    return self;
}

-(NSNumber *) retryStatus
{
    if (!_retryStatus) {
        _retryStatus = @(CwExKeepRetry);
    }
    
    return _retryStatus;
}

@end
