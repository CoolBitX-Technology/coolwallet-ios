//
//  ExchangeViewController.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/12.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "TabExchangeViewController.h"
#import "CwExchange.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

#define ExSignUpURL @"http://xsm.coolbitx.com:8080/signup"

@interface TabExchangeViewController ()

@property (strong, nonatomic) CwExchange *exchange;

@end

@implementation TabExchangeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.exchange = [CwExchange sharedInstance];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)createSession:(UIButton *)sender {
    [self showIndicatorView:@"Create Session..."];
    [self.exchange createExSession];
    
    @weakify(self);
    [RACObserve(self.exchange, loginSessionFinish) subscribeNext:^(NSNumber *finished) {
        NSLog(@"finished: %d", finished.boolValue);
        @strongify(self);
        if (finished.boolValue) {
            [self performDismiss];
            [self sessionComplete];
        }
    }];
}

- (IBAction)signupEx:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ExSignUpURL]];
}

-(void) sessionComplete
{
    if (self.exchange.loginSession == nil) {
        [self showHintAlert:@"session fail" withMessage:@"can't create session with exchange site" withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    } else {
        [self.exchange syncCardInfo];
    }
}

@end
