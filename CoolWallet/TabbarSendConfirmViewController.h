//
//  TabbarSendConfirmViewController.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2017/2/15.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface TabbarSendConfirmViewController : BaseViewController

@property (strong, nonatomic) CwAccount *cwAccount;
@property (strong, nonatomic) NSString *sendToAddress;
@property (strong, nonatomic) NSString *sendAmountBTC;

@end
