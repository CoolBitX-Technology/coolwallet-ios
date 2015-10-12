//
//  CwEraseCwViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/16.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "CwEraseCwViewController.h"
#import "CwInfoViewController.h"
#import "CwManager.h"
#import "CwListTableViewController.h"

@interface CwEraseCwViewController () <CwManagerDelegate, CwCardDelegate, UITextFieldDelegate>
@property CwManager *cwManager;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;
@property (weak, nonatomic) IBOutlet UITextField *txtPin;
@property (weak, nonatomic) IBOutlet UITextField *txtNewPin;
- (IBAction)btnEraseCw:(id)sender;
@end

CwCard *cwCard;

@implementation CwEraseCwViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //find CW via BLE
    self.cwManager = [CwManager sharedManager];
    
    cwCard = self.cwManager.connectedCwCard;
    
    self.txtPin.delegate = self;
    self.txtNewPin.delegate = self;

    self.actBusyIndicator.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.cwManager.delegate = self;
    self.cwManager.connectedCwCard.delegate = self;
    
    [cwCard getModeState];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Close the cwCard connection and goback to ListTable
- (void)viewWillDisappear:(BOOL)animated
{
    long currentVCIndex = [self.navigationController.viewControllers indexOfObject:self.navigationController.topViewController];
    NSObject *listCV = [self.navigationController.viewControllers objectAtIndex:currentVCIndex];
    
    if ([listCV isKindOfClass:[CwInfoViewController class]]) {
        [((CwInfoViewController *)listCV) viewDidLoad];
    }
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

- (IBAction)btnEraseCw:(id)sender {
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    [self.cwManager.connectedCwCard pinChlng];
}

#pragma marks - CwCard Delegates

-(void) didPrepareService
{
    NSLog(@"didPrepareService");
    //[cwCard getModeState];
}

-(void) didCwCardCommand
{
    [self.actBusyIndicator stopAnimating];
    self.actBusyIndicator.hidden = YES;
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

-(void) didGetModeState
{
    NSLog(@"didGetModeState mode = %d", cwCard.mode);
}

-(void) didPinChlng
{
    
    [self.cwManager.connectedCwCard eraseCw:NO Pin:@"12345678" NewPin:@"12345678"];
    //[self.cwManager.connectedCwCard eraseCw:NO Pin:self.txtPin.text NewPin:self.txtNewPin.text];
}

-(void) didEraseCw {
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"CoolWallet has reset"
                                                   message: nil
                                                  delegate: self
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    
    //[alert setTag:1];
    [alert show];
    
    NSLog(@"CoolWallet Erased");
    
    //back to previous controller
    [self.navigationController popViewControllerAnimated:YES];
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
    
    //[self.navigationController popViewControllerAnimated:YES];

     // Get the storyboard named secondStoryBoard from the main bundle:
     UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
     // Load the view controller with the identifier string myTabBar
     // Change UIViewController to the appropriate class
     UIViewController *listCV = (UIViewController *)[secondStoryBoard instantiateViewControllerWithIdentifier:@"CwMain"];
     // Then push the new view controller in the usual way:
     [self.parentViewController presentViewController:listCV animated:YES completion:nil];
    
}

- (IBAction)BtnCancelAction:(id)sender {
    [self.cwManager disconnectCwCard];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
