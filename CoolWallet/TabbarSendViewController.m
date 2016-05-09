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
#import "AccountBalanceView.h"
#import "TabbarAccountViewController.h"

CwCard *cwCard;
CwAccount *account;

UIAlertView *OTPalert;
UITextField *tfOTP;
UIAlertController *PressAlert;

NSDictionary *rates;

long TxFee = 10000;

typedef NS_ENUM (NSInteger, InputAmountUnit) {
    BTC,
    FiatMoney,
};

@interface TabbarSendViewController () <CwBtcNetworkDelegate>
{
    CGFloat _currentMovedUpHeight;
}

@property (weak, nonatomic) IBOutlet UIButton *btnAccount1;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount2;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount3;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount4;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount5;
@property (weak, nonatomic) IBOutlet AccountBalanceView *balanceView;
@property (weak, nonatomic) IBOutlet UIView *sendToView;
@property (weak, nonatomic) IBOutlet UITextField *txtReceiverAddress;
@property (weak, nonatomic) IBOutlet UIView *amountView;
@property (weak, nonatomic) IBOutlet UILabel *lblConvertAmount;
@property (weak, nonatomic) IBOutlet UITextField *txtAmount;
@property (weak, nonatomic) IBOutlet UIButton *btnAmountConvertUnit;
@property (weak, nonatomic) IBOutlet UIButton *btnAmountUnit;
@property (weak, nonatomic) IBOutlet UIView *inputView;

@property (strong, nonatomic) CwAddress *genAddr;
@property (assign, nonatomic) BOOL transactionBegin;
@property (strong, nonatomic) CwBtcNetWork *btcNet;
@property (strong, nonatomic) NSMutableArray *updateUnspendBalance;
@property (strong, nonatomic) NSMutableArray *unspentAddresses;
@property (strong, nonatomic) NSMutableDictionary *publicKeyUpdate;

@property (strong, nonatomic) NSArray *accountButtons;
@property (assign, nonatomic) InputAmountUnit amountUnit;

@property (strong, nonatomic) UIBarButtonItem *addButton;

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
    self.unspentAddresses = [NSMutableArray new];
    self.publicKeyUpdate = [NSMutableDictionary new];
    
    self.accountButtons = @[self.btnAccount1, self.btnAccount2, self.btnAccount3, self.btnAccount4, self.btnAccount5];
    
    self.amountUnit = BTC;
    
    [self.view sendSubviewToBack:self.balanceView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIViewController *parantViewController = self.parentViewController;
    parantViewController.navigationController.navigationBar.hidden = NO;
    if (![parantViewController.navigationItem.title isEqualToString:@"Send"]) {
        [parantViewController.navigationItem setTitle:@"Send"];
        self.addButton = ((TabbarAccountViewController *)parantViewController).addButton;
        [self.addButton setEnabled:NO];
        [self.addButton setTintColor:[UIColor clearColor]];
    }
    
    cwCard.delegate = self;
    self.btcNet.delegate = self;
    
    [self setAccountButton];
    
    if (self.amountUnit == BTC) {
        [self.btnAmountUnit setTitle:@"BTC" forState:UIControlStateNormal];
        [self.btnAmountConvertUnit setTitle:cwCard.currId forState:UIControlStateNormal];
    } else {
        [self.btnAmountUnit setTitle:cwCard.currId forState:UIControlStateNormal];
        [self.btnAmountConvertUnit setTitle:@"BTC" forState:UIControlStateNormal];
    }
    
    self.txtReceiverAddress.text = cwCard.paymentAddress;
    NSString *receiveAmount = cwCard.amount > 0 ? [[OCAppCommon getInstance] convertBTCStringformUnit: cwCard.amount] : nil;
    if (receiveAmount != nil) {
        if (self.amountUnit == BTC) {
            self.txtAmount.text = receiveAmount;
        } else {
            self.lblConvertAmount.text = receiveAmount;
        }
        
        [self doneAmountItem];
    } else {
        self.txtAmount.text = @"";
        self.lblConvertAmount.text = @"";
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    if (self.btcNet && self.btcNet.delegate == self) {
        self.btcNet.delegate = nil;
    }
    
    if (self.transactionBegin) {
        // TODO: alert cancel?
    } else {
        cwCard.paymentAddress = @"";
        cwCard.amount = 0;
        cwCard.label = @"";
    }
    
    if (self.updateUnspendBalance.count > 0) {
        self.transactionBegin = NO;
        [self performDismiss];
        [self.updateUnspendBalance removeAllObjects];
    }
}

-(CwBtcNetWork *) btcNet
{
    if (_btcNet == nil) {
        _btcNet = [CwBtcNetWork sharedManager];
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
    if ([self getSendAmountWithSatoshi] < 1) {
        [self showHintAlert:@"Unable to send" withMessage:@"Please enter a valid amount." withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        return;
    }
    
    if (![self isValidBitcoinAddress:self.txtReceiverAddress.text]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to send" message:@"Invalid Bitcoin address" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    if([self.txtAmount.text compare:@""] == 0 ) return;
    
    self.transactionBegin = YES;
    
    if ([self.updateUnspendBalance containsObject:[NSString stringWithFormat:@"%ld", (long)account.accId]] ) {
        [self showIndicatorView:@"Update unspent balance..."];
    } else {
        //send OTP
        [self sendBitcoin];
    }
}

- (IBAction)btnScanQRcode:(id)sender {
    
    [self performSegueWithIdentifier:@"ScanQRSegue" sender:self];
}

- (IBAction)btnChangeUnit:(UIButton *)sender {
    NSString *txtAmountText = @"";
    
    if (self.amountUnit == BTC) {
        self.amountUnit = FiatMoney;
        [self.btnAmountUnit setTitle:cwCard.currId forState:UIControlStateNormal];
        [self.btnAmountConvertUnit setTitle:@"BTC" forState:UIControlStateNormal];
        
        txtAmountText = self.lblConvertAmount.text;
    } else {
        self.amountUnit = BTC;
        [self.btnAmountUnit setTitle:@"BTC" forState:UIControlStateNormal];
        [self.btnAmountConvertUnit setTitle:cwCard.currId forState:UIControlStateNormal];
        
        txtAmountText = self.lblConvertAmount.text;
    }
    
    self.lblConvertAmount.text = self.txtAmount.text;
    self.txtAmount.text = txtAmountText;
    
}

-(void) sendBitcoin
{
    [self showIndicatorView:@"Send..."];
    
    [cwCard findEmptyAddressFromAccount:cwCard.currentAccountId keyChainId:CwAddressKeyChainInternal];
}

- (void)addDecimalKeyboardDoneButton
{
    //add done button
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 35.0f)];
    toolbar.barStyle=UIBarStyleDefault;
    
    // Create a flexible space to align buttons to the right
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // Create a cancel button to dismiss the keyboard
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAmountItem)];
    
    // Add buttons to the toolbar
    [toolbar setItems:[NSArray arrayWithObjects:flexibleSpace, barButtonItem, nil]];
    
    // Set the toolbar as accessory view of an UITextField object
    _txtAmount.inputAccessoryView = toolbar;
}

- (void)doneAmountItem
{
    NSString *value = @"";
    if ([self.txtAmount.text compare:@""] != 0) {
        if (self.amountUnit == BTC) {
            NSString *amount = [self.txtAmount.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
            NSString *satoshi = [[OCAppCommon getInstance] convertBTCtoSatoshi:amount];
            value =  [[OCAppCommon getInstance] convertFiatMoneyString:[satoshi longLongValue] currRate:self.cwManager.connectedCwCard.currRate];
        } else {
            NSString *amount = [self.txtAmount.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
            value = [[OCAppCommon getInstance] convertBTCFromFiatMoney:[amount doubleValue] currRate:self.cwManager.connectedCwCard.currRate];
        }
        
        self.lblConvertAmount.text = value;
    } else if ([self.lblConvertAmount.text compare:@""] != 0) {
        if (self.amountUnit == BTC) {
            value = [[OCAppCommon getInstance] convertBTCFromFiatMoney:[self.lblConvertAmount.text doubleValue] currRate:self.cwManager.connectedCwCard.currRate];
        } else {
            NSString *satoshi = [[OCAppCommon getInstance] convertBTCtoSatoshi:self.lblConvertAmount.text];
            value =  [[OCAppCommon getInstance] convertFiatMoneyString:[satoshi longLongValue] currRate:self.cwManager.connectedCwCard.currRate];
        }
        
        self.txtAmount.text = value;
    }
    
    [self.txtAmount resignFirstResponder];
}

-(BOOL) isValidBitcoinAddress:(NSString *)address
{
    int verify = addrVerify([address cStringUsingEncoding:NSUTF8StringEncoding]);
    return verify == ADDRESS_VERIFY_BASE;
}

-(long long) getSendAmountWithSatoshi
{
    NSString *sato;
    if (self.amountUnit == BTC) {
        sato = [self.txtAmount.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
        
    } else {
        sato = [self.txtAmount.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    }
    
    return [[[OCAppCommon getInstance] convertBTCtoSatoshi:sato] longLongValue];
}

#pragma marks - Account Button Actions

- (void)setAccountButton{
    for(int i =0; i< [cwCard.cwAccounts count]; i++) {
        UIButton *accountBtn = [self.accountButtons objectAtIndex:i];
        accountBtn.hidden = NO;
        
        if (i == self.accountButtons.count-1) {
            accountBtn.enabled = YES;
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
            [btn setSelected:YES];
        } else {
            [btn setSelected:NO];
        }
    }
    
    if (currentAccId != cwCard.currentAccountId) {
        self.transactionBegin = NO;
        [cwCard setDisplayAccount:cwCard.currentAccountId];
    }
    
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)cwCard.currentAccountId]];
    
    [cwCard getAccountInfo:cwCard.currentAccountId];
    [self SetBalanceText];
}

- (void)SetBalanceText
{
    CwAccount *account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)cwCard.currentAccountId]];
    self.balanceView.account = account;
}

-(void) updateAccountInfo:(CwAccount *)cwAccount
{
    NSString *accountId = [NSString stringWithFormat:@"%ld", (long)cwAccount.accId];
    if (![self.updateUnspendBalance containsObject:accountId]) {
        [self.updateUnspendBalance addObject:accountId];
    }
    
    BlockChain *blockChain = [[BlockChain alloc] init];
    [blockChain getBalanceByAccountID:cwAccount.accId];
    [self performSelectorOnMainThread:@selector(SetBalanceText) withObject:nil waitUntilDone:NO];
    
    [self.btcNet getTransactionByAccount: cwAccount.accId];
}

-(void) sendPrepareTransaction
{
    if (self.genAddr == nil) {
        return;
    }
    
    self.transactionBegin = YES;
    if (![self isGetAllPublicKeyByAccount:cwCard.currentAccountId]) {
        return;
    }
    
    [cwCard prepareTransaction: [self getSendAmountWithSatoshi] Address:self.txtReceiverAddress.text Change: self.genAddr.address];
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
    [self.lblConvertAmount setText:@""];
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

-(void) checkUnspentPublicKeyByAccount:(NSInteger)accId
{
    CwAccount *txAccount = (CwAccount *) [self.cwManager.connectedCwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)accId]];
    
    //get address publickey uf the unspent if needed
    for (CwUnspentTxIndex *utx in txAccount.unspentTxs)
    {
        CwAddress *addr;
        if (utx.kcId==0) {
            addr = txAccount.extKeys[utx.kId];
        } else {
            addr = txAccount.intKeys[utx.kId];
        }
        
        if (addr.publicKey==nil && ![self.unspentAddresses containsObject:addr]) {
            [self.unspentAddresses addObject:addr];
            [self.cwManager.connectedCwCard getAddressPublickey:accId KeyChainId:utx.kcId KeyId:utx.kId];
        }
    }
}

-(BOOL) isGetAllPublicKeyByAccount:(NSInteger)accId
{
    CwAccount *txAccount = (CwAccount *) [self.cwManager.connectedCwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)accId]];
    
    BOOL result = YES;
    //get address publickey uf the unspent if needed
    for (CwUnspentTxIndex *utx in txAccount.unspentTxs)
    {
        CwAddress *addr;
        if (utx.kcId==0) {
            addr = txAccount.extKeys[utx.kId];
        } else {
            addr = txAccount.intKeys[utx.kId];
        }
        
        if (addr.publicKey == nil) {
            result = NO;
            break;
        }
    }
    
    return result;
}

#pragma marks - CwBtcNetwork Delegates
-(void) didGetTransactionByAccount:(NSInteger)accId
{
    if (accId != cwCard.currentAccountId) {
        return;
    }
    
    [self checkUnspentPublicKeyByAccount:accId];
    
    NSString *accountId = [NSString stringWithFormat:@"%ld", (long)accId];
    if ([self.updateUnspendBalance containsObject:accountId]) {
        [self.updateUnspendBalance removeObject:accountId];
    }
    
    if (self.transactionBegin && accId == cwCard.currentAccountId) {
        [self performSelectorOnMainThread:@selector(sendBitcoin) withObject:nil waitUntilDone:YES];
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
    [super didCwCardCommandError:cmdId ErrString:errString];
    
    [self performDismiss];
    
    self.transactionBegin = NO;
}

-(void) didSetAccountBalance:(NSInteger)accId
{
    NSLog(@"TabbarSendViewController, didSetAccountBalance:%ld, currentAccountId:%ld", accId, (long)cwCard.currentAccountId);
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

-(void) didGenAddress: (CwAddress *) addr
{
    NSLog(@"didGenAddress, %@, kid = %ld", addr.address, (long)addr.keyId);
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
    NSLog(@"didGetAccountInfo = %ld", (long)accId);
    if(accId == cwCard.currentAccountId) {
        [self SetBalanceText];
        
        if (account.lastUpdate == nil) {
            [cwCard getAccountAddresses:accId];
        } else {
            [self checkUnspentPublicKeyByAccount:accId];
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

-(void) didGetAddressPublicKey:(CwAddress *)address
{
    if ([self.unspentAddresses containsObject:address]) {
        [self.unspentAddresses removeObject:address];
    }
    
    if (address.accountId != account.accId) {
        return;
    }
    
    if (self.transactionBegin) {
        BOOL isUnspentAddress = NO;
        for (CwUnspentTxIndex *utx in account.unspentTxs)
        {
            if (utx.kcId == address.keyChainId && utx.kId == address.keyId) {
                isUnspentAddress = YES;
                break;
            }
        }
        
        if (isUnspentAddress && [self isGetAllPublicKeyByAccount:account.accId]) {
            [self sendPrepareTransaction];
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
    NSLog(@"didGetButton");
    [PressAlert dismissViewControllerAnimated:YES completion:nil];
    
    PressAlert = [UIAlertController alertControllerWithTitle:@"Sending..." message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self cancelTransaction];
    }];
    [PressAlert addAction:cancelAction];
    
    [self presentViewController:PressAlert animated:YES completion:nil];
    
    [cwCard signTransaction];
}

-(void) didVerifyOtp
{
    NSLog(@"didVerifyOtp");
    if (cwCard.securityPolicy_BtnEnable.boolValue == YES) {
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

-(void) didSignTransaction:(NSString *)txId
{
    NSLog(@"didSignTransaction: %@", txId);
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

-(void) keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat deltaHeight = 0;
    
    if (self.txtReceiverAddress.isFirstResponder) {
        CGRect senderRect = [self.inputView convertRect:self.sendToView.frame toView:self.view];
        
        deltaHeight = kbSize.height - (self.view.frame.size.height - senderRect.origin.y - senderRect.size.height);
    } else if (self.txtAmount.isFirstResponder) {
        CGRect senderRect = [self.inputView convertRect:self.amountView.frame toView:self.view];
        
        deltaHeight = kbSize.height - (self.view.frame.size.height - senderRect.origin.y - senderRect.size.height);
    }
    
    if (_currentMovedUpHeight >= deltaHeight) {
        return;
    } else if (_currentMovedUpHeight > 0) {
        self.view.frame = CGRectMake(self.view.frame.origin.x,
                                     self.view.frame.origin.y + _currentMovedUpHeight,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height);
    }
    
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



@end
