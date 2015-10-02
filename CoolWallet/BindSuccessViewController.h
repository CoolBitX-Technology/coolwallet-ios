//
//  UIViewController+BindSuccessViewController.h
//  CoolWallet
//
//  Created by MAC-BRYAN on 2014/10/15.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CwManager.h"
#import "CwHost.h"

@interface BindSuccessViewController:UIViewController <CwManagerDelegate, CwCardDelegate>

- (IBAction)BtnNextToAccounts:(id)sender;
@end
