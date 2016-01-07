//
//  TabCreateHdwViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/19.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "TabCreateHdwViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "NYMnemonic.h"
#import "TabCreateHdwVerifyViewController.h"
#import "TabImportSeedViewController.h"

@interface TabCreateHdwViewController () <CwManagerDelegate, CwCardDelegate, UITextFieldDelegate, UITextViewDelegate>
@property CwManager *cwManager;

@property (weak, nonatomic) IBOutlet UITextField *txtHdwName;
@property (weak, nonatomic) IBOutlet UILabel *lblSeedLen;
@property (weak, nonatomic) IBOutlet UILabel *lblSeedUnit;
@property (weak, nonatomic) IBOutlet UITextView *txtSeed;
@property (weak, nonatomic) IBOutlet UITextView *txtSeed2;
@property (weak, nonatomic) IBOutlet UIButton *btnCreateHdw;
@property (weak, nonatomic) IBOutlet UIButton *btnConfirmHdw;
@property (weak, nonatomic) IBOutlet UISwitch *swSeedOnCard;
@property (weak, nonatomic) IBOutlet UISlider *sliSeedLen;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;
@property (weak, nonatomic) IBOutlet UILabel *lblOnCardDetail;
@property (weak, nonatomic) IBOutlet UIButton *btnWrittenDown;
@property (weak, nonatomic) IBOutlet UIView *viewWrittenDown;
@property (weak, nonatomic) IBOutlet UIButton *btnVerifySeed;
@property (weak, nonatomic) IBOutlet UIButton *btnSeedType;


- (IBAction)sliSeedLen:(UISlider *)sender;
- (IBAction)swSeedOnCard:(UISwitch *)sender;

- (IBAction)swipSeed:(id)sender;
- (IBAction)btnCreateHdw:(id)sender;
- (IBAction)btnConfirmHdw:(id)sender;
- (IBAction)btnWrittenDown:(id)sender;

@end

@implementation TabCreateHdwViewController{
    BOOL checkWrittenDown;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    checkWrittenDown = NO;
    // Do any additional setup after loading the view.
    //find CW via BLE
    self.cwManager = [CwManager sharedManager];
    self.cwManager.connectedCwCard.delegate = self;
    
    self.txtHdwName.delegate = self;
    self.txtSeed.delegate = self;
    
    // Generating a mnemonic
    [self genMnemonic: [NSNumber numberWithInt: [self.lblSeedLen.text intValue]*32/3]];
    //mnemonic = [NYMnemonic generateMnemonicString:@128 language:@"english"];
    //NSLog(@"mnemonic = %@",mnemonic);
    
    //[self.swSeedOnCard setOn:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.actBusyIndicator.hidden = YES;
    //[self.actBusyIndicator startAnimating];
    //[self.swSeedOnCard setOn:YES animated:YES];
}

-(void)viewDidAppear:(BOOL)animated {
    NSLog(@"viewDidAppear");
    [_swSeedOnCard setOn:YES animated:YES];
    [self SetUIforSeedSwitch];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)unwindHdwToHomeViewcontroller:(UIStoryboardSegue *)unwindSegue
{
    NSLog(@"unwindHdwToHomeViewcontroller");
    //[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITextFieldDelegate Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - UITextViewDelegate Delegates
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
    }
    return YES;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier compare:@"CreateVerifySegue"] == 0) {
        TabCreateHdwVerifyViewController *vc  = [segue destinationViewController];
        vc.mnemonic = mnemonic;
        vc.SeedOnCard = self.swSeedOnCard.on;
        vc.Seedlen = [self.lblSeedLen.text integerValue];
    }
}


-(void) genMnemonic: (NSNumber *)seedLen {
    NSLog(@"genMnemonic len = %@",seedLen);
    // Generating a mnemonic
    mnemonic = [NYMnemonic generateMnemonicString:seedLen language:@"english"];
    NSLog(@"mnemonic = %@",mnemonic);
    //=> @"letter advice cage absurd amount doctor acoustic avoid letter advice cage above"
    NSArray *array = [mnemonic componentsSeparatedByString:@" "];
    //NSLog(@"array count = %ld",array.count);
    NSString *showSeedStr =@"";
    NSString *showSeedStr2 =@"";
    for (int i = 0; i < [array count]; i++){
        if(i < [array count]/2)
            showSeedStr = [NSString stringWithFormat:@"%@%d. %@\n",showSeedStr,i+1,[array objectAtIndex:i] ];
        else showSeedStr2 = [NSString stringWithFormat:@"%@%d. %@\n",showSeedStr2,i+1,[array objectAtIndex:i] ];
    }
    
    self.txtSeed.text = showSeedStr;
    self.txtSeed2.text = showSeedStr2;
    
    //self.txtSeed.text = mnemonic;
}

-(void) updateSeedLen {
    int discreteValue = roundl([self.sliSeedLen value]); // Rounds float to an integer
    NSLog(@"discreteValue = %d", discreteValue);
    if (self.swSeedOnCard.on) {
        //48/72/96
        //self.lblSeedLen.text = [[NSString alloc] initWithFormat:@"%d",  (discreteValue * 24 + 48)];
        self.lblSeedLen.text = [[NSString alloc] initWithFormat:@"%d",  (discreteValue * 4 + 8)];
        [self SetBtnwrittenDownToDefult];
    } else {
        //12/18/24
        //Seed size	128(32*4) 192(32*6)	256(32*8)
        self.lblSeedLen.text = [[NSString alloc] initWithFormat:@"%d",  (discreteValue * 6 + 12)];
        [self genMnemonic: [NSNumber numberWithInt: [self.lblSeedLen.text intValue]*32/3]];
        [self SetBtnwrittenDownToDefult];
    }
}

- (void) SetBtnwrittenDownToDefult{
    checkWrittenDown = NO;
    [self.btnWrittenDown setImage:[UIImage imageNamed:@"checkbox_empty.png"] forState:UIControlStateNormal];
}

#pragma marks - Actions
- (IBAction)selectSeedType:(id)sender {
    if (!self.btnSeedType.enabled) {
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Generate seed on" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *englishAction = [UIAlertAction actionWithTitle:@"App (words)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.swSeedOnCard.on = NO;
        [self SetUIforSeedSwitch];
        [self.btnSeedType setTitle:action.title forState:UIControlStateNormal];
    }];
    
    UIAlertAction *numberAction = [UIAlertAction actionWithTitle:@"Card (numbers)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.swSeedOnCard.on = YES;
        [self SetUIforSeedSwitch];
        [self.btnSeedType setTitle:action.title forState:UIControlStateNormal];
    }];
    
    [alertController addAction:englishAction];
    [alertController addAction:numberAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)sliSeedLen:(UISlider *)sender {
    int discreteValue = roundl([sender value]); // Rounds float to an integer
    [sender setValue:(float)discreteValue]; // Sets your slider to this value

    [self updateSeedLen];
}

- (IBAction)swSeedOnCard:(UISwitch *)sender {
    
    [self SetUIforSeedSwitch];
}

- (void)SetUIforSeedSwitch
{
    [self updateSeedLen];
    
    if (_swSeedOnCard.on) {
        //update seed length
        self.txtSeed.hidden=YES;
        self.txtSeed2.hidden =YES;
        self.lblOnCardDetail.hidden = YES;
        self.viewWrittenDown.hidden = YES;
        [self.btnVerifySeed setTitle:@"Next" forState:UIControlStateNormal];
        
        self.btnCreateHdw.hidden = NO;
        self.btnVerifySeed.hidden = YES;
        /*
         [self.cwManager.connectedCwCard initHdw:self.txtHdwName.text ByCard:[self.lblSeedLen.text integerValue]];
         
         self.actBusyIndicator.hidden = NO;
         [self.actBusyIndicator startAnimating];*/
        
    } else {
        self.txtSeed.hidden=NO;
        self.txtSeed2.hidden=NO;
        self.lblOnCardDetail.hidden = YES;
        self.viewWrittenDown.hidden = YES;
        self.btnCreateHdw.hidden = YES;
        self.btnVerifySeed.hidden = NO;
        [self.btnVerifySeed setTitle:@"Verify" forState:UIControlStateNormal];
    }
    
    [self SetBtnwrittenDownToDefult];
}

- (IBAction)swipSeed:(id)sender {
    [self updateSeedLen];
}

- (IBAction)btnCreateHdw:(id)sender {

    if (self.swSeedOnCard.on) {
        NSLog(@"name = %@, len = %d",self.txtHdwName.text, (int)self.lblSeedLen.text.length);
        //ask card to generate seed
        //[self.cwManager.connectedCwCard initHdw:self.txtHdwName.text ByCard:[self.lblSeedLen.text integerValue]];
        
        [self.cwManager.connectedCwCard setSecurityPolicy:NO ButtonEnable:YES DisplayAddressEnable:NO WatchDogEnable:YES];
        [self.cwManager.connectedCwCard initHdw:self.txtHdwName.text ByCard:[self.lblSeedLen.text integerValue] * 6];
        
        [self showIndicatorView:@"Generating seed, please wait"];
        
    } else {
        //send seed to Card
        NSString *seed = [NYMnemonic deterministicSeedStringFromMnemonicString:self.txtSeed.text
                                                                    passphrase:@""
                                                                      language:@"english"];
        
        //=> "d71de856f81a8acc65e6fc851a38d4d7ec216fd0796d0a6827a3ad6ed5511a30fa280f12eb2e47ed2ac03b5c462a0358d18d69fe4f985ec81778c1b370b652a8"
        [self.cwManager.connectedCwCard initHdw:self.txtHdwName.text BySeed:seed];

        [self showIndicatorView:@""];
    }
}

- (IBAction)btnConfirmHdw:(id)sender {
    //[self.cwManager.connectedCwCard initHdwConfirm];
    //self.cwManager.connectedCwCard initHdwConfirm:<#(NSString *)#>]
//    self.actBusyIndicator.hidden = NO;
//    [self.actBusyIndicator startAnimating];
}

- (IBAction)btnWrittenDown:(id)sender {
    if(checkWrittenDown) {
        checkWrittenDown = NO;
        [self.btnWrittenDown setImage:[UIImage imageNamed:@"checkbox_empty.png"] forState:UIControlStateNormal];
    }
    else {
      checkWrittenDown = YES;
        [self.btnWrittenDown setImage:[UIImage imageNamed:@"checkbox_full.png"] forState:UIControlStateNormal];
    }
}

#pragma marks - CwCard Delegate
-(void) didCwCardCommand
{
    [self.actBusyIndicator stopAnimating];
    self.actBusyIndicator.hidden = YES;
}

-(void) didCwCardCommandError:(NSInteger)cmdId ErrString:(NSString *)errString
{
    NSString *msg = [NSString stringWithFormat:@"Cmd %02lX %@", (long)cmdId, errString];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Command Error"
                                                   message: msg
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    
    [alert show];
}

-(void) didSetSecurityPolicy
{
    CwCard *cwCard = self.cwManager.connectedCwCard;
    NSLog(@"security policy: OTP(%@)/PressButton(%@)/Wachdog(%@)/DisplayAddress(%@)", cwCard.securityPolicy_OtpEnable, cwCard.securityPolicy_BtnEnable, cwCard.securityPolicy_WatchDogEnable, cwCard.securityPolicy_DisplayAddressEnable);
    
//    if (self.swSeedOnCard.on && self.cwManager.connectedCwCard.securityPolicy_WatchDogEnable.boolValue) {
//        [self.cwManager.connectedCwCard initHdw:self.txtHdwName.text ByCard:[self.lblSeedLen.text integerValue] * 6];
//    }
}

-(void) didInitHdwByCard
{
    NSLog(@"didInitHdwByCard hdw!!");
    //disable btn
    self.btnCreateHdw.enabled = NO;
    
    self.btnCreateHdw.hidden = YES;
    self.btnVerifySeed.hidden = NO;
    
    self.lblOnCardDetail.hidden = NO;
    self.viewWrittenDown.hidden = NO;
    
    self.btnSeedType.enabled = NO;
    
    //enable confirm btn
    //self.btnConfirmHdw.hidden = NO;
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Please Backup Seed and Confirm"
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];

    [self performDismiss];
}

-(void) didInitHdwConfirm
{
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
    //back to previous controller
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    NSLog(@"disconnect");
    //Add a notification to the systemek3
    /*
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
     */
}

- (IBAction)btnVerifySeed:(id)sender {
    if(_swSeedOnCard.on){
        if(checkWrittenDown == NO){
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Please Backup Seed and Confirm"
                                                           message: nil
                                                          delegate: nil
                                                 cancelButtonTitle: nil
                                                 otherButtonTitles:@"OK",nil];
            [alert show];
            return;
        }
    }
    
    [self performSegueWithIdentifier:@"CreateVerifySegue" sender:self];
}

- (IBAction)btnImportSeed:(id)sender {
    [self performSegueWithIdentifier:@"ImportSeedSegue" sender:self];
}

- (void) showIndicatorView:(NSString *)Msg {
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
        [mHUD removeFromSuperview];
        //[mHUD release];
        mHUD = nil;
    }
    //[IndicatorAlert dismissWithClickedButtonIndex:0 animated:NO];
}

@end
