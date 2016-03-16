//
//  UITableViewController+TabAddressBookViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/4/29.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabAddressBookViewController.h"

@implementation TabAddressBookViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

@end
