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
#import "NSDate+Localize.h"

#import <AFNetworking/AFNetworking.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface ExOrderDetailViewController()

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

@end

@implementation ExOrderDetailViewController

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    if ([self.order isKindOfClass:[CwExSellOrder class]]) {
        self.addressTitleLabel.text = NSLocalizedString(@"Buyer's Address",nil);
        self.completeOrderBtn.hidden = NO;
    } else {
        self.addressTitleLabel.text = NSLocalizedString(@"Receive Address",nil);
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

- (IBAction)completeOrder:(UIButton *)sender {
    // prepare ex transaction & sign transaction
    
//    [self showOTPEnterView];
    [self showIndicatorView:NSLocalizedString(@"Send...",nil)];
    
    [self.cwManager.connectedCwCard findEmptyAddressFromAccount:self.order.accountId.integerValue keyChainId:CwAddressKeyChainInternal];
}

-(void) sendPrepareTransaction
{
    self.transactionBegin = YES;
    
    CwExchangeManager *exchange = [CwExchangeManager sharedInstance];
    [exchange prepareTransactionFromSellOrder:(CwExSellOrder *)self.order withChangeAddress:self.changeAddress.address andAccountId:self.order.accountId.integerValue];
}

- (void) showOTPEnterView
{
    if(self.cwManager.connectedCwCard.securityPolicy_OtpEnable.boolValue == NO) return;
    
    UIAlertController *OTPAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please enter OTP",nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [OTPAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = OTPAlert.textFields.firstObject;
        [self showIndicatorView:NSLocalizedString(@"Send...",nil)];
        
        [self.cwManager.connectedCwCard verifyTransactionOtp:textField.text];
    }];
    
    RAC(okAction, enabled) = [OTPAlert.textFields.firstObject.rac_textSignal map:^NSNumber *(NSString *text) {
        return @(text.length == 6);
    }];
    
    [OTPAlert addAction:okAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self cancelTransaction];
    }];
    
    [OTPAlert addAction:cancelAction];
    
    [self presentViewController:OTPAlert animated:YES completion:nil];
}

-(void) cancelTransaction
{
    [self showIndicatorView:NSLocalizedString(@"Cancel transaction...",nil)];
    
    self.transactionBegin = NO;
    
    [self.cwManager.connectedCwCard cancelTrancation];
    [self.cwManager.connectedCwCard setDisplayAccount: self.cwManager.connectedCwCard.currentAccountId];
}

// card cmd delegate
-(void) didGenAddress:(CwAddress *) addr
{
    self.changeAddress = addr;
    [self sendPrepareTransaction];
}

-(void) didGenAddressError
{
    [self performDismiss];
    
    [self showHintAlert:NSLocalizedString(@"Unable to send",nil) withMessage:NSLocalizedString(@"Can't generate address, please try it later.",nil) withOKAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil]];
}

-(void) didPrepareTransaction: (NSString *)OTP
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
    
    [self showHintAlert:NSLocalizedString(@"Unable to send",nil) withMessage:errMsg withOKAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil]];
}

-(void) didGetTapTapOtp: (NSString *)OTP
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
        
        UIAlertController *pressAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Press Button On the Card",nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
        
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"OTP Error",nil) message:NSLocalizedString(@"Generate OTP Again",nil) preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showIndicatorView:NSLocalizedString(@"Send...",nil)];
        [self sendPrepareTransaction];
    }];
    [alertController addAction:okAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self cancelTransaction];
    }];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) didSignTransaction:(NSString *)txId
{
    NSLog(@"didSignTransaction");
    
    UIAlertController *alertController = (UIAlertController *)self.navigationController.presentedViewController;
    if(alertController != nil) [alertController dismissViewControllerAnimated:YES completion:nil] ;
    
    if (self.transactionBegin) {
        [self performDismiss];
        
        CwExSellOrder *sellOrder = (CwExSellOrder *)self.order;
        
        CwExchangeManager *exchange = [CwExchangeManager sharedInstance];
        [exchange completeTransactionWithOrderId:sellOrder.orderId TxId:txId Handle:sellOrder.trxHandle];
        
        [self showHintAlert:NSLocalizedString(@"Sent",nil) withMessage:[NSString stringWithFormat:NSLocalizedString(@"Sent %@ BTC to %@",nil), self.order.amountBTC, self.order.address] withOKAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil]];
    }
    
    self.transactionBegin = NO;
}

-(void) didSignTransactionError:(NSString *)errMsg
{
    self.transactionBegin = NO;
    
    UIAlertController *alertController = (UIAlertController *)self.navigationController.presentedViewController;
    if(alertController != nil) [alertController dismissViewControllerAnimated:YES completion:nil] ;
    
    [self showHintAlert:NSLocalizedString(@"Unable to send",nil) withMessage:errMsg withOKAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil]];
}

-(void) didCancelTransaction
{
    [self performDismiss];
}

@end
