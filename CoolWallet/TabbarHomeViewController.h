//
//  UIViewController+TabbarHomeViewController.h
//  CoolWallet
//
//  Created by bryanLin on 2015/3/19.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CwManager.h"
#import "CwCard.h"
#import "CwAccount.h"
#import "MBProgressHUD.h"
#import "CwBtcNetwork.h"

@interface TabbarHomeViewController : UIViewController <CwManagerDelegate, CwCardDelegate, CwBtcNetworkDelegate, UITableViewDataSource, UITableViewDelegate>
{
#pragma makrs - Internal properties
    CwManager *cwManager;
    CwCard *cwCard;
    
    MBProgressHUD *mHUD;
}

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnAddAccount;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount1;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount2;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount3;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount4;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount5;
@property (weak, nonatomic) IBOutlet UIButton *btnAddAccount;
@property (weak, nonatomic) IBOutlet UIImageView *imgAddAccount;

@property (weak, nonatomic) IBOutlet UILabel *lblBalance;
@property (weak, nonatomic) IBOutlet UILabel *lblFaitMoney;
@property (weak, nonatomic) IBOutlet UITableView *tableTransaction;

- (IBAction)btnAddAccount:(id)sender;

- (IBAction)btnAccount1:(id)sender;
- (IBAction)btnAccount2:(id)sender;
- (IBAction)btnAccount3:(id)sender;
- (IBAction)btnAccount4:(id)sender;
- (IBAction)btnAccount5:(id)sender;

@property (nonatomic,strong) UIRefreshControl *refreshControl;
@end
