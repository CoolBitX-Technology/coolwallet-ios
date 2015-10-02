//
//  UIViewController+WalletViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2014/10/19.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import "WalletViewController.h"
#import "SWRevealViewController.h"

@implementation WalletViewController : UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Wallet", nil);
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

- (IBAction)unwindToThisViewController:(UIStoryboardSegue *)unwindSegue
{
    //[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
