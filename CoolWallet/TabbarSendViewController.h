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

@property (weak, nonatomic) IBOutlet UIButton *btnSendBitcoin;

- (IBAction)btnSendBitcoin:(id)sender;
- (IBAction)btnScanQRcode:(id)sender;

@end
