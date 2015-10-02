//
//  TabCreateHdwViewController.h
//  CwTest
//
//  Created by CP Hsiao on 2014/12/19.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface TabCreateHdwViewController : UIViewController
{
    NSString *mnemonic;
    MBProgressHUD *mHUD;
}

- (IBAction)btnVerifySeed:(id)sender;
- (IBAction)btnImportSeed:(id)sender;


@end
