//
//  CwExRetryModel.h
//  CoolWallet
//
//  Created by wen on 2017/10/25.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+RMArchivable.h"

enum CwExRetryStatus
{
    CwExStopRetry,
    CwExKeepRetry
};

@interface CwExRetryModel : NSObject

@property (strong, nonatomic, nonnull) NSString *cardId;
@property (strong, nonatomic, nonnull) NSNumber *retryStatus;

-(instancetype _Nonnull) initWithCardId:(NSString *_Nonnull)cardId;

@end
