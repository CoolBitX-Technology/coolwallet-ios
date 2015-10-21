//
//  UIViewController+TabSecurityViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/7/2.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabSecurityViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "SWRevealViewController.h"

@interface TabSecurityViewController ()  <CwManagerDelegate, CwCardDelegate>
@property CwManager *cwManager;
@property (weak, nonatomic) IBOutlet UISwitch *swOtpEnable;
@property (weak, nonatomic) IBOutlet UISwitch *swBtnEnable;
@property (weak, nonatomic) IBOutlet UISwitch *swWatchDogEnable;
@property (weak, nonatomic) IBOutlet UISwitch *swDisplayAddress;

@property (weak, nonatomic) IBOutlet UISwitch *swPreserveHostInfo;

@property (weak, nonatomic) IBOutlet UISlider *sliDogScale;

- (IBAction)btnUpdateSecurityPolicy:(id)sender;
- (IBAction)btnEraseCw:(id)sender;
- (IBAction)sliDogScale:(id)sender;

@end

CwCard *cwCard;

@implementation TabSecurityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Navigate Bar UI effect
    //add CW Logo
    UIImage* myImage = [UIImage imageNamed:@"security.png"];
    UIImageView* myImageView = [[UIImageView alloc] initWithImage:myImage];
    
    myImageView.frame = CGRectMake(75, 5, 30, 30);
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
    cwCard = self.cwManager.connectedCwCard;
    cwCard.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.sliDogScale.value = [cwCard.securityPolicy_WatchDogScale integerValue];
    
    if ([cwCard.mode integerValue] == CwCardModeNormal) {
        [self showIndicatorView:@"loading..."];
        
        //get security policy
        [cwCard getSecurityPolicy];
    }else if ([self.cwManager.connectedCwCard.mode integerValue] == CwCardModePerso){
        self.baritemBack.enabled = false;
        self.swBtnEnable.on = YES;
    }
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

#pragma mark - Actions
- (IBAction)btnUpdateSecurityPolicy:(id)sender {
    
    NSLog(@"mode = %@", self.cwManager.connectedCwCard.mode);
    if ([self.cwManager.connectedCwCard.mode integerValue] == CwCardModeNormal) {
        //get security policy
        [self showIndicatorView:@"update security policy..."];
        [self.cwManager.connectedCwCard setSecurityPolicy:self.swOtpEnable.on
                                             ButtonEnable:self.swBtnEnable.on
                                     DisplayAddressEnable:self.swDisplayAddress.on
                                           WatchDogEnable:self.swWatchDogEnable.on];
    } else if ([self.cwManager.connectedCwCard.mode integerValue] == CwCardModePerso) {
        NSLog(@"otp = %d", self.swOtpEnable.on);
        //get security policy
        [self showIndicatorView:@"update security policy..."];
        [self.cwManager.connectedCwCard persoSecurityPolicy:self.swOtpEnable.on
                                               ButtonEnable:self.swBtnEnable.on
                                       DisplayAddressEnable:self.swDisplayAddress.on
                                             WatchDogEnable:self.swWatchDogEnable.on];
    }
}

- (IBAction)btnEraseCw:(id)sender {
    [self showIndicatorView:@"Start reset CoolWallet..."];
    
    [cwCard eraseCw:self.swPreserveHostInfo.on Pin:@"" NewPin:@""];
}

- (IBAction)sliDogScale:(id)sender {
    self.sliDogScale.value = lroundf (self.sliDogScale.value);
    cwCard.securityPolicy_WatchDogScale = [NSNumber numberWithInteger:self.sliDogScale.value];
}

- (IBAction)securiityChanged:(UISwitch *)sender {
    if (sender == self.swOtpEnable) {
        if (!sender.on && !self.swBtnEnable.on) {
            self.swBtnEnable.on = YES;
        }
    } else if (sender == self.swBtnEnable) {
        if (!sender.on && !self.swOtpEnable.on) {
            self.swOtpEnable.on = YES;
        }
    }
    
}

#pragma mark - CwCardDelegate

-(void) didCwCardCommand
{
    if (cwCard.cardId)
        [cwCard saveCwCardToFile];
    
    [self performDismiss];
}

-(void) didGetModeState
{
    NSLog(@"mode = %@", self.cwManager.connectedCwCard.mode);
    
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
    
    [self performDismiss];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
    UIViewController * vc = [sb instantiateViewControllerWithIdentifier:@"CwAccount"];
    [self.revealViewController pushFrontViewController:vc animated:YES];
    
}

-(void) didGetSecurityPolicy
{
    self.swOtpEnable.on = self.cwManager.connectedCwCard.securityPolicy_OtpEnable.boolValue;
    self.swBtnEnable.on = self.cwManager.connectedCwCard.securityPolicy_BtnEnable.boolValue;
    self.swWatchDogEnable.on = self.cwManager.connectedCwCard.securityPolicy_WatchDogEnable.boolValue;
    self.swDisplayAddress.on = self.cwManager.connectedCwCard.securityPolicy_DisplayAddressEnable.boolValue;
    
    [self performDismiss];
}

-(void) didSetSecurityPolicy
{
    [self performDismiss];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Security policy updated" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
        UIViewController * vc = [sb instantiateViewControllerWithIdentifier:@"CwAccount"];
        [self.revealViewController pushFrontViewController:vc animated:YES];
    }];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) didEraseWallet {
    [self performDismiss];
    
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
    [self performDismiss];
    
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
