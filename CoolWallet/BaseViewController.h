//
//  BaseViewController.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/10/8.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "CwManagerDelegate.h"
#import "CwCardDelegate.h"
#import "CwManager.h"

@interface BaseViewController : UIViewController <CwManagerDelegate, CwCardDelegate>

@property (strong, nonatomic) CwManager *cwManager;

- (void) showIndicatorView:(NSString *)Msg;
- (void) performDismiss;
-(void) showHintAlert:(NSString *)title withMessage:(NSString *)message withOKAction:(UIAlertAction *)okAction;
-(void) showHintAlert:(NSString *)title withMessage:(NSString *)message withActions:(NSArray *)actions;
-(BOOL) isLoadingFinish;

@end
