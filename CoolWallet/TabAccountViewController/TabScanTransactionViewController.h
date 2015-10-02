//
//  TabScanTransactionViewController.h
//  CwTest
//
//  Created by CP Hsiao on 2015/1/23.
//  Copyright (c) 2015年 CP Hsiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface TabScanTransactionViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UIImageView *cameraGuide;

- (IBAction)flash:(id)sender;

- (void)stop;

@end


