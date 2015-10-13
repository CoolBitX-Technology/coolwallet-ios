//
//  UIViewController+TabbarSendViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/3/19.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabbarSendViewController.h"
#import "OCAppCommon.h"

CwManager *cwManager;
CwCard *cwCard;
CwAccount *account;
CwBtcNetWork *btcNet;

UIAlertView *OTPalert;
UITextField *tfOTP;
UIAlertView *PressAlert;

NSDictionary *rates;

long TxFee = 10000;

@interface TabbarSendViewController ()

@property (strong, nonatomic) CwAddress *genAddr;

@end

@implementation TabbarSendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //find CW via BLE
    CwManager *cwManager = [CwManager sharedManager];
    cwCard = cwManager.connectedCwCard;
    //NSLog(@"currentAccountId = %ld",cwCard.currentAccountId);
    //btcNet = [CwBtcNetWork sharedManager];
    
    cwCard.paymentAddress = @"";
    //cwCard.amount = 0;
    cwCard.label = @"";
    
    [self addDecimalKeyboardDoneButton];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"will appear");
    self.actBusyIndicator.hidden=YES;
    self.navigationController.navigationBar.hidden = NO;
    //self.txtAddress.delegate = self;
    cwCard.delegate = self;
    
    //[cwCard getCwHdwInfo];
    
    [self setAccountButton];
    
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", cwCard.currentAccountId]];
    
    self.txtReceiverAddress.delegate = self;
    self.txtAmount.delegate = self;
    self.txtNote.delegate = self;
    self.txtOtp.delegate = self;
    self.txtAmountFiatmoney.delegate =self;
    
    //NSLog(@"account.accId = %d",account.accId);
    [cwCard getAccountAddresses: account.accId];
    
    //NSLog(@"payment address = %@", cwCard.paymentAddress);
    self.txtReceiverAddress.text = cwCard.paymentAddress;
    self.txtAmount.text = @"";
    self.txtNote.text = cwCard.label;
    _txtAmountFiatmoney.text = @"";
    _lblFiatCurrency.text = cwCard.currId;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event

{
    [super touchesBegan:touches withEvent:event];
    
}

- (IBAction)btnGenOtp:(id)sender {
    //get Wait OTP
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    self.txtOtp.text = @"";
    
    //self.lblOtp.hidden = YES;
    //self.txtOtp.hidden = YES;
    
    //find an internal address with empty transactions, if no, creat a new internal address
    [cwCard genAddress:cwCard.currentAccountId KeyChainId:CwAddressKeyChainInternal];
    
    /*
    NSMutableArray *transactions = [[NSMutableArray alloc] init];
    
    [transactions addObject:self.txtReceiverAddress.text];
    [cwCard prepareTransaction: transactions Amount: [self.txtAmount.text longLongValue] Address:self.txtReceiverAddress.text];
     */
}

- (IBAction)btnVerifyOtp:(id)sender {
    
    //verify OTP
    //self.btnVerifyOtp.hidden = YES;
    [cwCard verifyTransactionOtp: self.txtOtp.text];
    
}


- (IBAction)btnSendBitcoin:(id)sender {
    
    if([self.txtReceiverAddress.text compare:@""] == 0 ) return;
    if([self.txtAmount.text compare:@""] == 0 ) return;
    
    //send OTP
    [self showIndicatorView:@"Send..."];
    
    [cwCard genAddress:cwCard.currentAccountId KeyChainId:CwAddressKeyChainInternal];
}

- (IBAction)btnScanQRcode:(id)sender {
    
    [self performSegueWithIdentifier:@"ScanQRSegue" sender:self];
}

- (void)addDecimalKeyboardDoneButton
{
    //add done button
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 35.0f)];
    toolbar.barStyle=UIBarStyleDefault;
    
    // Create a flexible space to align buttons to the right
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // Create a cancel button to dismiss the keyboard
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAmountItem:)];
    
    // Add buttons to the toolbar
    [toolbar setItems:[NSArray arrayWithObjects:flexibleSpace, barButtonItem, nil]];
    
    // Set the toolbar as accessory view of an UITextField object
    _txtAmount.inputAccessoryView = toolbar;
    
    //add done button
    UIToolbar *mtoolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 35.0f)];
    toolbar.barStyle=UIBarStyleDefault;
    
    // Create a flexible space to align buttons to the right
    UIBarButtonItem *mflexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // Create a cancel button to dismiss the keyboard
    UIBarButtonItem *mbarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAmountFiatmoney:)];
    
    // Add buttons to the toolbar
    [mtoolbar setItems:[NSArray arrayWithObjects:mflexibleSpace, mbarButtonItem, nil]];
    
    // Set the toolbar as accessory view of an UITextField object
    _txtAmountFiatmoney.inputAccessoryView = mtoolbar;
}

- (IBAction)doneAmountItem:(id)sender
{
    if([_txtAmount.text compare:@""] != 0) {
        NSString *satoshi = [[OCAppCommon getInstance] convertBTCtoSatoshi:_txtAmount.text];
        NSString *fiatmoney =  [[OCAppCommon getInstance] convertFiatMoneyString:[satoshi longLongValue] currRate:cwManager.connectedCwCard.currRate];
        
        _txtAmountFiatmoney.text = fiatmoney;
    }else{
        _txtAmountFiatmoney.text = @"";
    }
    [_txtAmount resignFirstResponder];
}

- (IBAction)doneAmountFiatmoney:(id)sender
{
    if([_txtAmountFiatmoney.text compare:@""] != 0) {
        NSString *btc = [[OCAppCommon getInstance] convertBTCFromFiatMoney:[_txtAmountFiatmoney.text doubleValue] currRate:cwManager.connectedCwCard.currRate];
        _txtAmount.text = btc;
    }else{
        _txtAmount.text = @"";
    }
    [_txtAmountFiatmoney resignFirstResponder];
}

#pragma marks - Account Button Actions

- (void)setAccountButton{
    NSLog(@"cwAccounts = %d", [cwCard.cwAccounts count]);
    for(int i =0; i< [cwCard.cwAccounts count]; i++) {
        if(i == 0) {
            _btnAccount1.hidden = NO;
        }else if(i == 1) {
            _btnAccount2.hidden = NO;
        }else if(i == 2) {
            _btnAccount3.hidden = NO;
        }else if(i == 3) {
            _btnAccount4.hidden = NO;
        }else if(i == 4) {
            _btnAccount5.hidden = NO;
            _btnAccount5.enabled = YES;
            _btnAddAccount.hidden = YES;
        }
        
    }
    
    if([cwCard.cwAccounts count] == 1) {
        [_btnAccount1 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }else{
        switch (cwCard.currentAccountId) {
            case 0:
                [_btnAccount1 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            case 1:
                [_btnAccount2 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            case 2:
                [_btnAccount3 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            case 3:
                [_btnAccount4 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            case 4:
                [_btnAccount5 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            default:
                break;
        }
    }
    
}

- (IBAction)btnAccount1:(id)sender {
    [_btnAccount1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [_btnAccount2 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount3 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount4 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount5 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    [_btnAccount1 setBackgroundColor:[UIColor colorAccountBackground]];
    
    [_btnAccount2 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount3 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount4 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount5 setBackgroundColor:[UIColor blackColor]];
    
    if(cwCard.currentAccountId != 0) {
        cwCard.currentAccountId = 0;
        [cwCard setDisplayAccount:cwCard.currentAccountId];
    }
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%d", cwCard.currentAccountId]];
    
    NSLog(@"account.accId = %d",account.accId);
    //[cwCard getAccountAddresses: account.accId];
    
    [cwCard getAccountInfo:cwCard.currentAccountId];
    [self SetBalanceText];
}

- (IBAction)btnAccount2:(id)sender {
    [_btnAccount2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [_btnAccount1 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount3 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount4 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount5 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    [_btnAccount2 setBackgroundColor:[UIColor colorAccountBackground]];
    [_btnAccount1 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount3 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount4 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount5 setBackgroundColor:[UIColor blackColor]];
    
    if(cwCard.currentAccountId != 1) {
        cwCard.currentAccountId = 1;
        [cwCard setDisplayAccount:cwCard.currentAccountId];
    }
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%d", cwCard.currentAccountId]];
    
    NSLog(@"account.accId = %d",account.accId);
    //[cwCard getAccountAddresses: account.accId];
    
    [cwCard getAccountInfo:cwCard.currentAccountId];
    [self SetBalanceText];
}

- (IBAction)btnAccount3:(id)sender {
    [_btnAccount3 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [_btnAccount2 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount1 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount4 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount5 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    [_btnAccount3 setBackgroundColor:[UIColor colorAccountBackground]];
    [_btnAccount1 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount2 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount4 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount5 setBackgroundColor:[UIColor blackColor]];
    
    if(cwCard.currentAccountId != 2) {
        cwCard.currentAccountId = 2;
        [cwCard setDisplayAccount:cwCard.currentAccountId];
    }
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%d", cwCard.currentAccountId]];
    
    NSLog(@"account.accId = %d",account.accId);
    //[cwCard getAccountAddresses: account.accId];
    
    [cwCard getAccountInfo:cwCard.currentAccountId];
    [self SetBalanceText];
}

- (IBAction)btnAccount4:(id)sender {
    [_btnAccount4 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [_btnAccount2 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount3 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount1 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount5 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    [_btnAccount4 setBackgroundColor:[UIColor colorAccountBackground]];
    [_btnAccount1 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount2 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount3 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount5 setBackgroundColor:[UIColor blackColor]];
    
    if(cwCard.currentAccountId != 3) {
        cwCard.currentAccountId = 3;
        [cwCard setDisplayAccount:cwCard.currentAccountId];
    }
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%d", cwCard.currentAccountId]];
    
    NSLog(@"account.accId = %d",account.accId);
    //[cwCard getAccountAddresses: account.accId];
    
    [cwCard getAccountInfo:cwCard.currentAccountId];
    [self SetBalanceText];
}

- (IBAction)btnAccount5:(id)sender {
    [_btnAccount5 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [_btnAccount2 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount3 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount4 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount1 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    [_btnAccount5 setBackgroundColor:[UIColor colorAccountBackground]];
    [_btnAccount1 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount2 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount3 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount4 setBackgroundColor:[UIColor blackColor]];
    
    if(cwCard.currentAccountId != 4) {
        cwCard.currentAccountId = 4;
        [cwCard setDisplayAccount:cwCard.currentAccountId];
    }
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%d", cwCard.currentAccountId]];
    
    NSLog(@"account.accId = %d",account.accId);
    //[cwCard getAccountAddresses: account.accId];
    [cwCard getAccountInfo:cwCard.currentAccountId];
    [self SetBalanceText];
}

- (void)SetBalanceText
{
    CwAccount *account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%d", cwCard.currentAccountId]];
    //_lblBalance.text = [NSString stringWithFormat: @"%lld BTC", (int64_t)account.balance];
    _lblBalance.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertBTCStringformUnit: (int64_t)account.balance], [[OCAppCommon getInstance] BitcoinUnit]];
    
    _lblFaitMoney.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertFiatMoneyString:(int64_t)account.balance currRate:cwManager.connectedCwCard.currRate], cwCard.currId];
}

-(void) sendPrepareTransaction
{
    if (self.genAddr == nil) {
        return;
    }
    
    NSString *sato = [[OCAppCommon getInstance] convertBTCtoSatoshi:self.txtAmount.text];
    [cwCard prepareTransaction: [sato longLongValue] Address:self.txtReceiverAddress.text Change: self.genAddr.address];
}

-(void) cancelTransaction
{
    [cwCard cancelTrancation];
    [cwCard setDisplayAccount: cwCard.currentAccountId];
}

#define TAG_SEND_OTP 1
#define TAG_PRESS_BUTTON 2
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"OTP entered=%@",tfOTP.text);
    if(actionSheet.tag == TAG_SEND_OTP) {
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            [self showIndicatorView:@"Cancel transaction..."];
            
            [self cancelTransaction];
        } else {
            [self showIndicatorView:@"Send..."];
            
            [cwCard verifyTransactionOtp:tfOTP.text];
        }
    }else  if(actionSheet.tag == TAG_PRESS_BUTTON) {
        [self showIndicatorView:@"Cancel transaction..."];
        
        [self cancelTransaction];
    }
}

#pragma marks - CwCard Delegates
-(void) didCwCardCommand
{
    NSLog(@"didCwCardCommand");
//    [self.actBusyIndicator stopAnimating];
//    self.actBusyIndicator.hidden = YES;
    
    [self didGetCwCurrRate];
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

-(void) didPrepareTransactionError: (NSString *) errMsg
{
    [self performDismiss];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Send Bitcoin Error"
                                                   message: errMsg
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles: @"OK",nil];
    
    [alert show];
}

-(void) didGenAddress: (CwAddress *) addr;
{
    NSLog(@"didGenAddress");
    [btcNet registerNotifyByAccount:cwCard.currentAccountId];
    
    self.genAddr = addr;
    
    [self sendPrepareTransaction];
}

//-(void) didGetAccountInfo
//{
//    NSLog(@"didGetAccountInfo");
//    //account keyIdx and keys beening updated
//    account = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat: @"%ld", (long)account.accId]];
//}

-(void) didGetAccountInfo: (NSInteger) accId
{
    NSLog(@"didGetAccountInfo = %ld", accId);
    if(accId == cwCard.currentAccountId) {
        [self SetBalanceText];
    }
}

-(void) didPrepareTransaction: (NSString *)OTP
{
    NSLog(@"didPrepareTransaction");
    if (cwCard.securityPolicy_OtpEnable) {
        [self performDismiss];
        
        self.btnSendBitcoin.hidden = NO;
        [self showOTPEnterView];
    }else{
        [self didVerifyOtp];
    }
}

-(void) didGetTapTapOtp: (NSString *)OTP
{
    if (cwCard.securityPolicy_OtpEnable) {
        
        if(OTPalert != nil){
            tfOTP.text = OTP;
        }
        //self.txtOtp.text = OTP;
        //[self btnVerifyOtp:self];
    }
}

-(void) didGetButton
{
    [cwCard signTransaction];
}

-(void) didVerifyOtp
{
    NSLog(@"didVerifyOtp");
    if (cwCard.securityPolicy_BtnEnable) {
        //[self showIndicatorView:@"Press Button On the Card"];
        //self.lblPressButton.text = @"Press Button On the Card";
        [self performDismiss];
        
        PressAlert = [[UIAlertView alloc]initWithTitle: nil
                                                       message: @"Press Button On the Card"
                                                      delegate: nil
                                             cancelButtonTitle: nil
                                             otherButtonTitles: @"Cancel",nil];
        PressAlert.tag = TAG_PRESS_BUTTON;
        
        [PressAlert show];
        
    } else {
        //self.lblPressButton.text = @"Otp Verified, Sending Bitcoin";
        [self didGetButton];
    }
}

-(void) didVerifyOtpError
{
    [self performDismiss];
    
    self.txtOtp.text = @"";
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"OTP Error" message:@"Generate OTP Again" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self sendPrepareTransaction];
    }];
    [alertController addAction:okAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self cancelTransaction];
    }];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) didSignTransaction
{
    NSLog(@"didSignTransaction");
    //[self performDismiss];
    
    if(PressAlert != nil) [PressAlert dismissWithClickedButtonIndex:-1 animated:YES] ;
    
    [self performDismiss];
    
    NSString *sato = [[OCAppCommon getInstance] convertBTCtoSatoshi:self.txtAmount.text];
    [cwCard setAccount: account.accId Balance: account.balance-([sato longLongValue] + TxFee)];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Send Bitcoin"
                                                   message: [NSString stringWithFormat:@"Send %@ BTC to %@", self.txtAmount.text, self.txtReceiverAddress.text]
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles: @"OK",nil];
    
    [alert show];
    
    [self SetBalanceText];
    
    //back to previous controller
    //[self.navigationController popViewControllerAnimated:YES];
}

-(void) didSignTransactionError:(NSString *)errMsg
{
    [self performDismiss];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Send Bitcoin Fail" message:errMsg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) didGetCwCurrRate
{
    NSLog(@"didGetCwCurrRate");
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    //NSString *numberAsString = [numberFormatter stringFromNumber: cwManager.connectedCwCard.currRate];
    //_lblFaitMoney.text = numberAsString;
    NSLog(@"string = %@",[[OCAppCommon getInstance] convertFiatMoneyString:(int64_t)account.balance currRate:cwCard.currRate]);
    self.lblFaitMoney.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertFiatMoneyString:(int64_t)account.balance currRate:cwCard.currRate], cwCard.currId];
    //self.txtExchangeRage.text = numberAsString;
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    [self dismissAllAlert];
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


- (void) showOTPEnterView
{
    if(cwCard.securityPolicy_OtpEnable == NO) return;
    OTPalert = [[UIAlertView alloc] initWithTitle:@"Please enter OTP" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    OTPalert.alertViewStyle = UIAlertViewStylePlainTextInput;
    OTPalert.tag = TAG_SEND_OTP;
    tfOTP = [OTPalert textFieldAtIndex:0];
    tfOTP.keyboardType = UIKeyboardTypeDecimalPad;
    //alertTextField.keyboardType = UIKeyboardTypeNumberPad;
    //alertTextField.placeholder = @"Enter request BTC";
    [OTPalert show];
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
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }
    //[IndicatorAlert dismissWithClickedButtonIndex:0 animated:NO];
}

- (void)dismissAllAlert
{
    for (UIWindow* w in [UIApplication sharedApplication].windows)
        for (NSObject* o in w.subviews)
            if ([o isKindOfClass:[UIAlertView class]])
                [(UIAlertView*)o dismissWithClickedButtonIndex:[(UIAlertView*)o cancelButtonIndex] animated:YES];
}

#define kOFFSET_FOR_KEYBOARD 80.0
//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= kOFFSET_FOR_KEYBOARD;
        rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;
        rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

-(void)textFieldDidBeginEditing:(UITextField *)sender
{
    NSLog(@"textFieldDidBeginEditing");
    if (sender == _txtNote || sender == _txtAmount || sender == _txtAmountFiatmoney)
    {
        //move the main view, so that the keyboard does not hide it.
        if  (self.view.frame.origin.y >= 0)
        {
            [self setViewMovedUp:YES];
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)sender
{
    NSLog(@"textFieldDidEndEditing");
    if (sender == _txtNote || sender == _txtAmount || sender == _txtAmountFiatmoney)
    {
        if  (self.view.frame.origin.y < 0)
        {
            [self setViewMovedUp:NO];
        }
    }
}


@end
