//
//  TabReceiveBitcoinViewController.h
//  CwTest
//
//  Created by CP Hsiao on 2014/12/27.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "qrencode.h"
#import "BaseViewController.h"

@interface TabReceiveBitcoinViewController : BaseViewController <UITableViewDataSource,UITableViewDelegate>

- (UIImage *)quickResponseImageForString:(NSString *)dataString withDimension:(int)imageWidth;

- (IBAction)btnCopyAddress:(id)sender;
- (IBAction)btnRequestPayment:(id)sender;
- (IBAction)btnEditLabel:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *btnAccount1;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount2;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount3;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount4;
@property (weak, nonatomic) IBOutlet UIButton *btnAccount5;

//- (IBAction)btnAddAccount:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btnEditLabel;
@property (weak, nonatomic) IBOutlet UIButton *btnRequestPayment;

@end
