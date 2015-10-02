//
//  CwCardSoft.h
//  CwTest
//
//  Created by CP Hsiao on 2014/12/23.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CwCardCommand.h"

@interface CwCardSoft : NSObject

-(void) processCwCardCommand: (CwCardCommand *)cmd;

@end
