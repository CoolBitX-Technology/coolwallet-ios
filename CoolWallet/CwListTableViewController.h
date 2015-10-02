//
//  CwListTableViewController.h
//  CwTest
//
//  Created by CP Hsiao on 2014/11/27.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CwManager.h"
#import "CwInfoViewCell.h"
#import "MBProgressHUD.h"

@interface CwListTableViewController : UIViewController  <UITableViewDelegate, UITableViewDataSource, CwManagerDelegate>
{
    MBProgressHUD *mHUD;
}
@property CwManager *cwMgr;

@property (weak, nonatomic) IBOutlet UIView *view_connecting;
@property (weak, nonatomic) IBOutlet UITableView *tablev_cwlist;
@property (weak, nonatomic) IBOutlet UIButton *bt_cwlater;

@end
