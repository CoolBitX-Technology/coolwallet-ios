//
//  CALayer+ColorConfig.h
//  CoolWallet
//
//  Created by MAC-BRYAN on 2014/10/15.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface CALayer (ColorConfig)

@property(nonatomic, assign) UIColor* borderColorFromUIColor;
@property(nonatomic, assign) UIColor* shadowColorFromUIColor;

@end
