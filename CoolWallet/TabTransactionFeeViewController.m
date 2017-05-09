//
//  TabTransactionFeeViewController.m
//  CoolWallet
//
//  Created by wen on 2017/5/9.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import "TabTransactionFeeViewController.h"
#import "CwTransactionFee.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface TabTransactionFeeViewController ()
@property (weak, nonatomic) IBOutlet UITextField *manualFeeTextField;
@property (weak, nonatomic) IBOutlet UISwitch *autoFeeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *estimatedTransactionFeeLabel;
@end

@implementation TabTransactionFeeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateUI];
    [self addObservers];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [CwTransactionFee saveData];
}

- (void) updateUI
{
    CwTransactionFee *transactionFee = [CwTransactionFee sharedInstance];
    [self.autoFeeSwitch setOn:transactionFee.enableAutoFee.boolValue animated:YES];
    self.autoFeeSwitch.on = transactionFee.enableAutoFee.boolValue;
    self.estimatedTransactionFeeLabel.hidden = !self.autoFeeSwitch.on;
    self.manualFeeTextField.text = transactionFee.manualFee.stringValue;
    self.manualFeeTextField.enabled = !self.autoFeeSwitch.on;
}

- (void) addObservers
{
    @weakify(self)
    [[[RACObserve(self.estimatedTransactionFeeLabel, hidden) filter:^BOOL(NSNumber *hidden) {
        return !hidden.boolValue;
    }] subscribeOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id value) {
         @strongify(self)
         [self.estimatedTransactionFeeLabel setText:[[CwTransactionFee sharedInstance] getEstimatedTransactionFeeString]];
     }];
    
    [[[self.manualFeeTextField.rac_textSignal filter:^BOOL(NSString *value) {
        return [value doubleValue] > 0;
    }]
      distinctUntilChanged]
     subscribeNext:^(NSString *newText) {
        [CwTransactionFee sharedInstance].manualFee = [NSNumber numberWithDouble:[newText doubleValue]];
    }];
    
    [[RACObserve(self.manualFeeTextField, enabled) distinctUntilChanged]
    subscribeNext:^(NSNumber *enabled) {
        if (enabled.boolValue) {
            @strongify(self)
            [self.manualFeeTextField setBackgroundColor:[UIColor whiteColor]];
        } else {
            [self.manualFeeTextField setBackgroundColor:[UIColor lightGrayColor]];
        }
    }];
}

- (IBAction)switchAutoFee:(UISwitch *)sender {
    self.manualFeeTextField.enabled = !sender.on;
    self.estimatedTransactionFeeLabel.hidden = !sender.on;
    
    [CwTransactionFee sharedInstance].enableAutoFee = [NSNumber numberWithBool:sender.on];
}

@end
