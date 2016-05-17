//
//  ExVerifyOrderViewController.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/2/18.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "ExUnclarifyOrderViewController.h"
#import "CwExchangeManager.h"
#import "CwExchange.h"
#import "QuartzCore/QuartzCore.h"
#import "CwExUnclarifyOrder.h"
#import "ExOrderCell.h"
#import "CwCommandDefine.h"

#import "NSUserDefaults+RMSaveCustomObject.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface ExUnclarifyOrderViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) CwExUnclarifyOrder *selectOrder;
@property (strong, nonatomic) CwExchange *exchange;

@property (strong, nonatomic) RACDisposable *disposable;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ExUnclarifyOrderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    CwExchangeManager *exManager = [CwExchangeManager sharedInstance];
    self.exchange = exManager.exchange;
    
    @weakify(self)
    self.disposable = [[[RACObserve(self.exchange, unclarifyOrders) distinctUntilChanged] filter:^BOOL(id value) {
        return value != nil;
    }] subscribeNext:^(id value) {
        @strongify(self)
        NSLog(@"unclarifyOrders, %@", value);
        
        [self.tableView reloadData];
    }];    
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.disposable) {
        [self.disposable dispose];
    }
}

- (void) showOTPEnterView
{
    UIAlertController *OTPAlert = [UIAlertController alertControllerWithTitle:@"Please enter OTP" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [OTPAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = OTPAlert.textFields.firstObject;
        [self showIndicatorView:@"block with otp..."];
        
        CwExchangeManager *exManager = [CwExchangeManager sharedInstance];
        [exManager blockWithOrderID:self.selectOrder.orderId withOTP:textField.text withComplete:^() {
            [self performDismiss];
            
            [self showHintAlert:nil withMessage:@"place order completed" withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            
            [self.tableView reloadData];
        } error:^(NSError *error) {
            [self performDismiss];
            
            [self showHintAlert:@"block fail" withMessage:error.localizedDescription withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        }];
    }];
    
    RAC(okAction, enabled) = [OTPAlert.textFields.firstObject.rac_textSignal map:^NSNumber *(NSString *text) {
        return @(text.length == 6);
    }];
    
    [OTPAlert addAction:okAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        //TODO: need do something with card?
    }];
    
    [OTPAlert addAction:cancelAction];
    
    [self presentViewController:OTPAlert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource delegate

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.exchange.unclarifyOrders == nil) {
        return 0;
    }
    
    return self.exchange.unclarifyOrders.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ExOrderCell *cell = (ExOrderCell *)[tableView dequeueReusableCellWithIdentifier:@"VerifyOrderCell" forIndexPath:indexPath];
    [cell setOrder:[self.exchange.unclarifyOrders objectAtIndex:indexPath.row]];
    
    return cell;
}

#pragma mark - UITableViewDelegate delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectOrder = [self.exchange.unclarifyOrders objectAtIndex:indexPath.row];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
//    [self showOTPEnterView];
    [self.cwManager.connectedCwCard exGetBlockOtp];
}

#pragma mark - CwCard delegate

-(void) didExGetOtp:(NSString *)exOtp type:(NSInteger)otpType
{
    if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (otpType == CwHdwExOTPKeyInfoBlock) {
        [self showOTPEnterView];
    }
}

-(void) didExGetOtpError:(NSInteger)errId type:(NSInteger)otpType
{
    if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (otpType == CwHdwExOTPKeyInfoBlock) {
        [self showHintAlert:@"Fail" withMessage:@"Can't gen OTP." withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    }
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
