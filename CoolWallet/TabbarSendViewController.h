//
//  UIViewController+TabbarSendViewController.h
//  CoolWallet
//
//  Created by bryanLin on 2015/3/19.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CwManager.h"
#import "CwCard.h"
#import "CwAccount.h"
#import "CwAddress.h"
#import "CwBtcNetWork.h"
#import "UIColor+CustomColors.h"
#import "BaseViewController.h"
@interface TabbarSendViewController:BaseViewController <CwManagerDelegate, CwCardDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnAccount1;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount2;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount3;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount4;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount5;
@property (weak, nonatomic) IBOutlet UIButton *btnAddAccount;

//- (IBAction)btnAddAccount:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *lblBalance;
@property (weak, nonatomic) IBOutlet UILabel *lblFaitMoney;

@property (weak, nonatomic) IBOutlet UITextField *txtAmount;
@property (weak, nonatomic) IBOutlet UITextField *txtNote;
@property (weak, nonatomic) IBOutlet UITextField *txtReceiverAddress;
@property (weak, nonatomic) IBOutlet UITextField *txtAmountFiatmoney;
@property (weak, nonatomic) IBOutlet UILabel *lblFiatCurrency;


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;
@property (weak, nonatomic) IBOutlet UIButton *btnSendBitcoin;

- (IBAction)btnSendBitcoin:(id)sender;
- (IBAction)btnScanQRcode:(id)sender;

@end
