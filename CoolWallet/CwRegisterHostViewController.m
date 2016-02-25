//
//  CwRegisterHostViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/15.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "CwRegisterHostViewController.h"
#import "CwListTableViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "CwHost.h"
#import "CwCardApduError.h"
#import "CwCommandDefine.h"
#import "ViewController.h"
#import "KeychainItemWrapper.h"

@interface CwRegisterHostViewController () <UITextFieldDelegate>
{
    CGFloat _currentMovedUpHeight;
}

@property (weak, nonatomic) IBOutlet UITextField *txtIdentifier;
@property (weak, nonatomic) IBOutlet UITextField *txtDescription;
@property (weak, nonatomic) IBOutlet UITextField *txtOtp;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;

- (IBAction)regHost:(id)sender;
- (IBAction)regHostConfirm:(id)sender;

@end

CwCard *cwCard;

@implementation CwRegisterHostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _currentMovedUpHeight = 0.0f;
    
    //find CW via BLE
    cwCard = self.cwManager.connectedCwCard;
    
    // Do any additional setup after loading the view.
    self.txtIdentifier.delegate = self;
    self.txtDescription.delegate = self;
    self.txtOtp.delegate = self;
    
    //display iphone infos
    //self.txtIdentifier.text = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    self.txtIdentifier.text = self.cwManager.connectedCwCard.devCredential;
    self.txtDescription.text = [[UIDevice currentDevice] name];
    
    self.actBusyIndicator.hidden = NO;
    
    self.viewOTPConfirm.hidden = YES;
    
    NSLog(@"mode = %@",self.cwManager.connectedCwCard.mode);
}

- (void)viewWillAppear:(BOOL)animated {    
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [cwCard getModeState];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Close the cwCard connection and goback to ListTable
- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    long currentVCIndex = [self.navigationController.viewControllers indexOfObject:self.navigationController.topViewController];
    NSObject *listCV = [self.navigationController.viewControllers objectAtIndex:currentVCIndex];
    
    if ([listCV isKindOfClass:[CwListTableViewController class]]) {
        if ([cwCard.mode integerValue] == CwCardModeNormal || [cwCard.mode integerValue] == CwCardModePerso || [cwCard.mode integerValue] == CwCardModeAuth)
            [cwCard logoutHost];
        else
            [self didLogoutHost];
        
    } else if ([listCV isKindOfClass:[CwRegisterHostViewController class]]) {
        
    }

}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesBegan cwCard.mode = %@", cwCard.mode);
    [self.txtOtp resignFirstResponder];
}

-(void) keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat deltaHeight = kbSize.height - (self.view.frame.size.height - self.viewOTPConfirm.frame.origin.y - self.viewOTPConfirm.frame.size.height);
    
    if (deltaHeight <= 0) {
        _currentMovedUpHeight = 0.0f;
        return;
    }
    
    _currentMovedUpHeight = deltaHeight;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    self.view.frame = CGRectMake(self.view.frame.origin.x,
                                           self.view.frame.origin.y - _currentMovedUpHeight,
                                           self.view.frame.size.width,
                                           self.view.frame.size.height);

    [UIView commitAnimations];
}


-(void) keyboardWillHide:(NSNotification *)notification
{
    if (_currentMovedUpHeight <= 0) {
        return;
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    self.view.frame = CGRectMake(self.view.frame.origin.x,
                                           self.view.frame.origin.y + _currentMovedUpHeight,
                                           self.view.frame.size.width,
                                           self.view.frame.size.height);
    
    [UIView commitAnimations];
    
    _currentMovedUpHeight = 0.0f;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSLog(@"prepareForSegue");
}


- (IBAction)regHost:(id)sender {
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    _viewOTPConfirm.hidden = NO;
    _btnRegisterHost.hidden = NO;
    NSLog(@"cwManager = %@",self.txtDescription.text);
    [self.cwManager.connectedCwCard registerHost: self.txtIdentifier.text Description: self.txtDescription.text];
}

- (IBAction)regHostConfirm:(id)sender {
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    [self.cwManager.connectedCwCard confirmHost:self.txtOtp.text];
}

#pragma mark - UITextFieldDelegate Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - CwCard Delegates
/*
-(void) didPrepareService
{
    NSLog(@"didPrepareService");
    //self.lblMode.text = @"";
    //self.lblState.text = @"";
    [cwCard getModeState];
}
*/

-(void) didGetModeState
{
    NSLog(@"didGetModeState mode = %@", cwCard.mode);
    
    NSString *modeStr = [[NSString alloc] init];
    
    switch ([cwCard.mode integerValue]) {
        case CwCardModeAuth:
            modeStr = @"Auth";
            break;
        case CwCardModeDisconn:
            modeStr = @"Disconn";
            break;
        case CwCardModeInit:
            modeStr = @"Init";
            break;
        case CwCardModeNoHost:
            modeStr = @"NoHost";
            break;
        case CwCardModeNormal:
            modeStr = @"Normal";
            break;
        case CwCardModePerso:
            modeStr = @"Perso";
            break;
    }

    NSLog(@"mode = %@", modeStr);
    //action according to the mode
    switch (cwCard.mode.integerValue) {
        case CwCardModeNormal:
            [self didPersoSecurityPolicy];
            break;
            
        case CwCardModePerso:
            [cwCard persoSecurityPolicy:NO ButtonEnable:YES DisplayAddressEnable:NO WatchDogEnable:NO];
            break;
            
        default:
            [cwCard getCwInfo];
            break;
    }
}

-(void) didGetCwInfo
{
    self.actBusyIndicator.hidden = YES;
    NSString *msg = @"";
    //display the Contents of the card
    //self.lblFwVersion.text = cwCard.fwVersion;
    //self.lblUid.text = cwCard.uid;
    
    NSInteger cardMode = [cwCard.mode integerValue];
    
    //update UI according to the mode
    if (cardMode == CwCardModeNoHost) {
        //new Card
        [self regHost:self];
        
    } else if (cardMode == CwCardModeDisconn || cardMode == CwCardModePerso) {
        //used Card
        if ([cwCard.hostId integerValue] >= 0) {
            NSLog(@"cwCard.hostConfirmStatus = %@",cwCard.hostConfirmStatus);
            if ([cwCard.hostConfirmStatus integerValue] == CwHostConfirmStatusConfirmed) {
                //login
                [cwCard loginHost];
                [self showIndicatorView:@"Login Host"];
            } else {
                //need confirm
                msg = @"Waiting for authorization from paired device";
                [self showHintAlert:nil withMessage:msg withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self didLogoutHost];
                }]];
                
                _btnRefreshInfo.hidden = NO;
            }
            
        } else {
            NSLog(@"hostId < 0");
            //register host, need confirm.
            [self regHost:self];
        }
    }
}

-(void) didGetCwCardId
{
    NSLog(@"didGetCwCardId");
}


-(void) didLoginHost
{
    [cwCard getModeState];
}

-(void) didPersoSecurityPolicy
{
    [self performDismiss];
    
    [cwCard displayCurrency:cwCard.cardFiatDisplay.boolValue];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
    ViewController *myVC = (ViewController *)[storyboard instantiateViewControllerWithIdentifier:@"RevealViewController"];
    [self.navigationController presentViewController:myVC animated:YES completion:nil];
}

-(void) didLogoutHost
{
    /*
     long currentVCIndex = [self.navigationController.viewControllers indexOfObject:self.navigationController.topViewController];
     NSObject *listCV = [self.navigationController.viewControllers objectAtIndex:currentVCIndex];
     
     cwManager.delegate = (CwListTableViewController *)listCV;
     */
    
    [self.cwManager disconnectCwCard];
    
    //clear properties
    cwCard = nil;
    
    NSLog(@"CW Released");
    
    //[self.cwMgr scanCwCards];
}

-(void) didCwCardCommandError:(NSInteger)cmdId ErrString:(NSString *)errString
{
    [super didCwCardCommandError:cmdId ErrString:errString];
    
    switch (cmdId) {
        case CwCmdIdGetModeState:
            
            break;
        
        case CwCmdIdBindRegFinish:
            break;
            
        default:
            if (![errString hasPrefix:@"Command Error"]) {
                UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:nil message:errString preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [errorAlertController addAction:okAction];
                
                [self presentViewController:errorAlertController animated:YES completion:nil];
            }
            
            break;
    }
    
}

-(void) didRegisterHost: (NSString *)OTP {
    NSLog(@"didRegisterHost");
    self.actBusyIndicator.hidden = YES;
    [self.actBusyIndicator stopAnimating];
    
    //cwManager.connectedCwCard.hostOtp = OTP;
    //self.txtOtp.text = OTP;
}

-(void) didRegisterHostError:(NSInteger)errorId
{
    NSString *title = @"Unable to Pair";
    NSString *message = nil;
    if (errorId == ERR_BIND_HOSTFULL) {
        message = @"Maximum number of 3 hosts have been paired with this card";
    }
    
    [self showHintAlert:title withMessage:message withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self didLogoutHost];
    }]];
}

-(void) didConfirmHost {
    NSLog(@"didConfirmHost");
    self.actBusyIndicator.hidden = YES;
    [self.actBusyIndicator stopAnimating];
    
    //[cwCard getCwInfo];
    
    //back to previous controller
    //[self.navigationController popViewControllerAnimated:YES];
    if ([cwCard.mode integerValue] == CwCardModeDisconn || [cwCard.mode integerValue] == CwCardModePerso) {
        //used Card
        if ([cwCard.hostId integerValue] >= 0) {
            if ([cwCard.hostConfirmStatus integerValue] != CwHostConfirmStatusConfirmed) {
                NSString *msg = @"Waiting for authorization from paired device.";
                [self showHintAlert:nil withMessage:msg withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self didLogoutHost];
                }]];
            }
            
        }
    }else {
        /*
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"CW Registered"
                                                       message: nil
                                                      delegate: nil
                                             cancelButtonTitle: nil
                                             otherButtonTitles:@"OK",nil];
        [alert show];
        */
        [self performSegueWithIdentifier:@"CwPairSuccesfulSegue" sender:self];
    }
}

-(void) didConfirmHostError:(NSInteger)errId
{
    self.actBusyIndicator.hidden = YES;
    [self.actBusyIndicator stopAnimating];
    
    if (errId == ERR_BIND_REGRESP) {
        self.txtOtp.text = @"";
        
        UIAlertAction *tryAction = [UIAlertAction actionWithTitle:@"try again" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self regHost:self];
        }];
        [self showHintAlert:@"Unable to Pair" withMessage:@"OTP incorrect" withOKAction:tryAction];
    }
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    NSLog(@"didDisconnectCwCard");
    [self performDismiss];

    //Add a notification to the system
//    UILocalNotification *notify = [[UILocalNotification alloc] init];
//    notify.alertBody = [NSString stringWithFormat:@"%@ Disconnected", cardName];
//    notify.soundName = UILocalNotificationDefaultSoundName;
//    [[UIApplication sharedApplication] presentLocalNotificationNow: notify];

    // Get the storyboard named secondStoryBoard from the main bundle:
    UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    // Load the view controller with the identifier string myTabBar
    // Change UIViewController to the appropriate class
    UIViewController *listCV = (UIViewController *)[secondStoryBoard instantiateViewControllerWithIdentifier:@"CwMain"];
    // Then push the new view controller in the usual way:
    [self.parentViewController presentViewController:listCV animated:YES completion:nil];
     
}

- (IBAction)BtnCancelAction:(id)sender {
    //[self regHost:self];
    [cwCard logoutHost];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)btnRefreshInfo:(id)sender {
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    [cwCard getModeState];
    //    [cwCard getCwCardId];
}

@end
