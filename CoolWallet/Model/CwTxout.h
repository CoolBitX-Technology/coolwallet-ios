//
//  CWTxout.h
//  BCDC
//
//  Created by LIN CHIH-HUNG on 2014/9/2.
//  Copyright (c) 2014年 LIN CHIH-HUNG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CwBtc.h"

@interface CwTxout : NSObject

@property NSData* tid; //transaction ID
@property NSString* addr;
@property CwBtc* amount;
@property NSInteger n;
@property BOOL isSpent;

@end
