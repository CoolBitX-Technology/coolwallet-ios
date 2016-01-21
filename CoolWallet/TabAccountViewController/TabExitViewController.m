//
//  TabExitViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/16.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "TabExitViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "SWRevealViewController.h"
#import "CwBtcNetWork.h"
#import "CwExchange.h"

@interface TabExitViewController ()
- (IBAction)btnDisconnectCw:(id)sender;
@end

@implementation TabExitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    //Navigate Bar UI effect
    //add CW Logo
    UIImage* myImage = [UIImage imageNamed:@"logout.png"];
    UIImageView* myImageView = [[UIImageView alloc] initWithImage:myImage];
    
    myImageView.frame = CGRectMake(80, 5, 30, 30);
    [self.navigationController.navigationBar addSubview:myImageView];
    /*
    //change navigation bar font
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    [self.navigationController.navigationBar setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                      [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                                      shadow, NSShadowAttributeName,
                                                                      [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:21.0], NSFontAttributeName, nil]];
     */
    
    //find CW via BLE
    self.cwManager = [CwManager sharedManager];
    self.cwManager.delegate=self;
    
}

-(void)viewWillAppear:(BOOL)animated{
    self.cwManager.connectedCwCard.delegate=self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma marks - Actions
- (IBAction)btnDisconnectCw:(id)sender {
    [self showIndicatorView:@"Logout..."];
    
    CwBtcNetWork *network = [CwBtcNetWork sharedManager];
    network.delegate = nil;
    
    CwExchange *exchange = [CwExchange sharedInstance];
    if (exchange.loginSession != nil) {
        [self.cwManager.connectedCwCard exSessionLogout];
    } else {
        [self.cwManager.connectedCwCard logoutHost];
    }
}

#pragma marks - CwCardDelegate
-(void) didCwCardCommand
{
}

-(void) didExSessoinLogout
{
    [self.cwManager.connectedCwCard logoutHost];
}

-(void) didLogoutHost
{
    [self.cwManager disconnectCwCard];
    
    NSLog(@"CW LogoutHost");
}

#pragma marks - CwManagerDelegates

-(void) didDisconnectCwCard: (NSString *) cwCardName
{
    NSLog(@"CW %@ Disconnected", cwCardName);
    
    [self performDismiss];

    // Get the storyboard named secondStoryBoard from the main bundle:
    UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // Load the view controller with the identifier string myTabBar
    // Change UIViewController to the appropriate class
    UIViewController *listCV = (UIViewController *)[secondStoryBoard instantiateViewControllerWithIdentifier:@"CwMain"];
    
    // Then push the new view controller in the usual way:
    [self.parentViewController presentViewController:listCV animated:YES completion:nil];
    
}

@end
