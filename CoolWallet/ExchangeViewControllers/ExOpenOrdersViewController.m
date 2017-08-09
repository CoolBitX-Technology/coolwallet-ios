//
//  ExVerifyOrderViewController.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/2/18.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "ExOpenOrdersViewController.h"
#import "CwExchangeManager.h"
#import "CwExchange.h"
#import "QuartzCore/QuartzCore.h"
#import "ExOrderCell.h"
#import "CwCommandDefine.h"

#import "NSUserDefaults+RMSaveCustomObject.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface ExOpenOrdersViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) CwExchange *exchange;

@property (strong, nonatomic) RACDisposable *disposable;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ExOpenOrdersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    CwExchangeManager *exManager = [CwExchangeManager sharedInstance];
    self.exchange = exManager.exchange;
    
    @weakify(self)
    self.disposable = [[[RACObserve(self.exchange, openOrders) distinctUntilChanged] filter:^BOOL(id value) {
        return value != nil;
    }] subscribeNext:^(id value) {
        @strongify(self)
        NSLog(@"openOrders, %@", value);
        
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

#pragma mark - UITableViewDataSource delegate

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.exchange.openOrders == nil) {
        return 0;
    }
    
    return self.exchange.openOrders.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ExOrderCell *cell = (ExOrderCell *)[tableView dequeueReusableCellWithIdentifier:@"OpenOrderCell" forIndexPath:indexPath];
    [cell setOrder:(CwExOrderBase *)[self.exchange.openOrders objectAtIndex:indexPath.row]];
    
    return cell;
}

#pragma mark - UITableViewDelegate delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

#pragma mark - CwCard delegate

-(void) didExGetOtp:(NSString *)exOtp type:(NSInteger)otpType
{
    if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (otpType == CwHdwExOTPKeyInfoBlock) {
        // TODO: pass OTP to API directly
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
