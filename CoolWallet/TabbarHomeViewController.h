//
//  UIViewController+TabbarHomeViewController.h
//  CoolWallet
//
//  Created by bryanLin on 2015/3/19.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "CwAccount.h"
#import "MBProgressHUD.h"
#import "CwBtcNetwork.h"

@interface TabbarHomeViewController : BaseViewController <CwBtcNetworkDelegate, UITableViewDataSource, UITableViewDelegate>

//@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnAddAccount;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount1;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount2;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount3;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount4;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount5;

@property (weak, nonatomic) IBOutlet UITableView *tableTransaction;

@property (nonatomic,strong) UIRefreshControl *refreshControl;
@end
