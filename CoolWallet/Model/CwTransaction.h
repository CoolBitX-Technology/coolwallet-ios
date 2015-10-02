//
//  CwTransaction.h
//  CwTest
//
//  Created by CP Hsiao on 2015/1/15.
//  Copyright (c) 2015年 CP Hsiao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CwTransaction : NSObject

@property (nonatomic) NSInteger cmdId;
@property NSInteger cmdP1;
@property NSInteger cmdP2;
@property NSData *cmdInput;
@property NSData *cmdOutput;
@property NSInteger cmdResult;
@property BOOL busy;

@end
