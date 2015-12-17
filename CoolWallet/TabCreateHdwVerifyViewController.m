//
//  UIViewController+TabCreateHdwVerifyViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/3/13.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabCreateHdwVerifyViewController.h"
#import "SWRevealViewController.h"
#import "CwCommandDefine.h"

@implementation TabCreateHdwVerifyViewController 
{
    int SelectPage;
    NSArray *SeedArray;
}

@synthesize mnemonic;
@synthesize SeedOnCard;
@synthesize Seedlen;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    
    SelectPage =0;
    
    //NSLog(@"mnemonic = %@",mnemonic);
    //NSLog(@"SeedOnCard = %d",SeedOnCard);
    
    if(SeedOnCard) {
        _lblSeedVerifyCheck.hidden = YES;
        _lblSeedDetail.hidden = YES;
        _btnNextPage.hidden = YES;
    }else{
        _lblSeedOnCardCheck.hidden = YES;
        _viewOnCardCheckSum.hidden = YES;
        _btnCreateWallet.hidden = YES;
        SeedArray = [mnemonic componentsSeparatedByString:@" "];
        [self ShowSeedDetail];
        [self showHintAlert];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.actBusyIndicator.hidden = YES;
    //[self.actBusyIndicator startAnimating];
}

- (void)ShowSeedDetail
{
    //NSLog(@"array count = %ld",array.count);
    NSString *showSeedStr =@"";
    int showcount = SelectPage*6 + 6;
    //if(showcount <= [SeedArray count]) {
        for (int i = (SelectPage*6); i < showcount; i++){
            showSeedStr = [NSString stringWithFormat:@"%@%d. %@\n",showSeedStr,i+1,[SeedArray objectAtIndex:i] ];
        }
    //}
    if(showcount >= [SeedArray count]) {
        //_btnNextPage.hidden = YES;
        [_btnNextPage setTitle:@"Verify again" forState:UIControlStateNormal];
        _btnCreateWallet.hidden = NO;
    }else{
        [_btnNextPage setTitle:@"Next" forState:UIControlStateNormal];
        _btnCreateWallet.hidden = YES;
    }
    //NSLog(@"showSeedStr = %@",showSeedStr);
    _lblSeedDetail.text = showSeedStr;
}

-(void) showHintAlert
{
    [self showHintAlert:@"IMPORTANT!" withMessage:@"This is the only time you can make a backup of your bitcoins." withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
}

- (IBAction)btnCreateWallet:(id)sender {
    NSLog(@"btnCreateWallet  SeedOnCard = %d",SeedOnCard);
    if (SeedOnCard) {
        //ask card to generate seed
        //[self.cwManager.connectedCwCard initHdw:self.txtHdwName.text ByCard:[self.lblSeedLen.text integerValue]];
        /*
        [self.cwManager.connectedCwCard initHdw:@"" ByCard:Seedlen];
        
        self.actBusyIndicator.hidden = NO;
        [self.actBusyIndicator startAnimating];
         */
        
        [self.cwManager.connectedCwCard initHdwConfirm: self.tfCheckSum.text];
        
        self.actBusyIndicator.hidden = NO;
        [self.actBusyIndicator startAnimating];
        
        //[self didInitHdwBySeed];
        
    } else {
        //send seed to Card
        NSString *seed = [NYMnemonic deterministicSeedStringFromMnemonicString:self.mnemonic
                                                                    passphrase:@""
                                                                      language:@"english"];
        
        //=> "d71de856f81a8acc65e6fc851a38d4d7ec216fd0796d0a6827a3ad6ed5511a30fa280f12eb2e47ed2ac03b5c462a0358d18d69fe4f985ec81778c1b370b652a8"
        //[self.cwManager.connectedCwCard initHdw:self.txtHdwName.text BySeed:seed];
        [self.cwManager.connectedCwCard initHdw:@"" BySeed:seed];
        
        self.actBusyIndicator.hidden = NO;
        [self.actBusyIndicator startAnimating];
    }
}

- (IBAction)btnNextPage:(id)sender {
    int showcount = SelectPage*6 + 6;
    if(showcount >= [SeedArray count]) SelectPage = 0;
    else SelectPage ++;
    [self ShowSeedDetail];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event

{
    [_tfCheckSum resignFirstResponder];
    
    [super touchesBegan:touches withEvent:event];
    
}

#pragma marks - CwCard Delegate
-(void) didCwCardCommand
{
    NSLog(@"didCwCardCommand");
    [self.actBusyIndicator stopAnimating];
    self.actBusyIndicator.hidden = YES;
}

-(void) didCwCardCommandError:(NSInteger)cmdId ErrString:(NSString *)errString
{
    if (cmdId == CwCmdIdHdwInitWalletGenConfirm) {
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Try again" style:UIAlertActionStyleDefault handler:nil];
        
        UIAlertAction *backAction = [UIAlertAction actionWithTitle:@"Regenerate" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }];
        
        [self showHintAlert:@"Checksum incorrect" withMessage:@"Please try again or generate seed again" withActions:@[okAction, backAction]];
    }
}

-(void) didInitHdwBySeed
{
    NSLog(@"didInitHdwBySeed");
    //disable btn
    self.btnCreateWallet.enabled = NO;
    //self.btnCreateWallet.backgroundColor = [UIColor grayColor];
    
    //back to previous controller
    //[self.navigationController popViewControllerAnimated:YES];
    //[self performSegueWithIdentifier:@"unwindToHome" sender:self];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
    UIViewController * vc = [sb instantiateViewControllerWithIdentifier:@"CwAccount"];
    [self.revealViewController pushFrontViewController:vc animated:YES];

}

-(void) didInitHdwByCard
{
    NSLog(@"didInitHdwByCard");
    //disable btn
    self.btnCreateWallet.enabled = NO;
    //self.btnCreateHdw.backgroundColor = [UIColor grayColor];
    /*
    //enable confirm btn
    self.btnConfirmHdw.hidden = NO;
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Please Backup Seed and Confirm"
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
    */
}
//create wallet finish
-(void) didInitHdwConfirm
{
    NSLog(@"didInitHdwConfirm");
    //disable btn
    //self.btnConfirmHdw.enabled = NO;
    //self.btnConfirmHdw.backgroundColor = [UIColor grayColor];
    /*
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"HDW Created"
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
     */
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
    UIViewController * vc = [sb instantiateViewControllerWithIdentifier:@"CwAccount"];
    [self.revealViewController pushFrontViewController:vc animated:YES];

    //[self performSegueWithIdentifier:@"unwindToHome" sender:self];
    //back to previous controller
    //[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    //Add a notification to the system
    UILocalNotification *notify = [[UILocalNotification alloc] init];
    notify.alertBody = [NSString stringWithFormat:@"%@ Disconnected", cardName];
    notify.soundName = UILocalNotificationDefaultSoundName;
    notify.applicationIconBadgeNumber=1;
    [[UIApplication sharedApplication] presentLocalNotificationNow: notify];
    
    // Get the storyboard named secondStoryBoard from the main bundle:
    UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    // Load the view controller with the identifier string myTabBar
    // Change UIViewController to the appropriate class
    UIViewController *listCV = (UIViewController *)[secondStoryBoard instantiateViewControllerWithIdentifier:@"CwMain"];
    // Then push the new view controller in the usual way:
    [self.parentViewController presentViewController:listCV animated:YES completion:nil];
}

@end
