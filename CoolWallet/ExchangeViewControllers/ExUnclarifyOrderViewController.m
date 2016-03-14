//
//  ExVerifyOrderViewController.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/2/18.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "ExUnclarifyOrderViewController.h"
#import "CwExchangeManager.h"
#import "QuartzCore/QuartzCore.h"

#import "NSUserDefaults+RMSaveCustomObject.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface ExUnclarifyOrderViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSString *selectOrderID;
@property (strong, nonatomic) NSMutableArray *orders;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ExUnclarifyOrderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void) viewWillAppear:(BOOL)animated
{
    if (self.orders == nil) {
        NSArray *cachedOrders = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"unclarify_%@", self.cwManager.connectedCwCard.cardId]];
        self.orders = [NSMutableArray arrayWithArray:cachedOrders];
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
        
        CwExchangeManager *exchange = [CwExchangeManager sharedInstance];
        [exchange blockWithOrderID:self.selectOrderID withOTP:textField.text withComplete:^() {
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
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"HeaderCell" forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"VerifyOrderCell" forIndexPath:indexPath];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 26;
    } else {
        return 40;
    }
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    self.selectOrderID = @"3b5c2eef";
//    [self.cwManager.connectedCwCard genResetOtp];
//    
//    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - CwCard delegate

-(void) didGenOTPWithError:(NSInteger)errId
{
    if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (errId == -1) {
        [self showOTPEnterView];
    } else {
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
