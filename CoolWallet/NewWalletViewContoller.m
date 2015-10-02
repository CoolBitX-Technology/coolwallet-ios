//
//  UIViewController+NewWalletViewContoller.m
//  CoolWallet
//
//  Created by bryanLin on 2014/10/18.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import "NewWalletViewContoller.h"
#import "SWRevealViewController.h"
#import "HomeViewController.h"

@implementation NewWalletViewContoller :UIViewController 


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"New Wallet", nil);
    self.navigationItem.titleView.backgroundColor = [UIColor blueColor];
    
    SWRevealViewController *revealController = [self revealViewController];
    
    //[revealController panGestureRecognizer];
    //[revealController tapGestureRecognizer];
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home-icon"]
        style:UIBarButtonItemStyleBordered target:nil action:@selector(revealToggle:)];
    
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    UIBarButtonItem *rightRevealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu-icon.png"]
        style:UIBarButtonItemStyleBordered target:revealController action:@selector(rightRevealToggle:)];
    
    self.navigationItem.rightBarButtonItem = rightRevealButtonItem;
    
}

- (IBAction)unwindToThisViewController:(UIStoryboardSegue *)unwindSegue
{
    //[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btn_done:(id)sender {
    SWRevealViewController *revealController = self.revealViewController;
    UIViewController *newFrontController = nil;
    newFrontController = [[HomeViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:newFrontController];
    [revealController pushFrontViewController:navigationController animated:YES];
    
}
@end
