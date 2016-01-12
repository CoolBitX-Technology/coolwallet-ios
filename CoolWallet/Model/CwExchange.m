//
//  CwExchange.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/12.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "CwExchange.h"
#import "CwCard.h"
#import "CwManager.h"

@interface CwExchange()

@property (strong, nonatomic) CwCard *card;

@end

@implementation CwExchange

+(id)sharedInstance
{
    static dispatch_once_t pred;
    static CwExchange *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[CwExchange alloc] init];
        CwManager *manager = [CwManager sharedManager];
        sharedInstance.card = manager.connectedCwCard;
    });
    return sharedInstance;
}

- (void)dealloc
{
    // implement -dealloc & remove abort() when refactoring for
    // non-singleton use.
    abort();
}

@end
