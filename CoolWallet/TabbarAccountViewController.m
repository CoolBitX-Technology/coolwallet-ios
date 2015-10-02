//
//  UITabBarController+TabbarAccountViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/3/23.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabbarAccountViewController.h"
#import "SWRevealViewController.h"
#import "OCAppCommon.h"

@implementation TabbarAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectedIndex = 1;
    [[OCAppCommon getInstance] initSetting];
    
    //[[UITabBar appearance] setSelectedImageTintColor:[UIColor whiteColor]];
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    //add CW Logo
    UIImage* myImage = [UIImage imageNamed:@"logo2.png"];
    UIImageView* myImageView = [[UIImageView alloc] initWithImage:myImage];
    
    myImageView.frame = CGRectMake(100, 0, 160, 40);
    //myImageView.contentMode = UIViewContentModeCenter;
    [self.navigationController.navigationBar addSubview:myImageView];
    
    //hide back item text
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, 1000.f) forBarMetrics:UIBarMetricsDefault];
    
    self.tabBarController.tabBar.tintColor=[UIColor colorWithRed:255/255.0f green:156/255.0f blue:28/255.0f alpha:1.0];
}

- (IBAction)unwindToHomeViewcontroller:(UIStoryboardSegue *)unwindSegue
{
    NSLog(@"unwindToHomeViewcontroller");
    //[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    //[self.navigationController popViewControllerAnimated:YES];
}

@end
