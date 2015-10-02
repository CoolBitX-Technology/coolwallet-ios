//
//  UIViewController+TransactionViewController.m
//  CoolWallet
//
//  Created by MAC-BRYAN on 2014/10/21.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import "TransactionViewController.h"
#import "SWRevealViewController.h"

@implementation TransactionViewController : UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"All Transaction", nil);
    //self.navigationItem.titleView.backgroundColor = [UIColor blueColor];
    
    SWRevealViewController *revealController = [self revealViewController];
    
    //[revealController panGestureRecognizer];
    //[revealController tapGestureRecognizer];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home-icon"]
                                                                         style:UIBarButtonItemStyleBordered target:nil action:@selector(revealToggle:)];
    
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    
    UIBarButtonItem *rightRevealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu-icon"]
                                                                              style:UIBarButtonItemStyleBordered target:revealController action:@selector(rightRevealToggle:)];
    
    self.navigationItem.rightBarButtonItem = rightRevealButtonItem;
    
}

@end
