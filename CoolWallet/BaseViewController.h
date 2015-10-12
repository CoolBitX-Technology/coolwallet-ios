//
//  BaseViewController.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/10/8.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface BaseViewController : UIViewController

- (void) showIndicatorView:(NSString *)Msg;
- (void) performDismiss;

@end
