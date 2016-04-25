//
//  UIViewController+TabCreateHdwVerifyViewController.h
//  CoolWallet
//
//  Created by bryanLin on 2015/3/13.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CwCard.h"
#import "CwManager.h"
#import "NYMnemonic.h"
#import "BaseViewController.h"

@interface TabCreateHdwVerifyViewController:BaseViewController <CwManagerDelegate, CwCardDelegate, UITextFieldDelegate, UITextViewDelegate>

@property NSString *mnemonic;
@property BOOL SeedOnCard;
@property NSInteger Seedlen;
@property (weak, nonatomic) IBOutlet UILabel *lblSeedOnCardCheck;
@property (weak, nonatomic) IBOutlet UILabel *lblSeedVerifyCheck;
@property (weak, nonatomic) IBOutlet UILabel *lblSeedDetail;
@property (weak, nonatomic) IBOutlet UIView *viewOnCardCheckSum;
@property (weak, nonatomic) IBOutlet UITextField *tfCheckSum;

@property (weak, nonatomic) IBOutlet UIButton *btnCreateWallet;
@property (weak, nonatomic) IBOutlet UIButton *btnNextPage;

- (IBAction)btnCreateWallet:(id)sender;
- (IBAction)btnNextPage:(id)sender;

@end
