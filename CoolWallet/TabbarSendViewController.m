//
//  UIViewController+TabbarSendViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/3/19.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabbarSendViewController.h"
#import "OCAppCommon.h"
#import "CwUnspentTxIndex.h"
#import "CwBtcNetworkDelegate.h"
#import "BlockChain.h"
#import "tx.h"

CwCard *cwCard;
CwAccount *account;

UIAlertView *OTPalert;
UITextField *tfOTP;
UIAlertController *PressAlert;

NSDictionary *rates;

long TxFee = 10000;

@interface TabbarSendViewController () <CwBtcNetworkDelegate>

@property (strong, nonatomic) CwAddress *genAddr;
@property (assign, nonatomic) BOOL transactionBegin;
@property (strong, nonatomic) CwBtcNetWork *btcNet;
@property (strong, nonatomic) NSMutableArray *updateUnspendBalance;

@property (strong, nonatomic) NSArray *accountButtons;

@end

@implementation TabbarSendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //find CW via BLE
    
    cwCard = self.cwManager.connectedCwCard;
    cwCard.paymentAddress = @"";
    cwCard.amount = 0;
    cwCard.label = @"";
    
    [self addDecimalKeyboardDoneButton];
    
    self.transactionBegin = NO;
    self.updateUnspendBalance = [NSMutableArray new];
    
    self.accountButtons = @[self.btnAccount1, self.btnAccount2, self.btnAccount3, self.btnAccount4, self.btnAccount5];
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
    
    //NSLog(@"payment address = %@", cwCard.paymentAddress);
    self.txtReceiverAddress.text = cwCard.paymentAddress;
    if (cwCard.amount > 0) {
        self.txtAmount.text = [[OCAppCommon getInstance] convertBTCStringformUnit: cwCard.amount];
        [self doneAmountItem:self.txtAmount];
    } else {
        self.txtAmount.text = @"";
        self.txtAmountFiatmoney.text = @"";
    }
    self.txtNote.text = cwCard.label;
    _lblFiatCurrency.text = cwCard.currId;
}

-(void) viewWillDisappear:(BOOL)animated
{
    if (self.transactionBegin) {
        // TODO: alert cancel?
    } else {
        cwCard.paymentAddress = @"";
        cwCard.amount = 0;
        cwCard.label = @"";
    }
    
    if (self.updateUnspendBalance.count > 0) {
        [self performDismiss];
        [self.updateUnspendBalance removeAllObjects];
    }
}

-(CwBtcNetWork *) btcNet
{
    if (_btcNet == nil) {
        _btcNet = [CwBtcNetWork sharedManager];
        _btcNet.delegate = self;
    }
    
    return _btcNet;
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

- (IBAction)btnSendBitcoin:(id)sender {
    
    if([self.txtReceiverAddress.text compare:@""] == 0 ) return;
    if (![self isValidBitcoinAddress:self.txtReceiverAddress.text]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to send" message:@"Invalid Bitcoin address" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    if([self.txtAmount.text compare:@""] == 0 ) return;
    
    self.transactionBegin = YES;
    
    if ([self.updateUnspendBalance containsObject:[NSString stringWithFormat:@"%ld", account.accId]] ) {
        [self showIndicatorView:@"Update unspent balance..."];
    } else {
        //send OTP
        [self sendBitcoin];
    }
}

- (IBAction)btnScanQRcode:(id)sender {
    
    [self performSegueWithIdentifier:@"ScanQRSegue" sender:self];
}

-(void) sendBitcoin
{
    [self showIndicatorView:@"Send..."];
    
    [cwCard genAddress:cwCard.currentAccountId KeyChainId:CwAddressKeyChainInternal];
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
        NSString *fiatmoney =  [[OCAppCommon getInstance] convertFiatMoneyString:[satoshi longLongValue] currRate:self.cwManager.connectedCwCard.currRate];
        
        self.txtAmountFiatmoney.text = fiatmoney;
    }else{
        self.txtAmountFiatmoney.text = @"";
    }
    [self.txtAmount resignFirstResponder];
}

- (IBAction)doneAmountFiatmoney:(id)sender
{
    if([_txtAmountFiatmoney.text compare:@""] != 0) {
        NSString *btc = [[OCAppCommon getInstance] convertBTCFromFiatMoney:[_txtAmountFiatmoney.text doubleValue] currRate:self.cwManager.connectedCwCard.currRate];
        _txtAmount.text = btc;
    }else{
        _txtAmount.text = @"";
    }
    [_txtAmountFiatmoney resignFirstResponder];
}

-(BOOL) isValidBitcoinAddress:(NSString *)address
{
    int verify = addrVerify([address cStringUsingEncoding:NSUTF8StringEncoding]);
    return verify == ADDRESS_VERIFY_BASE;
}

#pragma marks - Account Button Actions

- (void)setAccountButton{
    NSLog(@"cwAccounts = %ld", [cwCard.cwAccounts count]);
    for(int i =0; i< [cwCard.cwAccounts count]; i++) {
        UIButton *accountBtn = [self.accountButtons objectAtIndex:i];
        accountBtn.hidden = NO;
        
        if (i == self.accountButtons.count-1) {
            accountBtn.enabled = YES;
            self.btnAddAccount.hidden = YES;
        }
    }
    
    UIButton *selectedAccount = [self.accountButtons objectAtIndex:self.cwManager.connectedCwCard.currentAccountId];
    [selectedAccount sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)btnAccount:(id)sender {
    if (self.transactionBegin) {
        // should wait for transaction finish?
        return;
    }
    
    NSInteger currentAccId = self.cwManager.connectedCwCard.currentAccountId;
    for (UIButton *btn in self.accountButtons) {
        if (btn == sender) {
            cwCard.currentAccountId = [self.accountButtons indexOfObject:btn];
            
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor colorAccountBackground]];
        } else {
            [btn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor blackColor]];
        }
    }
    
    if (currentAccId != cwCard.currentAccountId) {
        self.transactionBegin = NO;
        [cwCard setDisplayAccount:cwCard.currentAccountId];
    }
    
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", cwCard.currentAccountId]];
    
    [cwCard getAccountInfo:cwCard.currentAccountId];
    [self SetBalanceText];
}

- (void)SetBalanceText
{
    CwAccount *account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", cwCard.currentAccountId]];
    //_lblBalance.text = [NSString stringWithFormat: @"%lld BTC", (int64_t)account.balance];
    _lblBalance.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertBTCStringformUnit: (int64_t)account.balance], [[OCAppCommon getInstance] BitcoinUnit]];
    
    _lblFaitMoney.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertFiatMoneyString:(int64_t)account.balance currRate:self.cwManager.connectedCwCard.currRate], cwCard.currId];
}

-(void) updateAccountInfo:(CwAccount *)cwAccount
{
    [self.updateUnspendBalance addObject:[NSString stringWithFormat:@"%ld", cwAccount.accId]];
    
    BlockChain *blockChain = [[BlockChain alloc] init];
    [blockChain getBalanceByAccountID:cwAccount.accId];
    [self performSelectorOnMainThread:@selector(SetBalanceText) withObject:nil waitUntilDone:NO];
    
    if (![cwAccount isTransactionSyncing]) {
        [self.btcNet getTransactionByAccount: cwAccount.accId];
    } else {
        if (!_btcNet) {
            _btcNet = [self btcNet];
        }
    }
}

-(void) sendPrepareTransaction
{
    if (self.genAddr == nil) {
        return;
    }
    
    self.transactionBegin = YES;
    NSString *sato = [[OCAppCommon getInstance] convertBTCtoSatoshi:self.txtAmount.text];
    [cwCard prepareTransaction: [sato longLongValue] Address:self.txtReceiverAddress.text Change: self.genAddr.address];
}

-(void) cancelTransaction
{
    [self showIndicatorView:@"Cancel transaction..."];
    
    self.transactionBegin = NO;
    [cwCard cancelTrancation];
    [cwCard setDisplayAccount: cwCard.currentAccountId];
}

-(void) cleanInput
{
    [self.txtReceiverAddress setText:@""];
    [self.txtAmount setText:@""];
    [self.txtAmountFiatmoney setText:@""];
}

-(void) performDismiss
{
    [super performDismiss];
    
    if (PressAlert != nil) {
        [PressAlert dismissViewControllerAnimated:YES completion:nil];
        PressAlert = nil;
    }
}

#define TAG_SEND_OTP 1
#define TAG_PRESS_BUTTON 2
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet.tag == TAG_SEND_OTP) {
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            [self cancelTransaction];
        } else {
            [self showIndicatorView:@"Send..."];
            
            [cwCard verifyTransactionOtp:tfOTP.text];
        }
    }else  if(actionSheet.tag == TAG_PRESS_BUTTON) {
        [self cancelTransaction];
    }
}

#pragma marks - CwBtcNetwork Delegates
-(void) didGetTransactionByAccount:(NSInteger)accId
{
    CwAccount *txAccount = (CwAccount *) [self.cwManager.connectedCwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", accId]];
    
    //get address publickey uf the unspent if needed
    for (CwUnspentTxIndex *utx in txAccount.unspentTxs)
    {
        CwAddress *addr;
        if (utx.kcId==0) {
            //External Address
            addr = txAccount.extKeys[utx.kId];
        } else {
            //Internal Address
            addr = txAccount.intKeys[utx.kId];
        }
        
        if (addr.publicKey==nil) {
            [self.cwManager.connectedCwCard getAddressPublickey:accId KeyChainId:utx.kcId KeyId:utx.kId];
        }
    }
    
    NSString *accountId = [NSString stringWithFormat:@"%ld", accId];
    if ([self.updateUnspendBalance containsObject:accountId]) {
        [self.updateUnspendBalance removeObject:accountId];
    }
    
    if (self.transactionBegin && accId == cwCard.currentAccountId) {
        [self performSelectorOnMainThread:@selector(sendBitcoin) withObject:nil waitUntilDone:YES];
//        [self sendBitcoin];
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
    [self performDismiss];
    
    self.transactionBegin = NO;
    
    NSString *msg = [NSString stringWithFormat:@"Cmd %02lX %@", (long)cmdId, errString];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Command Error"
                                                   message: msg
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    
    [alert show];
}

-(void) didSetAccountBalance
{
    [self SetBalanceText];
}

-(void) didPrepareTransactionError: (NSString *) errMsg
{
    [self performDismiss];
    
    self.transactionBegin = NO;
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Unable to send"
                                                   message: errMsg
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles: @"OK",nil];
    
    [alert show];
}

-(void) didGenAddress: (CwAddress *) addr;
{
    NSLog(@"didGenAddress");
    [self.btcNet registerNotifyByAccount:cwCard.currentAccountId];
    
    for (NSString *accIndex in cwCard.cwAccounts) {
        CwAccount *cwAccount = [cwCard.cwAccounts objectForKey:accIndex];
        if (cwAccount.accId == account.accId) {
            continue;
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.address == %@", self.txtReceiverAddress.text];
        NSArray *searchResult = [[cwAccount getAllAddresses] filteredArrayUsingPredicate:predicate];
        if (searchResult.count > 0) {
            CwAddress *address = searchResult[0];
            [self.btcNet registerNotifyByAddress:address];
            break;
        }
    }
    
    self.genAddr = addr;
    
    [self sendPrepareTransaction];
}

-(void) didGenAddressError
{
    [self performDismiss];
    
    self.transactionBegin = NO;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to send" message:@"Can't generate address, please try it later." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) didGetAccountInfo: (NSInteger) accId
{
    NSLog(@"didGetAccountInfo = %ld", accId);
    if(accId == cwCard.currentAccountId) {
        [self SetBalanceText];
        
        if (account.lastUpdate == nil) {
            [cwCard getAccountAddresses:accId];
        }
    }
}

-(void) didGetAccountAddresses:(NSInteger)accId
{
    if (accId == cwCard.currentAccountId) {
        if (account.extKeys.count <= 0) {
            return;
        }
        
        CwAddress *address = [account.extKeys objectAtIndex:0];
        if (address.address != nil) {
            [self performSelectorInBackground:@selector(updateAccountInfo:) withObject:account];
        }
    }
}

-(void) didPrepareTransaction: (NSString *)OTP
{
    NSLog(@"didPrepareTransaction");
    if (cwCard.securityPolicy_OtpEnable.boolValue == YES) {
        [self performDismiss];
        
        self.btnSendBitcoin.hidden = NO;
        [self showOTPEnterView];
    }else{
        [self didVerifyOtp];
    }
}

-(void) didGetTapTapOtp: (NSString *)OTP
{
    NSLog(@"didGetTapTapOtp");
    if (cwCard.securityPolicy_OtpEnable.boolValue == YES) {
        
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
    if (cwCard.securityPolicy_BtnEnable.boolValue == YES) {
        //[self showIndicatorView:@"Press Button On the Card"];
        //self.lblPressButton.text = @"Press Button On the Card";
        [self performDismiss];
        
        PressAlert = [UIAlertController alertControllerWithTitle:@"Press Button On the Card" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self cancelTransaction];
        }];
        [PressAlert addAction:cancelAction];
        
        [self presentViewController:PressAlert animated:YES completion:nil];
        
    } else {
        //self.lblPressButton.text = @"Otp Verified, Sending Bitcoin";
        [self didGetButton];
    }
}

-(void) didVerifyOtpError:(NSInteger)errId
{
    [self performDismiss];
    
    self.txtOtp.text = @"";
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"OTP Error" message:@"Generate OTP Again" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showIndicatorView:@"Send..."];
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
    
    if(PressAlert != nil) [PressAlert dismissViewControllerAnimated:YES completion:nil] ;
    
    if (self.transactionBegin) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Sent"
                                                       message: [NSString stringWithFormat:@"Sent %@ BTC to %@", self.txtAmount.text, self.txtReceiverAddress.text]
                                                      delegate: nil
                                             cancelButtonTitle: nil
                                             otherButtonTitles: @"OK",nil];
        [alert show];
    }
    
    self.transactionBegin = NO;
    
    [self cleanInput];
    
    //back to previous controller
    //[self.navigationController popViewControllerAnimated:YES];
}

-(void) didSignTransactionError:(NSString *)errMsg
{
    self.transactionBegin = NO;
    
    if(PressAlert != nil) [PressAlert dismissViewControllerAnimated:YES completion:nil] ;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to send" message:errMsg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) didFinishTransaction
{
    if (!self.transactionBegin) {
        [self performDismiss];
    }
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
    if(cwCard.securityPolicy_OtpEnable.boolValue == NO) return;
    
    OTPalert = [[UIAlertView alloc] initWithTitle:@"Please enter OTP" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    OTPalert.alertViewStyle = UIAlertViewStylePlainTextInput;
    OTPalert.tag = TAG_SEND_OTP;
    tfOTP = [OTPalert textFieldAtIndex:0];
    tfOTP.keyboardType = UIKeyboardTypeDecimalPad;
    //alertTextField.keyboardType = UIKeyboardTypeNumberPad;
    //alertTextField.placeholder = @"Enter request BTC";
    [OTPalert show];
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
