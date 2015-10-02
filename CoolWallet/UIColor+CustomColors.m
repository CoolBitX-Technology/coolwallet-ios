//
//  UIColor+CustomColors.m
//  CoolWallet
//
//  Created by bryanLin on 2015/3/17.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "UIColor+CustomColors.h"

@implementation UIColor (CustomColors)

//黑
+(UIColor *) colorMainBackground{
    return [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0];
}
//淺灰
+(UIColor *) colorContentBackground{
    return [UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1.0];
}
//深灰
+(UIColor *) colorAccountBackground{
    return [UIColor colorWithRed:25.0/255.0 green:25.0/255.0 blue:25.0/255.0 alpha:1.0];
}

@end
