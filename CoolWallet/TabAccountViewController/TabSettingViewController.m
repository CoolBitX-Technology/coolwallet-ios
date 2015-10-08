//
//  TabSettingViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/17.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "TabSettingViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "SWRevealViewController.h"

@interface TabSettingViewController ()  <CwManagerDelegate, CwCardDelegate>
@property CwManager *cwManager;
@property (weak, nonatomic) IBOutlet UISwitch *swOtpEnable;
@property (weak, nonatomic) IBOutlet UISwitch *swBtnEnable;
@property (weak, nonatomic) IBOutlet UISwitch *swWatchDogEnable;
@property (weak, nonatomic) IBOutlet UISwitch *swDisplayAddress;

@property (weak, nonatomic) IBOutlet UISwitch *swPreserveHostInfo;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;

- (IBAction)btnUpdateSecurityPolicy:(id)sender;
- (IBAction)btnEraseCw:(id)sender;

@end

@implementation TabSettingViewController
{
    NSArray *menuItems;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //menuItems = @[@"BitcoinUnits", @"ResetCoolWallet"];
    menuItems = @[@"ResetCoolWallet", @"BitcoinUnits"];
    
    //find CW via BLE
    self.cwManager = [CwManager sharedManager];
    //self.cwManager.delegate=self;

    self.actBusyIndicator.hidden = YES;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //add CW Logo
    UIImage* myImage = [UIImage imageNamed:@"settings.png"];
    UIImageView* myImageView = [[UIImageView alloc] initWithImage:myImage];
    
    myImageView.frame = CGRectMake(75, 5, 30, 30);
    myImageView.tag = 9;
    [self.navigationController.navigationBar addSubview:myImageView];
    
    self.cwManager.delegate=self;
    self.cwManager.connectedCwCard.delegate = self;

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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Configure the cell...
    NSString *CellIdentifier = [menuItems objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if(indexPath.row == 0) {
        
        //[self.navigationController.navigationBar.subviews removeFromSuperview];
        //myImageView.hidden = YES;
    }
    
    return cell;
}

#pragma mark - TableView Delegates

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSLog(@"row select = %d",indexPath.row);
    //if(indexPath.row == 0) [self performSegueWithIdentifier:@"SettingBitcoinUnit" sender:self];
}

#pragma mark - Actions
- (IBAction)btnUpdateSecurityPolicy:(id)sender {
    
    NSLog(@"mode = %d", self.cwManager.connectedCwCard.mode);
    if (self.cwManager.connectedCwCard.mode==CwCardModeNormal) {
        //get security policy
        self.actBusyIndicator.hidden = NO;
        [self.actBusyIndicator startAnimating];
        [self.cwManager.connectedCwCard setSecurityPolicy:self.swOtpEnable.on
                                             ButtonEnable:self.swBtnEnable.on
                                     DisplayAddressEnable:self.swDisplayAddress.on
                                           WatchDogEnable:self.swWatchDogEnable.on];
    } else if (self.cwManager.connectedCwCard.mode == CwCardModePerso) {
        NSLog(@"otp = %d", self.swOtpEnable.on);
        //get security policy
        self.actBusyIndicator.hidden = NO;
        [self.actBusyIndicator startAnimating];
        [self.cwManager.connectedCwCard persoSecurityPolicy:self.swOtpEnable.on
                                             ButtonEnable:self.swBtnEnable.on
                                     DisplayAddressEnable:self.swDisplayAddress.on
                                           WatchDogEnable:self.swWatchDogEnable.on];
    }
}

- (IBAction)btnEraseCw:(id)sender {
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    [self.cwManager.connectedCwCard eraseCw:self.swPreserveHostInfo.on Pin:@"" NewPin:@""];
}

#pragma mark - CwCardDelegate

-(void) didCwCardCommand
{
    [self.actBusyIndicator stopAnimating];
    self.actBusyIndicator.hidden = YES;
}

-(void) didGetModeState
{
    NSLog(@"mode = %d", self.cwManager.connectedCwCard.mode);

}

-(void) didCwCardCommandError:(NSInteger)cmdId ErrString:(NSString *)errString
{
    NSString *msg = [NSString stringWithFormat:@"Cmd %02lX %@", (long)cmdId, errString];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Command Error"
                                                   message: msg
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    
    [alert show];
}

-(void) didPersoSecurityPolicy
{
    NSLog(@"didPersoSecurityPolicy");
    /*
    [self.cwManager.connectedCwCard getModeState];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"CW Security Policy Set"
                                                   message: nil
                                                  delegate: self
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
     */
    //[self.cwManager.connectedCwCard getModeState];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
    UIViewController * vc = [sb instantiateViewControllerWithIdentifier:@"CwAccount"];
    [self.revealViewController pushFrontViewController:vc animated:YES];

}

-(void) didGetSecurityPolicy
{
    self.swOtpEnable.on = self.cwManager.connectedCwCard.securityPolicy_OtpEnable;
    self.swBtnEnable.on = self.cwManager.connectedCwCard.securityPolicy_BtnEnable;
    self.swWatchDogEnable.on = self.cwManager.connectedCwCard.securityPolicy_WatchDogEnable;
    self.swDisplayAddress.on = self.cwManager.connectedCwCard.securityPolicy_DisplayAddressEnable;
}

-(void) didSetSecurityPolicy
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"CW Security Policy Set"
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
    
    //[self.cwManager.connectedCwCard getModeState];
}

-(void) didEraseWallet {
    
    //if erase CW, then wait for didEraseCw delegate, don't show the alert here
    if (self.swPreserveHostInfo.on)
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"CoolWallet has reset"
                                                   message: @"Host info preserved"
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    
        [alert show];
    }
    
    NSLog(@"CW Erased (Host Preserved)");
    
    [self.cwManager disconnectCwCard];
    
    NSLog(@"CW Released");
}

-(void) didEraseCw {
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"CoolWallet has reset"
                                                   message: @"Host info also erased"
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    
    [alert show];
    
    NSLog(@"Cw Erased");
    
    [self.cwManager disconnectCwCard];
    
    NSLog(@"CW Released");
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    NSLog(@"didDisconnectCwCard");
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
