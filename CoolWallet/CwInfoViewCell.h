//
//  UIViewController+CwInfoViewCell.h
//  CoolWallet
//
//  Created by bryanLin on 2015/3/4.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CwInfoViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *ContentView;

@property (weak, nonatomic) IBOutlet UILabel *lb_CwName;
@property (weak, nonatomic) IBOutlet UIImageView *Img_switch;
@property (weak, nonatomic) IBOutlet UIButton *bt_reset;
@property (weak, nonatomic) IBOutlet UIButton *bt_connect;

@end
