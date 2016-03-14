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
#import "CwCommandDefine.h"
#import "CwCardApduError.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface CwEraseCwViewController () <CwManagerDelegate, CwCardDelegate, UITextFieldDelegate>
{
    CGFloat _currentMovedUpHeight;
}

@property CwManager *cwManager;

@property (weak, nonatomic) IBOutlet UILabel *resetHintLabel;
@property (weak, nonatomic) IBOutlet UIView *otpConfirmView;
@property (weak, nonatomic) IBOutlet UITextField *otpField;
@property (weak, nonatomic) IBOutlet UIButton *resetBtn;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;
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
    
    self.actBusyIndicator.hidden = YES;
    
    self.resetHintLabel.hidden = NO;
    self.otpConfirmView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.cwManager.delegate = self;
    self.cwManager.connectedCwCard.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
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

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.otpConfirmView.isHidden) {
        [self.otpField resignFirstResponder];
    }
}

- (void) startLoading
{
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
}

- (void) stopLoading
{
    [self.actBusyIndicator stopAnimating];
    self.actBusyIndicator.hidden = YES;
}

-(void) keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat deltaHeight = kbSize.height - (self.view.frame.size.height - self.otpConfirmView.frame.origin.y - self.otpConfirmView.frame.size.height);
    
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


#pragma marks - UITextFieldDelegate Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma marks - Actions

- (IBAction)btnEraseCw:(id)sender {
    [self startLoading];
    
    if (self.otpConfirmView.isHidden) {
        [cwCard getModeState];
    } else {
        [self.cwManager.connectedCwCard verifyResetOtp:self.otpField.text];
    }
}

#pragma marks - CwCard Delegates

-(void) didPrepareService
{
    NSLog(@"didPrepareService");
    //[cwCard getModeState];
}

-(void) didCwCardCommandError:(NSInteger)cmdId ErrString:(NSString *)errString
{
//    NSString *msg = [NSString stringWithFormat:@"Cmd %02lX %@", (long)cmdId, errString];
//    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Command Error"
//                                                   message: msg
//                                                  delegate: nil
//                                         cancelButtonTitle: nil
//                                         otherButtonTitles:@"OK",nil];
//    
//    [alert show];
}

-(void) didGetModeState
{
    NSLog(@"didGetModeState mode = %@", cwCard.mode);
    if (cwCard.mode.integerValue == CwCardModeNoHost) {
        [self didEraseCw];
    } else {
        [self.cwManager.connectedCwCard getCwCardId];
    }
}

-(void) didGetCwCardId
{
    [self.cwManager.connectedCwCard genResetOtp];
}

-(void) didGenOTPWithError:(NSInteger)errId
{
    if (errId == -1) {
        [self stopLoading];
        
        self.resetHintLabel.hidden = YES;
        self.otpConfirmView.hidden = NO;
        [self.resetBtn setTitle:@"Confirm" forState:UIControlStateNormal];
    } else {
        if (errId == ERR_CMD_NOT_SUPPORT) {
            // old firmware, allow reset directly
            [self.cwManager.connectedCwCard pinChlng];
        } else {
            // TODO: show msg?
            [self stopLoading];
        }
    }
}

-(void) didVerifyOtp
{
    [self.cwManager.connectedCwCard pinChlng];
}

-(void) didVerifyOtpError:(NSInteger)errId
{
    if (errId == ERR_TRX_VERIFY_OTP) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"OTP Error" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.otpField.text = @"";
        }];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

-(void) didPinChlng
{
    NSLog(@"didPinChlng");
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
