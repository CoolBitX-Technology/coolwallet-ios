//
//  ExOrderDetailViewController.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/28.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "ExOrderDetailViewController.h"
#import "CwExSellOrder.h"
#import "CwExBuyOrder.h"
#import "CwExchangeManager.h"
#import "CwExTx.h"
#import "CwCommandDefine.h"
#import "BlockChain.h"
#import "CwBtcNetWork.h"
#import "CwUnspentTxIndex.h"

#import "NSDate+Localize.h"

#import <AFNetworking/AFNetworking.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface ExOrderDetailViewController() <CwBtcNetworkDelegate>

@property (weak, nonatomic) IBOutlet UILabel *addressTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *completeOrderBtn;

@property (strong, nonatomic) CwAddress *changeAddress;
@property (assign, nonatomic) BOOL transactionBegin;

@property (strong, nonatomic) CwBtcNetWork *btcNet;
@property (strong, nonatomic) NSMutableArray *unspentAddresses;

@property (assign, nonatomic) BOOL needUpdateAccountInfo;

@end

@implementation ExOrderDetailViewController

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    [self updateUI];
    
    [self updateAccount];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.cwManager.connectedCwCard.delegate == self) {
        self.cwManager.connectedCwCard.delegate = nil;
    }
    
    if (self.btcNet && self.btcNet.delegate == self) {
        self.btcNet.delegate = nil;
    }
}

-(CwBtcNetWork *) btcNet
{
    if (_btcNet == nil) {
        _btcNet = [CwBtcNetWork sharedManager];
    }
    
    return _btcNet;
}

- (void) updateUI
{
    if ([self.order isKindOfClass:[CwExSellOrder class]]) {
        self.addressTitleLabel.text = @"Buyer's Address";
        self.completeOrderBtn.hidden = NO;
        
        CwExSellOrder *sellOrder = (CwExSellOrder *)self.order;
        [self.completeOrderBtn setEnabled:!sellOrder.submitted.boolValue];
    } else {
        self.addressTitleLabel.text = @"Receive Address";
        self.completeOrderBtn.hidden = YES;
    }
    
    self.addressLabel.text = self.order.address;
    
    if (self.order.amountBTC) {
        self.amountLabel.text = [NSString stringWithFormat:@"%@ BTC", self.order.amountBTC];
    }
    
    if (self.order.price) {
        self.priceLabel.text = [NSString stringWithFormat:@"$%@", self.order.price];
    }
    
    self.orderNumberLabel.text = [NSString stringWithFormat:@"#%@", self.order.orderId];
    
    if (self.order.accountId) {
        self.accountLabel.text = [NSString stringWithFormat:@"%d", self.order.accountId.intValue+1];
    }
    
    if (self.order.expiration) {
        self.timeLabel.text = [self.order.expiration localizeDateString:@"hh:mm a MM/dd/yyyy"];
    }
}

- (void) updateAccount
{
    self.unspentAddresses = [NSMutableArray new];
    
    NSInteger orderAccId = self.order.accountId.integerValue;
    
    self.cwManager.connectedCwCard.delegate = self;
    self.cwManager.connectedCwCard.currentAccountId = orderAccId;
    [self.cwManager.connectedCwCard setDisplayAccount:orderAccId];
    
    self.btcNet.delegate = self;
    
    self.needUpdateAccountInfo = NO;
    if (self.order.cwAccount.lastUpdate == nil) {
        self.needUpdateAccountInfo = YES;
        [self.cwManager.connectedCwCard getAccountAddresses:orderAccId];
    } else if (![self.order.cwAccount isAllUnspentPublicKeysExists]) {
        self.needUpdateAccountInfo = YES;
        [self updateUnspentPublicKeys];
    }
}

- (void) updateUnspentPublicKeys
{
    NSInteger orderAccId = self.order.accountId.integerValue;

    for (CwUnspentTxIndex *utx in self.order.cwAccount.unspentTxs)
    {
        [self.cwManager.connectedCwCard getAddressPublickey:orderAccId KeyChainId:utx.kcId KeyId:utx.kId];
    }
}

-(void) updateAccountTransaction
{
    [self.btcNet getTransactionByAccount: self.order.accountId.integerValue];
}

- (IBAction)completeOrder:(UIButton *)sender {
    // prepare ex transaction & sign transaction
    
    self.transactionBegin = YES;
    
    if (self.needUpdateAccountInfo) {
        [self showIndicatorView:@"Update account info first..."];
    } else {
        [self startCompleteOrder];
    }
}

-(void) startCompleteOrder
{
    [self performDismiss];
    [self showIndicatorView:@"Send..."];
    [self.cwManager.connectedCwCard exGetBlockOtp];
}

-(void) sendPrepareTransaction
{
    CwExchangeManager *exchange = [CwExchangeManager sharedInstance];
    CwExSellOrder *sellOrder = (CwExSellOrder *)self.order;
    [exchange prepareTransactionFrom:sellOrder withChangeAddress:self.changeAddress];
}

- (void) showBlockOTPEnterView
{
    UIAlertController *OTPAlert = [UIAlertController alertControllerWithTitle:@"Please enter OTP" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [OTPAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    @weakify(self)
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = OTPAlert.textFields.firstObject;
        @strongify(self)
        [self showIndicatorView:@"block with otp..."];
        
        CwExchangeManager *exManager = [CwExchangeManager sharedInstance];
        [exManager blockWithOrder:(CwExSellOrder *)self.order withOTP:textField.text withSuccess:^() {
            @strongify(self)
            [self.cwManager.connectedCwCard findEmptyAddressFromAccount:self.order.accountId.integerValue keyChainId:CwAddressKeyChainInternal];
            [self showIndicatorView:@"Preparing transaction..."];
        } error:^(NSError *error) {
            @strongify(self)
            [self performDismiss];
            [self showHintAlert:@"block fail" withMessage:error.localizedDescription withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            
            [self.cwManager.connectedCwCard setDisplayAccount:self.cwManager.connectedCwCard.currentAccountId];
        } finish:^() {
            
        }];
    }];
    
    RAC(okAction, enabled) = [OTPAlert.textFields.firstObject.rac_textSignal map:^NSNumber *(NSString *text) {
        return @(text.length == 6);
    }];
    
    [OTPAlert addAction:okAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self performDismiss];
        
        [self.cwManager.connectedCwCard setDisplayAccount:self.cwManager.connectedCwCard.currentAccountId];
    }];
    
    [OTPAlert addAction:cancelAction];
    
    [self presentViewController:OTPAlert animated:YES completion:nil];
}

- (void) showOTPEnterView
{
    if(self.cwManager.connectedCwCard.securityPolicy_OtpEnable.boolValue == NO) return;
    
    UIAlertController *OTPAlert = [UIAlertController alertControllerWithTitle:@"Please enter OTP" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [OTPAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = OTPAlert.textFields.firstObject;
        [self showIndicatorView:@"Send..."];
        
        [self.cwManager.connectedCwCard verifyTransactionOtp:textField.text];
    }];
    
    RAC(okAction, enabled) = [OTPAlert.textFields.firstObject.rac_textSignal map:^NSNumber *(NSString *text) {
        return @(text.length == 6);
    }];
    
    [OTPAlert addAction:okAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self cancelTransaction];
    }];
    
    [OTPAlert addAction:cancelAction];
    
    [self presentViewController:OTPAlert animated:YES completion:nil];
}

-(void) cancelTransaction
{
    [self showIndicatorView:@"Cancel transaction..."];
    
    self.transactionBegin = NO;
    
    [self.cwManager.connectedCwCard setDisplayAccount: self.cwManager.connectedCwCard.currentAccountId];
    
    if ([self.order isKindOfClass:[CwExSellOrder class]]) {
        CwExSellOrder *sellOrder = (CwExSellOrder *)self.order;
        if (sellOrder.exTrx.loginHandle) {
            [self.cwManager.connectedCwCard cancelTrancation];
        }
        
        [self.cwManager.connectedCwCard getBlockAmountWithAccount:self.order.accountId.integerValue];

    }
}

#pragma mark - CwBtc delegate

-(void) didGetTransactionByAccount: (NSInteger) accId
{
    if (accId != self.order.accountId.integerValue) {
        return;
    }
    
    self.needUpdateAccountInfo = ![self.order.cwAccount isAllUnspentPublicKeysExists];
    
    if (self.needUpdateAccountInfo) {
        [self updateUnspentPublicKeys];
    } else if (self.transactionBegin) {
        [self performSelectorOnMainThread:@selector(startCompleteOrder) withObject:nil waitUntilDone:NO];
    }
}

#pragma mark - CwCard delegate
-(void) didGetAccountAddresses:(NSInteger)accId
{
    if (accId != self.order.accountId.integerValue) {
        return;
    }
    
    if (self.order.cwAccount.extKeys.count <= 0) {
        return;
    }
    
    CwAddress *address = [self.order.cwAccount.extKeys objectAtIndex:0];
    if (address.address != nil) {
        [self performSelectorInBackground:@selector(updateAccountTransaction) withObject:nil];
    }
}

-(void) didGetAddressPublicKey:(CwAddress *)address
{
    if (address.accountId != self.order.accountId.integerValue || !self.needUpdateAccountInfo) {
        return;
    }
    
    self.needUpdateAccountInfo = ![self.order.cwAccount isAllUnspentPublicKeysExists];
    
    if (!self.needUpdateAccountInfo && self.transactionBegin) {
        [self performSelectorOnMainThread:@selector(startCompleteOrder) withObject:nil waitUntilDone:NO];
    }
}

-(void) didExGetOtp:(NSString *)exOtp type:(NSInteger)otpType
{
    if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (otpType == CwHdwExOTPKeyInfoBlock) {
        [self showBlockOTPEnterView];
    }
}

-(void) didExGetOtpError:(NSInteger)errId type:(NSInteger)otpType
{
    if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self performDismiss];
    
    if (otpType == CwHdwExOTPKeyInfoBlock) {
        [self showHintAlert:@"Fail" withMessage:@"Can't gen OTP." withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    }
}

-(void) didGenAddress:(CwAddress *) addr
{
    self.changeAddress = addr;
    [self sendPrepareTransaction];
}

-(void) didGenAddressError
{
    [self performDismiss];
    
    [self showHintAlert:@"Unable to send" withMessage:@"Can't generate address, please try it later." withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
}

-(void) didPrepareTransaction:(NSString *)OTP
{
    NSLog(@"didPrepareTransaction, OTP: %@, OTP enabled? %@", OTP, self.cwManager.connectedCwCard.securityPolicy_OtpEnable);
    if (self.cwManager.connectedCwCard.securityPolicy_OtpEnable.boolValue == YES) {
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
    
    [self cancelTransaction];
}

-(void) didGetTapTapOtp:(NSString *)OTP
{
    NSLog(@"didGetTapTapOtp");
    if (self.cwManager.connectedCwCard.securityPolicy_OtpEnable.boolValue != YES) {
        return;
    }
    
    UIAlertController *OTPalert = (UIAlertController *)self.navigationController.presentedViewController;
    
    if(OTPalert){
        OTPalert.textFields.firstObject.text = OTP;
    }
}

-(void) didGetButton
{
    NSLog(@"didGetButton");
    [self.cwManager.connectedCwCard signTransaction];
}

-(void) didVerifyOtp
{
    NSLog(@"didVerifyOtp");
    if (self.cwManager.connectedCwCard.securityPolicy_BtnEnable.boolValue == YES) {
        [self performDismiss];
        
        UIAlertController *pressAlert = [UIAlertController alertControllerWithTitle:@"Press Button On the Card" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self cancelTransaction];
        }];
        [pressAlert addAction:cancelAction];
        
        [self presentViewController:pressAlert animated:YES completion:nil];
    } else {
        [self didGetButton];
    }
}

-(void) didVerifyOtpError:(NSInteger)errId
{
    [self performDismiss];
    
    UIAlertController *OTPAlert = (UIAlertController *)self.navigationController.presentedViewController;
    [OTPAlert dismissViewControllerAnimated:NO completion:nil];
        
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
    
    UIAlertController *alertController = (UIAlertController *)self.navigationController.presentedViewController;
    if(alertController != nil) [alertController dismissViewControllerAnimated:YES completion:nil] ;
    
    if (self.transactionBegin) {
        [self performDismiss];
        
        CwExSellOrder *sellOrder = (CwExSellOrder *)self.order;
        sellOrder.exTrx.trxId = txId;
        
        CwExchangeManager *exchange = [CwExchangeManager sharedInstance];
        [exchange completeTransactionWith:sellOrder];
        
        [self.cwManager.connectedCwCard getBlockAmountWithAccount:self.order.accountId.integerValue];
                
        [self showHintAlert:@"Sent" withMessage:[NSString stringWithFormat:@"Sent %@ BTC to %@", self.order.amountBTC, self.order.address] withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        [self.completeOrderBtn setEnabled:NO];
    }
    
    self.transactionBegin = NO;
}

-(void) didSignTransactionError:(NSString *)errMsg
{
    [self cancelTransaction];
    
    UIAlertController *alertController = (UIAlertController *)self.navigationController.presentedViewController;
    if (alertController != nil) [alertController dismissViewControllerAnimated:YES completion:nil] ;
    
    [self showHintAlert:@"Unable to send" withMessage:errMsg withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
}

-(void) didCancelTransaction
{
    [self performDismiss];
}

@end
