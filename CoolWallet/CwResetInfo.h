//
//  CwResetInfo.h
//  CoolWallet
//
//  Created by wen on 2017/7/23.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RMMapper/RMMapper.h>
#import "NSObject+RMArchivable.h"

@interface CwResetInfo : NSObject <RMMapping>

@property (strong, nonatomic) NSString *cardId;
@property (strong, nonatomic) NSString *pinOld;
@property (strong, nonatomic) NSString *pinNew;

- (instancetype)initWithCardId:(NSString *)cardId;
- (void) saveResetInfo;

@end
