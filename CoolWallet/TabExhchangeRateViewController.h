//
//  UIViewController+TabExhchangeRateViewController.h
//  CoolWallet
//
//  Created by bryanLin on 2015/9/1.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CwManager.h"
#import "CwCard.h"

@interface TabExhchangeRateViewController :UIViewController <CwManagerDelegate,CwCardDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableExchangeRate;
@end
