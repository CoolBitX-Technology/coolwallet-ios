//
//  CwBlockInfo.h
//  CoolWallet
//
//  Created by wen on 2017/9/18.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

enum BlockStatus
{
    BlockWithoutLogin = 2,
    BlockWithLogin = 3,
    BlockNothing = 999 // block status is a 1 byte hex, the maximum is 255
};

@interface CwBlockInfo : NSObject

@property (assign, nonatomic) NSInteger blockStatus;
@property (assign, nonatomic) NSInteger blockAccountId;
@property (strong, nonatomic) NSNumber *blockAmount;

@end
