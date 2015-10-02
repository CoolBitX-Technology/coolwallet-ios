//
//  UIViewController+FrontViewController.h
//  CoolWallet
//
//  Created by bryanLin on 2014/10/16.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"
#import "CwCard.h"
#import "CwManager.h"
#import "CwManagerDelegate.h"

@interface FrontViewController : UIViewController <CBCentralManagerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btn_connectCoolWallet;
- (IBAction)btn_connectCoolWallet:(id)sender;

- (IBAction)btn_connectlater:(id)sender;

@property CBCentralManager *cbManager;
/*
@property CwManager *cwMgr;

@property (strong, nonatomic) NSMutableArray *cwCards;
@property (strong, nonatomic) CwCard *myCw;
/*
@property(nonatomic) BOOL clearsSelectionOnViewWillAppear NS_AVAILABLE_IOS(3_2); // defaults to YES. If YES, any selection is cleared in viewWillAppear:

@property (nonatomic,retain) UIRefreshControl *refreshControl NS_AVAILABLE_IOS(6_0);*/

@end
