//
//  CwRegisterHostViewController.h
//  CwTest
//
//  Created by CP Hsiao on 2014/12/15.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface CwRegisterHostViewController : UIViewController
{
    MBProgressHUD *mHUD;
}
- (IBAction)BtnCancelAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *viewOTPConfirm;
@property (weak, nonatomic) IBOutlet UIButton *btnRegisterHost;
@property (weak, nonatomic) IBOutlet UIButton *btnRefreshInfo;
@end
