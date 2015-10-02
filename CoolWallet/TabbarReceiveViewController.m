//
//  UIViewController+TabbarReceiveViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/3/19.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabbarReceiveViewController.h"

@implementation TabbarReceiveViewController

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
