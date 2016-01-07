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

@implementation UITextView (DisablePaste)

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:))
        return NO;
    return [super canPerformAction:action withSender:sender];
}

@end

@interface TabImportSeedViewController () <UITextFieldDelegate, UITextViewDelegate>
{
    CGFloat _currentMovedUpHeight;
}

@property (strong, nonatomic) NSArray *wordSeeds;

@property (weak, nonatomic) IBOutlet UIButton *btnSeedType;
@property (weak, nonatomic) IBOutlet UITextView *txtSeed;

@property (weak, nonatomic) IBOutlet UISwitch *swNumberSeed;

@property (weak, nonatomic) IBOutlet UIView *seedsInputView;

- (IBAction)btnCreateHdw:(id)sender;

@end

CwCard *cwCard;
CwBtcNetWork *btcNet;

@implementation TabImportSeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _currentMovedUpHeight = 0.0f;
    //find CW via BLE
    cwCard = self.cwManager.connectedCwCard;
    btcNet = [CwBtcNetWork sharedManager];
    self.txtSeed.delegate = self;
    
    self.wordSeeds = [NYMnemonic getSeedsWithLanguage:@"english"];
    self.swNumberSeed.on = NO;
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.txtSeed resignFirstResponder];
}

-(void) keyboardWillShow:(NSNotification *)notification
{    
    NSDictionary *info = [notification userInfo];
    CGRect rect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat deltaHeight = (self.seedsInputView.frame.origin.y + self.seedsInputView.frame.size.height / 2) - rect.origin.y;
    
    if (deltaHeight <= 0) {
        _currentMovedUpHeight = 0.0f;
        return;
    }
    
    _currentMovedUpHeight = deltaHeight;
    
    [self moveUpView:YES];
}

-(void) keyboardWillHide:(NSNotification *)notification
{
    [self moveUpView:NO];
}

-(void) moveUpView:(BOOL)shouldMove
{
    if (shouldMove) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationDelegate:self];
        
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        float adjustY = self.view.frame.origin.y;
        if (adjustY < 0) {
            adjustY += _currentMovedUpHeight;
        } else {
            adjustY = _currentMovedUpHeight;
        }
        
        self.view.frame = CGRectMake(self.view.frame.origin.x,
                                     self.view.frame.origin.y - adjustY,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height);
        
        [UIView commitAnimations];
        
    } else if (_currentMovedUpHeight > 0) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationDelegate:self];
        
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        self.view.frame = CGRectMake(self.view.frame.origin.x,
                                     self.view.frame.origin.y + _currentMovedUpHeight,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height);
        
        [UIView commitAnimations];
        
        _currentMovedUpHeight = 0.0f;
    }
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

#pragma marks - textview delegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    NSLog(@"textViewShouldBeginEditing:");
    return YES;
}

#pragma marks - Actions

- (IBAction)btnSelectSeedType:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Choose your seed type" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *englishAction = [UIAlertAction actionWithTitle:@"My seeds is in words" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.txtSeed.text = @"";
        [self.txtSeed setKeyboardType:UIKeyboardTypeASCIICapable];
        [self.txtSeed reloadInputViews];
        self.swNumberSeed.on = NO;
        [self.btnSeedType setTitle:action.title forState:UIControlStateNormal];
    }];
    
    UIAlertAction *numberAction = [UIAlertAction actionWithTitle:@"My seeds is in numbers" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.txtSeed.text = @"";
        [self.txtSeed setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
        [self.txtSeed reloadInputViews];
        self.swNumberSeed.on = YES;
        [self.btnSeedType setTitle:action.title forState:UIControlStateNormal];
    }];
    
    [alertController addAction:englishAction];
    [alertController addAction:numberAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
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
    
    [self showIndicatorView:@"Start init CoolWallet..."];
    
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

-(void) didInitHdwBySeed
{
    [self performDismiss];
    
    [self performSegueWithIdentifier:@"RecoverySegue" sender:self];
}

@end
