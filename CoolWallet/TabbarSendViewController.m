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
#import "AccountBalanceView.h"
#import "TabbarAccountViewController.h"
#import "NSString+Base58.h"
#import "TabbarSendConfirmViewController.h"

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

static NSString *SendConfirmSegueIdentifier = @"SendActionSegue";

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
@property (strong, nonatomic) CwBtcNetWork *btcNet;
@property (strong, nonatomic) NSMutableArray *updateUnspendBalance;
@property (strong, nonatomic) NSMutableArray *unspentAddresses;
@property (strong, nonatomic) NSMutableDictionary *publicKeyUpdate;

@property (strong, nonatomic) NSArray *accountButtons;
@property (assign, nonatomic) InputAmountUnit amountUnit;

@property (strong, nonatomic) UIBarButtonItem *addButton;

@property (strong, nonatomic) NSString *performIdentifier;

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
    
    if (self.updateUnspendBalance.count > 0) {
        [self performDismiss];
        [self.updateUnspendBalance removeAllObjects];
    }
}

-(void) viewDidDisappear:(BOOL)animated
{
    if ([self.tabBarController.selectedViewController class] != [TabbarSendViewController class]) {
        cwCard.paymentAddress = @"";
        cwCard.amount = 0;
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

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    self.performIdentifier = identifier;
    
    if ([identifier isEqualToString:SendConfirmSegueIdentifier]) {
        if ([self.updateUnspendBalance containsObject:[NSString stringWithFormat:@"%ld", (long)account.accId]] ) {
            [self showIndicatorView:@"Update unspent balance..."];
            return NO;
        } else {
            return [self shouldPerfomConfirmPage];
        }
    }
    
    return YES;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SendConfirmSegueIdentifier]) {
        cwCard.paymentAddress = self.txtReceiverAddress.text;
        cwCard.amount = [self getSendAmountWithSatoshi];
        
        TabbarSendConfirmViewController *targetVC = segue.destinationViewController;
        targetVC.cwAccount = account;
        targetVC.sendToAddress = self.txtReceiverAddress.text;
        if (self.amountUnit == BTC) {
            targetVC.sendAmountBTC = self.txtAmount.text;
        } else {
            targetVC.sendAmountBTC = self.lblConvertAmount.text;
        }
    }
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

- (BOOL) shouldPerfomConfirmPage
{
    if ([self getSendAmountWithSatoshi] < 1) {
        [self showHintAlert:@"Unable to send" withMessage:@"Please enter a valid amount." withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        return NO;
    }
    
    if (![self isValidBitcoinAddress:self.txtReceiverAddress.text]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to send" message:@"Invalid Bitcoin address" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
    
    if([self.txtAmount.text compare:@""] == 0 ) return NO;
    
    return YES;
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
    
    if ([self.updateUnspendBalance containsObject:[NSString stringWithFormat:@"%ld", (long)account.accId]] ) {
        [self showIndicatorView:@"Update unspent balance..."];
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
    return [address isValidBitcoinAddress];
}

-(long long) getSendAmountWithSatoshi
{
    NSString *sato;
    if (self.amountUnit == BTC) {
        sato = [self.txtAmount.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
        
    } else {
        sato = [self.lblConvertAmount.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
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
        self.performIdentifier = nil;
        
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
    
    if (OTPalert != nil) {
        [OTPalert dismissWithClickedButtonIndex:OTPalert.cancelButtonIndex animated:YES];
    }
    
    [self dismissAllAlert];
}

- (void)dismissAllAlert
{
    for (UIWindow* w in [UIApplication sharedApplication].windows)
        for (NSObject* o in w.subviews)
            if ([o isKindOfClass:[UIAlertView class]])
                [(UIAlertView*)o dismissWithClickedButtonIndex:[(UIAlertView*)o cancelButtonIndex] animated:YES];
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
    
    if (accId == cwCard.currentAccountId && self.performIdentifier != nil && [self.performIdentifier isEqualToString:SendConfirmSegueIdentifier]) {
        self.performIdentifier = nil;
        [self performDismiss];
        [self performSegueWithIdentifier:SendConfirmSegueIdentifier sender:self.btnSendBitcoin];
    }
}

#pragma marks - CwCard Delegates
-(void) didCwCardCommand
{
    NSLog(@"didCwCardCommand");
    
    [self didGetCwCurrRate];
}

-(void) didCwCardCommandError:(NSInteger)cmdId ErrString:(NSString *)errString
{
    [super didCwCardCommandError:cmdId ErrString:errString];
    
    [self performDismiss];
}

-(void) didSetAccountBalance:(NSInteger)accId
{
    NSLog(@"TabbarSendViewController, didSetAccountBalance:%ld, currentAccountId:%ld", accId, (long)cwCard.currentAccountId);
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
    
    if (self.performIdentifier != nil && [self.performIdentifier isEqualToString:SendConfirmSegueIdentifier]) {
        BOOL isUnspentAddress = NO;
        for (CwUnspentTxIndex *utx in account.unspentTxs)
        {
            if (utx.kcId == address.keyChainId && utx.kId == address.keyId) {
                isUnspentAddress = YES;
                break;
            }
        }
        
        if (isUnspentAddress && [self isGetAllPublicKeyByAccount:account.accId]) {
            [self performSegueWithIdentifier:SendConfirmSegueIdentifier sender:self.btnSendBitcoin];
        }
    }
}

-(void) didGetCwCurrRate
{
    NSLog(@"didGetCwCurrRate");
    NSLog(@"string = %@",[[OCAppCommon getInstance] convertFiatMoneyString:(int64_t)account.balance currRate:cwCard.currRate]);
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
