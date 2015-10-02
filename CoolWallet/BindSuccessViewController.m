//
//  UIViewController+BindSuccessViewController.m
//  CoolWallet
//
//  Created by MAC-BRYAN on 2014/10/15.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import "BindSuccessViewController.h"
#import "ViewController.h"

CwManager *cwManager;
CwCard *cwCard;

@implementation BindSuccessViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //find CW via BLE
    cwManager = [CwManager sharedManager];
    cwCard = cwManager.connectedCwCard;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    cwCard.delegate = self;
    cwManager.delegate = self;
    
}

- (IBAction)BtnNextToAccounts:(id)sender {
    [cwCard loginHost];
    
    /*
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
    ViewController *myVC = (ViewController *)[storyboard instantiateViewControllerWithIdentifier:@"RevealViewController"];
    [self.navigationController presentViewController:myVC animated:YES completion:nil];
    */
}

#pragma mark - CwCard Delegates
-(void) didLoginHost
{
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
    ViewController *myVC = (ViewController *)[storyboard instantiateViewControllerWithIdentifier:@"RevealViewController"];
    [self.navigationController presentViewController:myVC animated:YES completion:nil];
    /*
     // Get the storyboard named secondStoryBoard from the main bundle:
     UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
     
     // Load the view controller with the identifier string myTabBar
     // Change UIViewController to the appropriate class
     UIViewController *theTabBar = (UIViewController *)[secondStoryBoard instantiateViewControllerWithIdentifier:@"AccountMain"];
     
     // Then push the new view controller in the usual way:
     [self.navigationController presentViewController:theTabBar animated:YES completion:nil];*/
}

-(void) didLogoutHost
{
    
    [cwManager disconnectCwCard];
    
    //clear properties
    cwCard = nil;
    
    NSLog(@"CW Released");
    
    //[self.cwMgr scanCwCards];
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    NSLog(@"%@",@"didDisconnectCwCard");
    //Add a notification to the system
    UILocalNotification *notify = [[UILocalNotification alloc] init];
    notify.alertBody = [NSString stringWithFormat:@"%@ Disconnected", cardName];
    notify.soundName = UILocalNotificationDefaultSoundName;
    notify.applicationIconBadgeNumber=1;
    [[UIApplication sharedApplication] presentLocalNotificationNow: notify];
    
    // Get the storyboard named secondStoryBoard from the main bundle:
    UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    // Load the view controller with the identifier string myTabBar
    // Change UIViewController to the appropriate class
    UIViewController *listCV = (UIViewController *)[secondStoryBoard instantiateViewControllerWithIdentifier:@"CwMain"];
    // Then push the new view controller in the usual way:
    [self.parentViewController presentViewController:listCV animated:YES completion:nil];
}

@end
