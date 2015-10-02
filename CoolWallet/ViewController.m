//
//  ViewController.m
//  CoolWallet
//
//  Created by MAC-BRYAN on 2014/10/15.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    //[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"CWConnectState"];
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
- (IBAction)unwindToThisViewController:(UIStoryboardSegue *)unwindSegue
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
*/
@end
