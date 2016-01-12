//
//  ExchangeViewController.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/12.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "TabExchangeViewController.h"

#define ExSignUpURL @"http://xsm.coolbitx.com:8080/signup"

@interface TabExchangeViewController ()

@end

@implementation TabExchangeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)createSession:(UIButton *)sender {
    
}

- (IBAction)signupEx:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ExSignUpURL]];
}

@end
