//
//  UIViewController+HomeViewController.h
//  CoolWallet
//
//  Created by bryanLin on 2014/10/16.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"

@interface HomeViewController : UIViewController <UITableViewDelegate>
{
    NSInteger _presentedRow;
}

@property (weak, nonatomic) IBOutlet UITableView *WalletTableView;
@end
