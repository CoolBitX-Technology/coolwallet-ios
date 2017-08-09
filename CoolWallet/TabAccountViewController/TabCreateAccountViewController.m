//
//  TabCreateAccountViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/24.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "TabCreateAccountViewController.h"
#import "CwManager.h"
#import "CwCard.h"

@interface TabCreateAccountViewController () <CwManagerDelegate, CwCardDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *lblAccId;
@property (weak, nonatomic) IBOutlet UITextField *txtAccName;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;

- (IBAction)btnCreateAccount:(id)sender;

@end

#pragma makrs - Internal properties

CwCard *cwCard;

@implementation TabCreateAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.actBusyIndicator.hidden = YES;

    //find CW via BLE
    CwManager *cwManager = [CwManager sharedManager];
    cwCard = cwManager.connectedCwCard;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.txtAccName.delegate = self;
    cwCard.delegate = self;
    
    self.lblAccId.text = [NSString stringWithFormat: @"%ld", (long)cwCard.hdwAcccountPointer+1];
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

#pragma marks - UITextFieldDelegate Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma marks - Actions
- (IBAction)btnCreateAccount:(id)sender {
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    [cwCard newAccount:(long)cwCard.hdwAcccountPointer Name:self.txtAccName.text];
}

#pragma marks - CwCard Delegate
-(void) didCwCardCommand
{
    [cwCard saveCwCardToFile];
    
    [self.actBusyIndicator stopAnimating];
    self.actBusyIndicator.hidden = YES;
}

-(void) didNewAccount
{

    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Account Created"
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
    
    //back to previous controller
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
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
