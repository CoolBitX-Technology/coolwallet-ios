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
#import "CwExchange.h"
#import "NSDate+Localize.h"

#import <AFNetworking/AFNetworking.h>

@interface ExOrderDetailViewController()

@property (weak, nonatomic) IBOutlet UILabel *addressTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *completeOrderBtn;

@property (strong, nonatomic) NSString *receiveAddress;

@end

@implementation ExOrderDetailViewController

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    if ([self.order isKindOfClass:[CwExSellOrder class]]) {
        self.addressTitleLabel.text = @"Buyer's Address";
        self.completeOrderBtn.hidden = NO;
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
        self.accountLabel.text = [NSString stringWithFormat:@"%@", self.order.accountId];
    }
    if (self.order.expiration) {
        self.timeLabel.text = [self.order.expiration localizeDateString:@"hh:mm a MM/dd/yyyy"];
    }
}

- (IBAction)completeOrder:(UIButton *)sender {
    // prepare ex transaction & sign transaction
    
    [self showIndicatorView:@"Send..."];
    
    [self.cwManager.connectedCwCard genAddress:self.order.accountId.integerValue KeyChainId:CwAddressKeyChainInternal];
}

-(void) didPrepareTransactionError: (NSString *) errMsg
{
    [self performDismiss];
        
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Unable to send"
                                                   message: errMsg
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles: @"OK",nil];
    
    [alert show];
}

-(void) didGenAddress:(CwAddress *) addr
{
    CwExchange *exchange = [CwExchange sharedInstance];
    [exchange prepareTransactionWithAmount:self.order.amountBTC withChangeAddress:addr.address fromAccountId:self.order.accountId.integerValue];
}

//-(void) didPrepareTransaction: (NSString *)OTP
//{
//    NSLog(@"didPrepareTransaction");
//    if (self.cwManager.connectedCwCard.securityPolicy_OtpEnable.boolValue == YES) {
//        [self performDismiss];
//        
//        self.btnSendBitcoin.hidden = NO;
//        [self showOTPEnterView];
//    }else{
//        [self didVerifyOtp];
//    }
//}
//
//-(void) didGetTapTapOtp: (NSString *)OTP
//{
//    NSLog(@"didGetTapTapOtp");
//    if (self.cwManager.connectedCwCard.securityPolicy_OtpEnable.boolValue == YES) {
//        
//        if(OTPalert != nil){
//            tfOTP.text = OTP;
//        }
//        //self.txtOtp.text = OTP;
//        //[self btnVerifyOtp:self];
//    }
//}
//
//-(void) didGetButton
//{
//    NSLog(@"didGetButton");
//    [self.cwManager.connectedCwCard signTransaction];
//}
//
//-(void) didVerifyOtp
//{
//    NSLog(@"didVerifyOtp");
//    if (self.cwManager.connectedCwCard.securityPolicy_BtnEnable.boolValue == YES) {
//        //[self showIndicatorView:@"Press Button On the Card"];
//        //self.lblPressButton.text = @"Press Button On the Card";
//        [self performDismiss];
//        
//        PressAlert = [UIAlertController alertControllerWithTitle:@"Press Button On the Card" message:nil preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//            [self cancelTransaction];
//        }];
//        [PressAlert addAction:cancelAction];
//        
//        [self presentViewController:PressAlert animated:YES completion:nil];
//        
//    } else {
//        //self.lblPressButton.text = @"Otp Verified, Sending Bitcoin";
//        [self didGetButton];
//    }
//}
//
//-(void) didVerifyOtpError:(NSInteger)errId
//{
//    [self performDismiss];
//    
//    self.txtOtp.text = @"";
//    
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"OTP Error" message:@"Generate OTP Again" preferredStyle:UIAlertControllerStyleAlert];
//    
//    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        [self showIndicatorView:@"Send..."];
//        [self sendPrepareTransaction];
//    }];
//    [alertController addAction:okAction];
//    
//    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        [self cancelTransaction];
//    }];
//    [alertController addAction:cancelAction];
//    
//    [self presentViewController:alertController animated:YES completion:nil];
//}
//
//-(void) didSignTransaction
//{
//    NSLog(@"didSignTransaction");
//    //[self performDismiss];
//    
//    if(PressAlert != nil) [PressAlert dismissViewControllerAnimated:YES completion:nil] ;
//    
//    if (self.transactionBegin) {
//        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Sent"
//                                                       message: [NSString stringWithFormat:@"Sent %@ BTC to %@", self.txtAmount.text, self.txtReceiverAddress.text]
//                                                      delegate: nil
//                                             cancelButtonTitle: nil
//                                             otherButtonTitles: @"OK",nil];
//        [alert show];
//    }
//    
//    self.transactionBegin = NO;
//    
//    [self cleanInput];
//    
//    //back to previous controller
//    //[self.navigationController popViewControllerAnimated:YES];
//}
//
//-(void) didSignTransactionError:(NSString *)errMsg
//{
//    self.transactionBegin = NO;
//    
//    if(PressAlert != nil) [PressAlert dismissViewControllerAnimated:YES completion:nil] ;
//    
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to send" message:errMsg preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
//    [alertController addAction:okAction];
//    
//    [self presentViewController:alertController animated:YES completion:nil];
//}
//
//-(void) didFinishTransaction
//{
//    if (!self.transactionBegin) {
//        [self performDismiss];
//    }
//}


@end
