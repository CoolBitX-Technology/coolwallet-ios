//
//  UIViewController+ReciveCoinViewContorller.h
//  CoolWallet
//
//  Created by bryanLin on 2014/10/19.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReciveCoinViewContorller : UIViewController 

@property (weak, nonatomic) IBOutlet UITextField *tf_amount;
@property (weak, nonatomic) IBOutlet UITextField *tf_btc;
@property (weak, nonatomic) IBOutlet UITextView *tv_description;
@end
