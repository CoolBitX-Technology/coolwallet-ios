//
//  BaseViewController.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/10/8.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()
{
    MBProgressHUD *mHUD;
}

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) showIndicatorView:(NSString *)Msg {
    if (mHUD != nil) {
        mHUD.labelText = Msg;
        return;
    }
    
    mHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:mHUD];
    
    //如果设置此属性则当前的view置于后台
    mHUD.dimBackground = YES;
    mHUD.labelText = Msg;
    
    [mHUD show:YES];
}

- (void) performDismiss
{
    if(mHUD != nil) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        //[mHUD removeFromSuperview];
        //[mHUD release];
        mHUD = nil;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
