//
//  UIViewController+BindSuccessViewController.m
//  CoolWallet
//
//  Created by MAC-BRYAN on 2014/10/15.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import "BindSuccessViewController.h"
#import "ViewController.h"

@implementation BindSuccessViewController 

- (IBAction)BtnNextToAccounts:(id)sender {
    [self showIndicatorView:NSLocalizedString(@"Login Host",nil)];
    [self.cwManager.connectedCwCard loginHost];
}

#pragma mark - CwCard Delegates
-(void) didLoginHost
{
    [self.cwManager.connectedCwCard defaultPersoSecurityPolicy];
}

-(void) didPersoSecurityPolicy
{
    [self performDismiss];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
    ViewController *myVC = (ViewController *)[storyboard instantiateViewControllerWithIdentifier:@"RevealViewController"];
    [self.navigationController presentViewController:myVC animated:YES completion:nil];
}

@end
