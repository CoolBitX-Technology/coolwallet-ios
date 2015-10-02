//
//  CALayer+ColorConfig.m
//  CoolWallet
//
//  Created by MAC-BRYAN on 2014/10/15.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import "CALayer+ColorConfig.h"

@implementation CALayer (ColorConfig)

-(UIColor*)borderColorFromUIColor
{
    return [UIColor colorWithCGColor:self.borderColor];
}
-(UIColor*)shadowColorFromUIColor
{
    return [UIColor colorWithCGColor:self.shadowColor];
}
-(void)setBorderColorFromUIColor:(UIColor*)color
{
    self.borderColor = color.CGColor;
}
-(void)setShadowColorFromUIColor:(UIColor*)color
{
    self.shadowColor = color.CGColor;
}

@end
