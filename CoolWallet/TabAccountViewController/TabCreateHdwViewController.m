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
#import "CwCommandDefine.h"

@interface TabCreateHdwViewController () <UITextFieldDelegate, UITextViewDelegate>

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
- (IBAction)btnWrittenDown:(id)sender;

@end

@implementation TabCreateHdwViewController{
    BOOL checkWrittenDown;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    checkWrittenDown = NO;
    
    self.txtHdwName.delegate = self;
    self.txtSeed.delegate = self;
    
    // Generating a mnemonic
//    [self genMnemonic: [NSNumber numberWithInt: [self.lblSeedLen.text intValue]*32/3]];
    //mnemonic = [NYMnemonic generateMnemonicString:@128 language:@"english"];
    //NSLog(@"mnemonic = %@",mnemonic);
    
    //[self.swSeedOnCard setOn:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.actBusyIndicator.hidden = YES;
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
}

-(void) updateSeedLen {
    int discreteValue = roundl([self.sliSeedLen value]); // Rounds float to an integer
    NSLog(@"discreteValue = %d", discreteValue);
    if (self.swSeedOnCard.on) {
        //48/72/96
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
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Generate seed on",nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *englishAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"App (words)",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.swSeedOnCard.on = NO;
        [self SetUIforSeedSwitch];
        [self.btnSeedType setTitle:action.title forState:UIControlStateNormal];
    }];
    
    UIAlertAction *numberAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Card (numbers)",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
        [self.btnVerifySeed setTitle:NSLocalizedString(@"Next",nil) forState:UIControlStateNormal];
        
        self.btnCreateHdw.hidden = NO;
        self.btnVerifySeed.hidden = YES;
        
    } else {
        self.txtSeed.hidden=NO;
        self.txtSeed2.hidden=NO;
        self.lblOnCardDetail.hidden = YES;
        self.viewWrittenDown.hidden = YES;
        self.btnCreateHdw.hidden = YES;
        self.btnVerifySeed.hidden = NO;
        [self.btnVerifySeed setTitle:NSLocalizedString(@"Verify",nil) forState:UIControlStateNormal];
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
        
        [self showIndicatorView:NSLocalizedString(@"Generating seed, please wait",nil)];
        
        [self.cwManager.connectedCwCard setSecurityPolicy:NO ButtonEnable:YES DisplayAddressEnable:NO WatchDogEnable:YES];
        [self.cwManager.connectedCwCard initHdw:self.txtHdwName.text ByCard:[self.lblSeedLen.text integerValue] * 6];
    }
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
    [super didCwCardCommandError:cmdId ErrString:errString];
    
    if (cmdId == CwCmdIdHdwInitWalletGen) {
        [self performDismiss];
        
        [self showHintAlert:NSLocalizedString(@"Init wallet fail",nil) withMessage:NSLocalizedString(@"CoolWallet will disconnect, please try again later.",nil) withOKAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.cwManager disconnectCwCard];
        }]];
    }
}

-(void) didSetSecurityPolicy
{
    CwCard *cwCard = self.cwManager.connectedCwCard;
    NSLog(@"security policy: OTP(%@)/PressButton(%@)/Wachdog(%@)/DisplayAddress(%@)", cwCard.securityPolicy_OtpEnable, cwCard.securityPolicy_BtnEnable, cwCard.securityPolicy_WatchDogEnable, cwCard.securityPolicy_DisplayAddressEnable);
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
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Please Backup Seed and Confirm",nil)
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles: NSLocalizedString(@"OK",nil),nil];
    [alert show];

    [self performDismiss];
}

- (IBAction)btnVerifySeed:(id)sender {
    if(_swSeedOnCard.on){
        if(checkWrittenDown == NO){
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Please Backup Seed and Confirm",nil)
                                                           message: nil
                                                          delegate: nil
                                                 cancelButtonTitle: nil
                                                 otherButtonTitles: NSLocalizedString(@"OK",nil),nil];
            [alert show];
            return;
        }
    }
    
    [self performSegueWithIdentifier:@"CreateVerifySegue" sender:self];
}

@end
