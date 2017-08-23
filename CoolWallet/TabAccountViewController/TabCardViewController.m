//
//  TabCardViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/19.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "TabCardViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "SWRevealViewController.h"

#define MAXLENGTH_CARDNAME 9

@interface TabCardViewController () <UITextFieldDelegate>
//@property CwManager *cwManager;

@property (nonatomic) int updateCount;

@property (weak, nonatomic) IBOutlet UITextField *txtCardName;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;
@property (weak, nonatomic) IBOutlet UISwitch *fiatSwitch;

@end

@implementation TabCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.txtCardName.delegate = self;
    
    //Navigate Bar UI effect
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    self.updateCount = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];

//    self.cwManager.connectedCwCard.delegate = self;
    [self.cwManager.connectedCwCard getCwCardName];
    
    self.fiatSwitch.on = self.cwManager.connectedCwCard.cardFiatDisplay.boolValue;
}

-(void) viewDidDisappear:(BOOL)animated
{
    self.updateCount = 0;
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

- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (textField == self.txtCardName) {
        NSUInteger oldLength = [textField.text length];
        NSUInteger replacementLength = [string length];
        NSUInteger rangeLength = range.length;
        NSUInteger newLength = oldLength - rangeLength + replacementLength;
        BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
        
        return newLength <= MAXLENGTH_CARDNAME || returnKey;
    }
    
    return true;
}

-(void) showUpdateResult
{
    if (self.updateCount > 0) {
        return;
    }
    
    [self showHintAlert:NSLocalizedString(@"Updated!",nil) withMessage:nil withOKAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil]];
}

#pragma marks -Actions

- (IBAction)btnUpdate:(id)sender {
    if (self.updateCount > 0) {
        return;
    }
    
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    if (![self.txtCardName.text isEqualToString:self.cwManager.connectedCwCard.cardName]) {
        self.updateCount += 1;
        [self.cwManager.connectedCwCard setCwCardName:self.txtCardName.text];
    }
    
    if (self.fiatSwitch.on != self.cwManager.connectedCwCard.cardFiatDisplay.boolValue) {
        self.updateCount += 1;
        [self.cwManager.connectedCwCard displayCurrency:self.fiatSwitch.on];
    }
    
    if (self.updateCount <= 0) {
        [self showUpdateResult];
    }
}

#pragma marks -CwCard Delegate

-(void) didCwCardCommand
{
    [self.actBusyIndicator stopAnimating];
    self.actBusyIndicator.hidden = YES;
}

-(void) didGetCwCardName
{
    NSString *cardName = self.cwManager.connectedCwCard.cardName;
    if (cardName == nil || cardName.length == 0) {
        cardName = self.cwManager.connectedCwCard.cardId;
    }
    
    self.txtCardName.text = cardName;
}

-(void) didSetCwCardName
{
    self.updateCount -= 1;
    [self showUpdateResult];
}

-(void) didUpdateCurrencyDisplay
{
    self.updateCount -= 1;
    [self showUpdateResult];
}

-(void) didUpdateCurrencyDisplayError:(NSInteger)errorCode
{
    self.updateCount -= 1;
    [self showHintAlert:NSLocalizedString(@"Update fail",nil) withMessage:nil withOKAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil]];
    
    self.fiatSwitch.on = self.cwManager.connectedCwCard.cardFiatDisplay.boolValue;
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    //Add a notification to the system
    UILocalNotification *notify = [[UILocalNotification alloc] init];
    notify.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ Disconnected",nil), cardName];
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
