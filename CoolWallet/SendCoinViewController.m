//
//  UIViewController+SendCoinViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2014/10/19.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import "SendCoinViewController.h"
#import "SWRevealViewController.h"

@implementation SendCoinViewController : UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Send Coin", nil);
    //self.navigationItem.titleView.backgroundColor = [UIColor blueColor];
    
    SWRevealViewController *revealController = [self revealViewController];
    
    //[revealController panGestureRecognizer];
    //[revealController tapGestureRecognizer];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home-icon"]
                                                                         style:UIBarButtonItemStyleBordered target:nil action:@selector(revealToggle:)];
    
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    
    UIBarButtonItem *rightRevealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu-icon"]
                                                                              style:UIBarButtonItemStyleBordered target:revealController action:@selector(rightRevealToggle:)];
    
    self.navigationItem.rightBarButtonItem = rightRevealButtonItem;
    
}

//點擊文字框以外的地方隱藏鍵盤

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event

{
    
    [_tf_btc resignFirstResponder];
    [_tf_amount resignFirstResponder];
    [_tv_description resignFirstResponder];
    
    [super touchesBegan:touches withEvent:event];
    
}


@end
