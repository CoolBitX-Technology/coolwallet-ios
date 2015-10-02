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

@interface TabCardViewController () <CwManagerDelegate, CwCardDelegate, UITextFieldDelegate>
@property CwManager *cwManager;


@property (weak, nonatomic) IBOutlet UITextField *txtCardName;
@property (weak, nonatomic) IBOutlet UITextField *txtExchangeRage;
@property (weak, nonatomic) IBOutlet UILabel *lblHdwStatus;
@property (weak, nonatomic) IBOutlet UITextField *txtHdwName;
@property (weak, nonatomic) IBOutlet UILabel *lblHdwAccountPointer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;

- (IBAction)btnUpdateCardName:(id)sender;
- (IBAction)btnUpdateExchangeRate:(id)sender;
- (IBAction)btnUpdateHdwName:(id)sender;

@end

@implementation TabCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.txtCardName.delegate = self;
    self.txtExchangeRage.delegate = self;
    self.txtHdwName.delegate = self;
    
    //Navigate Bar UI effect
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    //Navigate Bar UI effect
    //add CW Logo
    UIImage* myImage = [UIImage imageNamed:@"cwcard.png"];
    UIImageView* myImageView = [[UIImageView alloc] initWithImage:myImage];
    
    myImageView.frame = CGRectMake(60, 5, 30, 30);
    [self.navigationController.navigationBar addSubview:myImageView];
    /*
    //change navigation bar font
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    [self.navigationController.navigationBar setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                      [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                                      shadow, NSShadowAttributeName,
                                                                      [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:21.0], NSFontAttributeName, nil]];
     */
    
    //find CW via BLE
    self.cwManager = [CwManager sharedManager];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];

    self.cwManager.connectedCwCard.delegate = self;
    [self.cwManager.connectedCwCard getCwCardName];
    [self.cwManager.connectedCwCard getCwCurrRate];
    [self.cwManager.connectedCwCard getCwHdwInfo];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma marks -Actions

- (IBAction)btnUpdateCardName:(id)sender {
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    [self.cwManager.connectedCwCard setCwCardName:self.txtCardName.text];
}

- (IBAction)btnUpdateExchangeRate:(id)sender {
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithDecimal:[[formatter numberFromString:self.txtExchangeRage.text] decimalValue]];
    [self.cwManager.connectedCwCard setCwCurrRate:decNum];
}

- (IBAction)btnUpdateHdwName:(id)sender {
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    [self.cwManager.connectedCwCard setCwHdwName:self.txtHdwName.text];
}

#pragma marks -CwCard Delegate

-(void) didCwCardCommand
{
    [self.actBusyIndicator stopAnimating];
    self.actBusyIndicator.hidden = YES;
}

-(void) didGetCwCardName
{
    self.txtCardName.text = self.cwManager.connectedCwCard.cardName;
}

-(void) didSetCwCardName
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Card Name Set"
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
    
}

-(void) didGetCwCurrRate
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSString *numberAsString = [numberFormatter stringFromNumber: self.cwManager.connectedCwCard.currRate];
    
    self.txtExchangeRage.text = numberAsString;
}

-(void) didSetCwCurrRate
{
    /*
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Currency Rate Set"
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];*/
}

-(void) didGetCwHdwStatus
{
    //status, name, account pointer
    
    switch (self.cwManager.connectedCwCard.hdwStatus)
    {
        case CwHdwStatusInactive:
            self.lblHdwStatus.text = @"Inactive";
            break;
        case CwHdwStatusWaitConfirm:
            self.lblHdwStatus.text = @"WaitConfirm";
            break;
        case CwHdwStatusActive:
            self.lblHdwStatus.text = @"Active";
            break;
    }
}

-(void) didGetCwHdwName
{
    self.txtHdwName.text = self.cwManager.connectedCwCard.hdwName;
}

-(void) didGetCwHdwAccointPointer
{
    self.lblHdwAccountPointer.text = [NSString stringWithFormat: @"%ld", (long)self.cwManager.connectedCwCard.hdwAcccountPointer];
}

-(void) didSetCwHdwName
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"HDW Name Set"
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
    
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
