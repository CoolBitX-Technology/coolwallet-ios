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
#import "ViewController.h"
#import "KeychainItemWrapper.h"

@interface CwRegisterHostViewController () <CwManagerDelegate, CwCardDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *txtIdentifier;
@property (weak, nonatomic) IBOutlet UITextField *txtDescription;
@property (weak, nonatomic) IBOutlet UITextField *txtOtp;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;

- (IBAction)regHost:(id)sender;
- (IBAction)regHostConfirm:(id)sender;
@end

CwManager *cwManager;
CwCard *cwCard;

@implementation CwRegisterHostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //find CW via BLE
    cwManager = [CwManager sharedManager];
    cwCard = cwManager.connectedCwCard;
    
    // Do any additional setup after loading the view.
    self.txtIdentifier.delegate = self;
    self.txtDescription.delegate = self;
    self.txtOtp.delegate = self;
    
    //display iphone infos
    //self.txtIdentifier.text = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    self.txtIdentifier.text = cwManager.connectedCwCard.devCredential;
    self.txtDescription.text = [[UIDevice currentDevice] name];
    
    self.actBusyIndicator.hidden = NO;
    
    //[self regHost:self];
    
    NSLog(@"txtIdentifier = %@",self.txtIdentifier.text);
    NSLog(@"mode = %d",cwManager.connectedCwCard.mode);
}

- (void)viewWillAppear:(BOOL)animated {    
    [super viewWillAppear:animated];
    cwManager.delegate = self;
    cwCard.delegate = self;
    
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
    
    if ([listCV isKindOfClass:[CwListTableViewController class]]) {
        if (cwCard.mode == CwCardModeNormal || cwCard.mode == CwCardModePerso || cwCard.mode == CwCardModeAuth)
            [cwCard logoutHost];
        else
            [self didLogoutHost];
        
    } else if ([listCV isKindOfClass:[CwRegisterHostViewController class]]) {
        
    }

}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesBegan cwCard.mode = %ld", cwCard.mode);
    [self.txtOtp resignFirstResponder];
}

/*
//Alerts
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    //將按鈕的Title當作判斷的依據
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if(alertView == alert_callphone) {
        if([title isEqualToString:@"確定"]) {
            NSLog(@"call phone");
            //[[UIApplication sharedApplication]openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",phonenumber]]];
        }
    }
    
}*/


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
    [cwManager.connectedCwCard registerHost: self.txtIdentifier.text Description: self.txtDescription.text];
}

- (IBAction)regHostConfirm:(id)sender {
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    [cwManager.connectedCwCard confirmHost:self.txtOtp.text];
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
    NSLog(@"didGetModeState mode = %d", cwCard.mode);
    
    NSString *modeStr = [[NSString alloc] init];
    
    switch (cwCard.mode) {
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

    
    //update Views
    //self.lblMode.text = [NSString stringWithFormat: @"%@ (%ld)", modeStr, (long)cwCard.mode];
    //self.lblState.text = [@(cwCard.state) stringValue];
    NSLog(@"mode = %@", modeStr);
    //action according to the mode
    if (cwCard.mode == CwCardModePerso || cwCard.mode == CwCardModeNormal) {
        //already loggin, goto Accounts story board
        [self didLoginHost];
        [self showIndicatorView:@"Login Host"];
    } else {
        //self.lblFwVersion.text = @"";
        //self.lblUid.text = @"";
        [cwCard getCwInfo];
        [cwCard getCwCardId];
    }
}

-(void) didGetCwInfo
{
    self.actBusyIndicator.hidden = YES;
    NSString *msg = @"";
    //display the Contents of the card
    //self.lblFwVersion.text = cwCard.fwVersion;
    //self.lblUid.text = cwCard.uid;
    
    //update UI according to the mode
    if (cwCard.mode == CwCardModeNoHost) {
        //new Card
        [self regHost:self];
        
    } else if (cwCard.mode == CwCardModeDisconn || cwCard.mode == CwCardModePerso) {
        //used Card
        if (cwCard.hostId>=0) {
            NSLog(@"cwCard.hostConfirmStatus = %d",cwCard.hostConfirmStatus);
            if (cwCard.hostConfirmStatus == CwHostConfirmStatusConfirmed) {
                //login
                [cwCard loginHost];
                [self showIndicatorView:@"Login Host"];
            } else {
                //need confirm
                msg = @"Waiting for authorization from paired device.";
                //self.lblCWstatus.text = @"CW Found, Need Authed Device to Confirm the Registration";
                
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle: nil
                                                               message: msg
                                                              delegate: nil
                                                     cancelButtonTitle: nil
                                                     otherButtonTitles:@"OK",nil];
                
                [alert show];
                
                _btnRefreshInfo.hidden = NO;
            }
            
        } else {
            NSLog(@"hostId < 0");
            //register host, need confirm.
            [self regHost:self];
        }
    }
    
    //[self reloadInputViews];
}

-(void) didGetCwCardId
{
    NSLog(@"didGetCwCardId");
    [cwCard loadCwCardFromFile];
}


-(void) didLoginHost
{
    [self performDismiss];
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
    
    [cwManager disconnectCwCard];
    
    //clear properties
    cwCard = nil;
    
    NSLog(@"CW Released");
    
    //[self.cwMgr scanCwCards];
}

-(void) didCwCardCommandError:(NSInteger)cmdId ErrString:(NSString *)errString
{
    NSLog(@"%ld", (long)cmdId );
    [self performDismiss];
    NSString *msg;
    //if(cmdId == 215) msg = @"locorrect sum, please check again";
    
    msg = [NSString stringWithFormat:@"Cmd %02lX %@", (long)cmdId, errString];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Command Error"
                                                   message: msg
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    
    [alert show];
}

-(void) didRegisterHost: (NSString *)OTP {
    NSLog(@"didRegisterHost");
    self.actBusyIndicator.hidden = YES;
    [self.actBusyIndicator stopAnimating];
    
    //cwManager.connectedCwCard.hostOtp = OTP;
    //self.txtOtp.text = OTP;
}

-(void) didConfirmHost {
    NSLog(@"didConfirmHost");
    self.actBusyIndicator.hidden = YES;
    [self.actBusyIndicator stopAnimating];
    
    //[cwCard getCwInfo];
    
    //back to previous controller
    //[self.navigationController popViewControllerAnimated:YES];
    if (cwCard.mode == CwCardModeDisconn || cwCard.mode == CwCardModePerso) {
        //used Card
        if (cwCard.hostId>=0) {
            if (cwCard.hostConfirmStatus!=CwHostConfirmStatusConfirmed) {
                NSString *msg = @"Waiting for authorization from paired device.";
                //self.lblCWstatus.text = @"CW Found, Need Authed Device to Confirm the Registration";
                
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle: nil
                                                               message: msg
                                                              delegate: nil
                                                     cancelButtonTitle: nil
                                                     otherButtonTitles:@"OK",nil];
                
                [alert show];
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

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    NSLog(@"didDisconnectCwCard");
    [self performDismiss];

    //Add a notification to the system
    UILocalNotification *notify = [[UILocalNotification alloc] init];
    notify.alertBody = [NSString stringWithFormat:@"%@ Disconnected", cardName];
    notify.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow: notify];

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

- (void) showIndicatorView:(NSString *)Msg {
    mHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:mHUD];
    
    //如果设置此属性则当前的view置于后台
    mHUD.dimBackground = YES;
    mHUD.labelText = Msg;
    
    [mHUD show:YES];
}

- (void) performDismiss
{
    if(mHUD != nil) {
        [mHUD removeFromSuperview];
        mHUD = nil;
    }
    //[IndicatorAlert dismissWithClickedButtonIndex:0 animated:NO];
}

@end
