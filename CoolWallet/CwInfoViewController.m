//
//  CwInfoViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/11.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "CwInfoViewController.h"
//#import "CwListTableViewController.h"
#import "FrontViewController.h"
#import "CwRegisterHostViewController.h"
#import "CwEraseCwViewController.h"
#import "CwHost.h"

@interface CwInfoViewController () <CwManagerDelegate, CwCardDelegate>

@property CwManager *cwMgr;

@property (weak, nonatomic) IBOutlet UILabel *lblMode;
@property (weak, nonatomic) IBOutlet UILabel *lblState;
@property (weak, nonatomic) IBOutlet UILabel *lblFwVersion;
@property (weak, nonatomic) IBOutlet UILabel *lblUid;
@property (weak, nonatomic) IBOutlet UILabel *lblCWstatus;
@property (weak, nonatomic) IBOutlet UIButton *btnRegHostNew;
@property (weak, nonatomic) IBOutlet UIButton *btnHostLogin;

- (IBAction)btnHostLoginAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;

@end

@implementation CwInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.cwMgr = [CwManager sharedManager];
    self.cwMgr.delegate=self;
    
    //disable buttons
    self.btnRegHostNew.hidden = YES;
    self.btnHostLogin.hidden = YES;
    self.lblCWstatus.text = @"";
    
    // discover Service
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    self.cwCard.delegate = self;
    [self.cwCard prepareService];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Close the cwCard connection and goback to ListTable
- (void)viewWillDisappear:(BOOL)animated
{
    long currentVCIndex = [self.navigationController.viewControllers indexOfObject:self.navigationController.topViewController];
    NSObject *listCV = [self.navigationController.viewControllers objectAtIndex:currentVCIndex];
    
    if ([listCV isKindOfClass:[FrontViewController class]]) {
        if ([self.cwCard.mode integerValue] == CwCardModeNormal || [self.cwCard.mode integerValue] == CwCardModePerso || [self.cwCard.mode integerValue] == CwCardModeAuth)
            [self.cwCard logoutHost];
        else
            [self didLogoutHost];
        
    } else if ([listCV isKindOfClass:[CwRegisterHostViewController class]]) {
        
    } else if ([listCV isKindOfClass:[CwEraseCwViewController class]]) {
        
    }
}

#pragma mark - Navigation
/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    NSObject *vc = [segue destinationViewController];
}
 */

#pragma mark - CwCard Delegate
-(void) didPrepareService
{
    //[self.cwCard getModeState];
}

-(void) didGetModeState
{
    self.lblMode.text = [NSString stringWithFormat:@"%@", self.cwCard.mode];
    self.lblState.text = [NSString stringWithFormat:@"%@", self.cwCard.state];
    
    if ([self.cwCard.mode integerValue] == CwCardModePerso || [self.cwCard.mode integerValue] == CwCardModeNormal) {
        //already loggin, goto Accounts story board
        [self didLoginHost];
    } else {
        [self.cwCard getCwInfo];
    }
}

-(void) didGetCwInfo
{
    //get fw, uid, hostId (-1)
    
    //display the Contents of the card
    self.lblFwVersion.text = self.cwCard.fwVersion;
    self.lblUid.text = self.cwCard.uid;
    
    //NSLog(@"didGetCwInfo cwcards = %ld",self.cwMgr.cwCards.count);
    
    if ([self.cwCard.mode integerValue] == CwCardModeNoHost) {
        //new Card
        self.lblCWstatus.text = @"New CW Found";
        self.btnRegHostNew.hidden=NO;
        
    } else if ([self.cwCard.mode integerValue] == CwCardModeDisconn || [self.cwCard.mode integerValue] == CwCardModePerso) {
        //used Card
        if ([self.cwCard.hostId integerValue] >= 0) {
            if ([self.cwCard.hostConfirmStatus integerValue] == CwHostConfirmStatusConfirmed) {
                //login
                self.lblCWstatus.text = @"CW Found";
                self.btnHostLogin.hidden=NO;
            } else {
                //need confirm
                self.lblCWstatus.text = @"CW Found, Need Authed Device to Confirm the Registration";
            }
            
        } else {
            //register host, need confirm.
            self.btnRegHostNew.hidden=NO;
        }
    }

    [self reloadInputViews];
    
}

-(void) didCwCardCommand
{
    [self.actBusyIndicator stopAnimating];
    self.actBusyIndicator.hidden = YES;
}

-(void) didSyncFromCard
{
    
}

-(void) didSyncToCard
{
    
}

-(void) didLoginHost
{
    // Get the storyboard named secondStoryBoard from the main bundle:
    UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
    
    // Load the view controller with the identifier string myTabBar
    // Change UIViewController to the appropriate class
    UIViewController *theTabBar = (UIViewController *)[secondStoryBoard instantiateViewControllerWithIdentifier:@"AccountMain"];
    
    // Then push the new view controller in the usual way:
    [self.navigationController presentViewController:theTabBar animated:YES completion:nil];
}

-(void) didLogoutHost
{
    
    long currentVCIndex = [self.navigationController.viewControllers indexOfObject:self.navigationController.topViewController];
    NSObject *listCV = [self.navigationController.viewControllers objectAtIndex:currentVCIndex];
    
    self.cwMgr.delegate = (FrontViewController *)listCV;
    
    [self.cwMgr disconnectCwCard];
    
    //clear properties
    self.cwCard = nil;
    
    NSLog(@"CW Released");
    
    [self.cwMgr scanCwCards];
}

- (IBAction)btnHostLoginAction:(id)sender {
    NSLog(@"btnHostLoginAction");
    //login host
    [self.cwCard loginHost];
}

@end
