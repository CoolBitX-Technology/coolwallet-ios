//
//  TabCreateHdwViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/19.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "TabImportSeedViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "CwAccount.h"
#import "CwAddress.h"
#import "CwBtcNetwork.h"
#import "NYMnemonic.h"
#import "SWRevealViewController.h"

@interface TabImportSeedViewController () <CwManagerDelegate, CwCardDelegate, UITextFieldDelegate, UITextViewDelegate>
@property CwManager *cwManager;
@property (strong, nonatomic) NSArray *wordSeeds;

@property (weak, nonatomic) IBOutlet UITextField *txtHdwName;
@property (weak, nonatomic) IBOutlet UILabel *lblSeedLen;
@property (weak, nonatomic) IBOutlet UITextView *txtSeed;
@property (weak, nonatomic) IBOutlet UIButton *btnCreateHdw;
@property (weak, nonatomic) IBOutlet UIButton *btnConfirmHdw;
@property (weak, nonatomic) IBOutlet UISwitch *swSeedOnCard;
@property (weak, nonatomic) IBOutlet UISlider *sliSeedLen;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;

@property (weak, nonatomic) IBOutlet UILabel *lblSum;
@property (weak, nonatomic) IBOutlet UITextField *txtSum;
@property (weak, nonatomic) IBOutlet UILabel *lblWarning;

@property (weak, nonatomic) IBOutlet UISwitch *swNumberSeed;

- (IBAction)sliSeedLen:(UISlider *)sender;
- (IBAction)swSeedOnCard:(UISwitch *)sender;

- (IBAction)swipSeed:(id)sender;
- (IBAction)btnCreateHdw:(id)sender;
- (IBAction)btnConfirmHdw:(id)sender;

- (IBAction)swNumberSeed:(UISwitch *)sender;

@end

CwCard *cwCard;
CwBtcNetWork *btcNet;

@implementation TabImportSeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //find CW via BLE
    self.cwManager = [CwManager sharedManager];
    cwCard = self.cwManager.connectedCwCard;
    btcNet = [CwBtcNetWork sharedManager];
    //self.txtHdwName.delegate = self;
    self.txtSeed.delegate = self;
    //self.txtSum.delegate = self;
    
    self.wordSeeds = [NYMnemonic getSeedsWithLanguage:@"english"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.cwManager.delegate = self;
    cwCard.delegate = self;
    
    self.actBusyIndicator.hidden = YES;
    //[self.actBusyIndicator startAnimating];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.txtSeed resignFirstResponder];
}

#pragma mark - UITextFieldDelegate Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - UITextViewDelegate Delegates
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@" "]) {
        NSArray *inputWords = [textView.text componentsSeparatedByString:@" "];
        NSString *checkWord = [[inputWords lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (checkWord.length > 0) {
            [self checkImportSeed:checkWord];
        }
    } else if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
    } else if (self.swNumberSeed.on) {
        NSCharacterSet* nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        for (int index = 0; index < text.length; index++) {
            NSRange r = [text rangeOfCharacterFromSet: nonNumbers];
            if (r.location != NSNotFound) {
                return NO;
            }
        }
        
    }
    
    return YES;
}

-(void) genMnemonic: (NSNumber *)seedLen {
    // Generating a mnemonic
    NSString *mnemonic = [NYMnemonic generateMnemonicString:seedLen language:@"english"];
    //=> @"letter advice cage absurd amount doctor acoustic avoid letter advice cage above"
    
    
    self.txtSeed.text = mnemonic;
}

-(void) updateSeedLen {
    int discreteValue = roundl([self.sliSeedLen value]); // Rounds float to an integer
    
    if (self.swSeedOnCard.on) {
        //48/72/96
        self.lblSeedLen.text = [[NSString alloc] initWithFormat:@"%d",  (discreteValue * 24 + 48)];
    } else {
        //12/18/24
        //Seed size	128(32*4) 192(32*6)	256(32*8)
        self.lblSeedLen.text = [[NSString alloc] initWithFormat:@"%d",  (discreteValue * 6 + 12)];
        [self genMnemonic: [NSNumber numberWithInt: [self.lblSeedLen.text intValue]*32/3]];
    }
}

#pragma marks - textview delegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    NSLog(@"textViewShouldBeginEditing:");
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    NSLog(@"textViewDidBeginEditing:");
    textView.backgroundColor = [UIColor greenColor];
}

#pragma marks - Actions

- (IBAction)swNumberSeed:(UISwitch *)sender {
    _txtSeed.text = @"";
}

- (IBAction)btnCreateHdw:(id)sender {
    NSString *seeds = [self.txtSeed.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSString *seed = [NYMnemonic deterministicSeedStringFromMnemonicString: seeds
                                                                passphrase: nil
                                                                  language: @"english"];
    
    //NSString *seed = _txtSeed.text;
    NSLog(@"HDW seed: %@", seed);
    
    //=> "d71de856f81a8acc65e6fc851a38d4d7ec216fd0796d0a6827a3ad6ed5511a30fa280f12eb2e47ed2ac03b5c462a0358d18d69fe4f985ec81778c1b370b652a8"
    [self.cwManager.connectedCwCard initHdw:@"" BySeed:seed];
    
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
}

- (IBAction)btnConfirmHdw:(id)sender {
    [self.cwManager.connectedCwCard initHdwConfirm: self.txtSum.text];
    
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
}

// check seed string number or english
- (void) checkImportSeed:(NSString *)seed {
    BOOL checkResult = NO;
    
    if (self.swNumberSeed.on) {
        if (seed.length != 6) {
            checkResult = NO;
        } else {
            int checkSum = [[seed substringFromIndex:seed.length-1] intValue];
            int sum = 0;
            for (int index = 0; index < seed.length - 1; index++) {
                sum = sum + [[seed substringWithRange:NSMakeRange(index, 1)] intValue];
            }
            
            checkResult = checkSum == (sum % 10);
        }
    } else {
        checkResult = [self.wordSeeds containsObject:seed];
    }
    
    if (!checkResult) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"seed invalid" message:[NSString stringWithFormat:@"'%@' is an invalid seed.", seed] delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
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

-(void) didInitHdwBySeed
{
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
    UIViewController * vc = [sb instantiateViewControllerWithIdentifier:@"CwAccount"];
    
    [self performSegueWithIdentifier:@"RecoverySegue" sender:self];
    
    //[self.revealViewController pushFrontViewController:vc animated:YES];
}

-(void) didInitHdwByCard
{
    //disable btn
    self.btnCreateHdw.enabled = NO;
    self.btnCreateHdw.backgroundColor = [UIColor grayColor];
    
    //enable confirm btn
    self.txtSum.hidden = NO;
    self.lblSum.hidden = NO;
    self.btnConfirmHdw.hidden = NO;
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Please Backup Seed and Confirm"
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
    
}

-(void) didInitHdwConfirm
{
    //disable btn
    self.btnConfirmHdw.enabled = NO;
    self.btnConfirmHdw.backgroundColor = [UIColor grayColor];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"HDW Created"
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
    
    //back to previous controller
    [self.navigationController popViewControllerAnimated:YES];
    
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    //Add a notification to the system
    UILocalNotification *notify = [[UILocalNotification alloc] init];
    notify.alertBody = [NSString stringWithFormat:@"%@ Disconnected", cardName];
    notify.soundName = UILocalNotificationDefaultSoundName;
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
