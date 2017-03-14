//
//  TabbarSendConfirmViewController.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2017/2/15.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import "TabbarSendConfirmViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "CwBtcNetWork.h"
#import "CwBtcNetworkDelegate.h"
#import "CwTxin.h"
#import "OCAppCommon.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

typedef NS_ENUM (NSInteger, InputAmountUnit) {
    BTC,
    FiatMoney,
};

@interface TabbarSendConfirmViewController () <CwManagerDelegate, CwCardDelegate, CwBtcNetworkDelegate>

@property (weak, nonatomic) IBOutlet UILabel *lblSendToAddress;
@property (weak, nonatomic) IBOutlet UILabel *lblSendToAmount;
@property (weak, nonatomic) IBOutlet UILabel *lblTxFees;
@property (weak, nonatomic) IBOutlet UILabel *lblTotalAmount;
@property (weak, nonatomic) IBOutlet UILabel *lblInputs;
@property (weak, nonatomic) IBOutlet UILabel *lblInputAmount;
@property (weak, nonatomic) IBOutlet UILabel *lblChangeAddress;
@property (weak, nonatomic) IBOutlet UILabel *lblChangeAmount;
@property (weak, nonatomic) IBOutlet UIButton *btnSend;
@property (weak, nonatomic) IBOutlet UIButton *btnChangeUnit;
@property (weak, nonatomic) IBOutlet UIView *viewChangeAddr;
@property (weak, nonatomic) IBOutlet UIView *viewChangeAmount;
@property (weak, nonatomic) IBOutlet UILabel *lblTxDust;

@property (strong, nonatomic) CwBtcNetWork *btcNet;
@property (strong, nonatomic) CwCard *cwCard;
@property (strong, nonatomic) CwAddress *genAddr;
@property (strong, nonatomic) CwTx *unsignedTx;

@property (strong, nonatomic) UIAlertController *OTPAlertController;
@property (assign, nonatomic) BOOL transactionBegin;
@property (assign, nonatomic) BOOL transactionSuccess;

@property (assign, nonatomic) InputAmountUnit amountUnit;

@end

@implementation TabbarSendConfirmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.btcNet.delegate = self;
    
    self.cwCard = self.cwManager.connectedCwCard;
    self.cwCard.delegate = self;
    
    self.transactionBegin = NO;
    self.transactionSuccess = NO;
    self.amountUnit = BTC;
    
    [self.cwCard findEmptyAddressFromAccount:self.cwAccount.accId keyChainId:CwAddressKeyChainInternal];
    [self updateUI];
}

- (void) viewWillDisappear:(BOOL)animated
{
    if (self.isMovingFromParentViewController && self.transactionSuccess) {
        self.cwCard.paymentAddress = @"";
        self.cwCard.amount = 0;
    }
}

-(CwBtcNetWork *) btcNet
{
    if (_btcNet == nil) {
        _btcNet = [CwBtcNetWork sharedManager];
    }
    
    return _btcNet;
}

-(CwTx *) unsignedTx
{
    if (!_unsignedTx) {
        int64_t satoshi = [self getSendAmountWithSatoshi];
        _unsignedTx = [self.cwCard getUnsignedTransaction:satoshi Address:self.sendToAddress Change:self.genAddr.address AccountId:self.cwAccount.accId];
    }
    
    return _unsignedTx;
}

- (IBAction)sendTransaction:(id)sender {
    [self showIndicatorView:@"Send..."];
    
    self.transactionBegin = YES;
    
    [self.cwCard prepareTransactionWithUnsignedTx:self.unsignedTx];
}

- (IBAction)changeUnit:(id)sender {
    
    
    if (self.amountUnit == BTC) {
        self.amountUnit = FiatMoney;
        [self.btnChangeUnit setTitle:@"BTC" forState:UIControlStateNormal];
        
        NSArray *updateLabels = @[self.lblSendToAmount, self.lblTxFees, self.lblTotalAmount, self.lblInputAmount, self.lblChangeAmount];
        for (UILabel *label in updateLabels) {
            label.text = [self convertToFiatMoney:label.text];
        }
    } else {
        self.amountUnit = BTC;
        [self.btnChangeUnit setTitle:self.cwCard.currId forState:UIControlStateNormal];
        
        self.lblSendToAmount.text = self.sendAmountBTC;
        [self getUnsignedTxInfo];
    }
}

- (NSString *) convertToFiatMoney:(NSString *)btc
{
    NSString *amount = [btc stringByReplacingOccurrencesOfString:@"," withString:@"."];
    NSString *satoshi = [[OCAppCommon getInstance] convertBTCtoSatoshi:amount];
    
    return [[OCAppCommon getInstance] convertFiatMoneyString:[satoshi longLongValue] currRate:self.cwCard.currRate];
}

- (void) updateUI
{
    if (self.amountUnit == BTC) {
        [self.btnChangeUnit setTitle:self.cwCard.currId forState:UIControlStateNormal];
    } else {
        [self.btnChangeUnit setTitle:@"BTC" forState:UIControlStateNormal];
    }
    
    self.lblSendToAddress.text = self.sendToAddress;
    self.lblSendToAmount.text = self.sendAmountBTC;
    
    self.lblTxDust.hidden = YES;
    
    [[[RACObserve(self, genAddr) ignore:nil]
    subscribeOn:[RACScheduler mainThreadScheduler]]
    subscribeNext:^(CwAddress *cwAddr) {
        [self getUnsignedTxInfo];
    }];
}

- (void) getUnsignedTxInfo
{
    int64_t satoshi = [self getSendAmountWithSatoshi];
    
    self.lblTxFees.text = [self.unsignedTx.txFee getBTCDisplayFromUnit];
    
    CwBtc *sendAmount = [CwBtc BTCWithSatoshi:[NSNumber numberWithLongLong:satoshi]];
    CwBtc *totalAmount = [sendAmount add:self.unsignedTx.txFee];
    self.lblTotalAmount.text = [totalAmount getBTCDisplayFromUnit];
    
    self.lblInputs.text = [NSString stringWithFormat:@"%lu Inputs", (unsigned long)self.unsignedTx.inputs.count];
    self.lblInputAmount.text = [self.unsignedTx.totalInput getBTCDisplayFromUnit];
    
    if ([self.unsignedTx.dustAmount greater:[CwBtc BTCWithSatoshi:@(0)]]) {
        self.viewChangeAddr.hidden = YES;
        self.viewChangeAmount.hidden = YES;
        
        [self.lblTxDust setText:[NSString stringWithFormat:@"Notice: the Bitcoin dust of this transaction (BTC %@) will be added to mining fee.", [self.unsignedTx.dustAmount getBTCDisplayFromUnit]]];
        self.lblTxDust.hidden = NO;
    } else {
        self.viewChangeAddr.hidden = NO;
        self.viewChangeAmount.hidden = NO;
        
        self.lblChangeAddress.text = self.genAddr.address;
        self.lblChangeAmount.text = [[self.unsignedTx.totalInput sub:totalAmount] getBTCDisplayFromUnit];
        
        self.lblTxDust.hidden = YES;
    }
    
}

-(long long) getSendAmountWithSatoshi
{
    NSString *sato = [self.sendAmountBTC stringByReplacingOccurrencesOfString:@"," withString:@"."];;
    
    return [[[OCAppCommon getInstance] convertBTCtoSatoshi:sato] longLongValue];
}

- (void) showOTPEnterView
{
    if(self.cwCard.securityPolicy_OtpEnable.boolValue == NO) return;
    
    [self showIndicatorView:@""];
    
    self.OTPAlertController = [UIAlertController alertControllerWithTitle:@"Please enter OTP"       message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    [self.OTPAlertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"OTP";
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    [self.OTPAlertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self cancelTransaction];
    }]];
    
    [self.OTPAlertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = self.OTPAlertController.textFields;
        UITextField *otpField = textfields[0];
        
        [self showIndicatorView:@"Send..."];
        [self.cwCard verifyTransactionOtp:otpField.text];
        
        self.OTPAlertController = nil;
    }]];
    
    
    [self presentViewController:self.OTPAlertController animated:YES completion:nil];
}

-(void) sendPrepareTransaction
{
    if (self.genAddr == nil) {
        self.transactionBegin = NO;
        return;
    }
    
    [self.cwCard prepareTransaction: [self getSendAmountWithSatoshi] Address:self.sendToAddress Change: self.genAddr.address];
}

-(void) cancelTransaction
{
    [self showIndicatorView:@"Cancel transaction..."];
    
    [self.cwCard cancelTrancation];
}

-(void) performDismiss
{
    [super performDismiss];
    
    if (self.OTPAlertController) {
        [self.OTPAlertController dismissViewControllerAnimated:YES completion:^{
            [self cancelTransaction];
        }];
        self.OTPAlertController = nil;
    }
    
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }    
}

# pragma mark - CwCard Delegate

-(void) didGenAddress: (CwAddress *) addr
{
    NSLog(@"didGenAddress, %@, accid = %ld, kid = %ld", addr.address, addr.accountId, (long)addr.keyId);
    
    if (addr.accountId != self.cwAccount.accId) {
        return;
    }
    
    [self.btcNet registerNotifyByAccount:self.cwCard.currentAccountId];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.address == %@", self.sendToAddress];
    NSArray *searchResult = [[self.cwAccount getAllAddresses] filteredArrayUsingPredicate:predicate];
    if (searchResult.count > 0) {
        CwAddress *address = searchResult[0];
        [self.btcNet registerNotifyByAddress:address];
    }
    
    self.genAddr = addr;
}

-(void) didGenAddressError
{
    [self performDismiss];
    
    self.transactionBegin = NO;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to send" message:@"Can't generate address, please try it later." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
    self.btnSend.enabled = NO;
}

-(void) didPrepareTransaction: (NSString *)OTP
{
    NSLog(@"didPrepareTransaction");
    if (self.cwCard.securityPolicy_OtpEnable.boolValue == YES) {
        [self performDismiss];
        
        [self showOTPEnterView];
    }else{
        [self didVerifyOtp];
    }
}

-(void) didPrepareTransactionError: (NSString *) errMsg
{
    [self performDismiss];
    
    self.transactionBegin = NO;
    
    [self showHintAlert:@"Unable to send" withMessage:errMsg withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

    self.btnSend.enabled = NO;
}

-(void) didGetTapTapOtp: (NSString *)OTP
{
    NSLog(@"didGetTapTapOtp");
    if (self.cwCard.securityPolicy_OtpEnable.boolValue == YES) {
        if (self.OTPAlertController) {
            UITextField *otpField = self.OTPAlertController.textFields[0];
            otpField.text = OTP;
        }
    }
}

-(void) didGetButton
{
    NSLog(@"didGetButton");
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self showHintAlert:@"Sending..." withMessage:nil withOKAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self cancelTransaction];
    }]];
    
    [self.cwCard signTransaction];
}

-(void) didVerifyOtp
{
    NSLog(@"didVerifyOtp");
    if (self.cwCard.securityPolicy_BtnEnable.boolValue == YES) {
        [self performDismiss];
        
        [self showHintAlert:@"Press Button On the Card" withMessage:nil withOKAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self cancelTransaction];
        }]];
    } else {
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
    
    [self performDismiss];
    
    self.transactionBegin = NO;
    self.transactionSuccess = YES;
    
    NSString *message = [NSString stringWithFormat:@"Sent %@ BTC to %@", self.sendAmountBTC, self.sendToAddress];
    
    [self showHintAlert:@"Sent" withMessage:message withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
}

-(void) didSignTransactionError:(NSString *)errMsg
{
    [self performDismiss];
    
    [self showHintAlert:@"Unable to send" withMessage:errMsg withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
}

-(void) didFinishTransaction
{
    if (self.transactionBegin) {
        [self performDismiss];
        self.transactionBegin = NO;
        [self.cwCard setDisplayAccount:self.cwAccount.accId];
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

@end
