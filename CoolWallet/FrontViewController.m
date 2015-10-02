//
//  UIViewController+FrontViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2014/10/16.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import "FrontViewController.h"

@implementation FrontViewController : UIViewController


#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"FrontViewController");
    //self.title = NSLocalizedString(@"Front View", nil);
    
    SWRevealViewController *revealController = [self revealViewController];
    
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    self.cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    [self checkBluetoothAccess];
    
    //[revealController panGestureRecognizer];
    //[revealController tapGestureRecognizer];
    /*
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                         style:UIBarButtonItemStyleBordered target:revealController action:@selector(revealToggle:)];
    
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    */
    /*
     UIBarButtonItem *rightRevealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
     style:UIBarButtonItemStyleBordered target:revealController action:@selector(rightRevealToggle:)];
     
     self.navigationItem.rightBarButtonItem = rightRevealButtonItem;
    */
    /*
    // Initialize the refresh control.
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor blueColor];
    self.refreshControl.tintColor = [UIColor whiteColor]; //[UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(refreshCwCards)
                  forControlEvents:UIControlEventValueChanged];
    
    self.cwCards = [[NSMutableArray alloc] init];
    
    //find CW via BLE
    self.cwMgr = [CwManager sharedManager];
    self.cwMgr.delegate=self;*/
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
-(void) refreshCwCards {
    [self.cwMgr scanCwCards];
}
*/

- (IBAction)btn_connectCoolWallet:(id)sender {
    NSString *myStoryboardName=@"Main";
    //if(UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPad)
    //   myStoryboardName = [myStoryboardName stringByAppendingString:@"_iPad"];
    UIStoryboard *myTargetStoryboard=[UIStoryboard storyboardWithName:myStoryboardName bundle:nil];
    [self presentModalViewController:[myTargetStoryboard instantiateInitialViewController] animated:YES];
    
}

- (IBAction)btn_persomode:(id)sender {
}

- (IBAction)btn_connectlater:(id)sender {
    SWRevealViewController *revealController = self.revealViewController;
    /*
    UIViewController *newFrontController = [[HomeViewController alloc]init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:newFrontController];
    [revealController pushFrontViewController:navigationController animated:YES];
     */
}

- (void)checkBluetoothAccess {
    
    if(!self.cbManager) {
        self.cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    
    /*
     We can ask the bluetooth manager ahead of time what the authorization status is for our bundle and take the appropriate action.
     */
    
    CBCentralManagerState state = [self.cbManager state];
    
    if(state == CBCentralManagerStateUnknown) {
        NSLog(@"CBCentralManagerStateUnknown");
        //[self alertViewWithDataClass: status:NSLocalizedString(@"UNKNOWN", @"")];
    }
    else if(state == CBCentralManagerStateUnauthorized) {
        NSLog(@"CBCentralManagerStateUnauthorized");
        //[self alertViewWithDataClass:Bluetooth status:NSLocalizedString(@"DENIED", @"")];
    }
    else {
        NSLog(@"CBCentralManagerStateGRANTED");
        //[self alertViewWithDataClass:Bluetooth status:NSLocalizedString(@"GRANTED", @"")];
    }
}
/*
#pragma mark - CwManager Delegate

-(void) didCwManagerReady;
{
    NSLog(@"didCwManagerReady");
    [self.cwMgr scanCwCards];
}

-(void) didScanCwCards: (NSMutableArray *) cwCards
{
    NSLog(@"didScanCwCards");
    self.cwCards = [NSMutableArray arrayWithArray:cwCards];
    
    // Reload table data
    //[self.tableView reloadData];
    
    // End the refreshing
    if (self.refreshControl) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM d, h:mm a"];
        NSString *title = [NSString stringWithFormat:@"Last update: %@", [formatter stringFromDate:[NSDate date]]];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.refreshControl.attributedTitle = attributedTitle;
        
        [self.refreshControl endRefreshing];
    }
}

-(void) didConnectCwCard:(CwCard *)cwCard
{
    
    NSLog(@"didConnectCwCard");
    //clear the UIActivityIndicatorView
    //create activity indicator on the cell
    //UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.cellIndex];
    //[cell setAccessoryView:nil];
    
    //move to CwInfo view
    [self performSegueWithIdentifier:@"CwInfoSegue" sender:self];
}

-(void) didDisconnectCwCard: (CwCard *) cwCard
{
    //Add a notification to the system
    UILocalNotification *notify = [[UILocalNotification alloc] init];
    notify.alertBody = [NSString stringWithFormat:@"CW Disconnected"];
    notify.soundName = UILocalNotificationDefaultSoundName;
    notify.applicationIconBadgeNumber=1;
    [[UIApplication sharedApplication] presentLocalNotificationNow: notify];
}
*/

//-----------start-----------
-(void)centralManagerDidUpdateState:(CBCentralManager*)cManager
{
    NSMutableString* nsmstring=[NSMutableString stringWithString:@"UpdateState:"];
    BOOL isWork=FALSE;
    switch (cManager.state) {
        case CBCentralManagerStateUnknown:
            [nsmstring appendString:@"Unknown\n"];
            break;
        case CBCentralManagerStateUnsupported:
            [nsmstring appendString:@"Unsupported\n"];
            break;
        case CBCentralManagerStateUnauthorized:
            [nsmstring appendString:@"Unauthorized\n"];
            break;
        case CBCentralManagerStateResetting:
            [nsmstring appendString:@"Resetting\n"];
            break;
        case CBCentralManagerStatePoweredOff:
            [nsmstring appendString:@"PoweredOff\n"];
            //if (connectedPeripheral!=NULL){
              //  [self.cbManager cancelPeripheralConnection:connectedPeripheral];
           // }
            break;
        case CBCentralManagerStatePoweredOn:
            [nsmstring appendString:@"PoweredOn\n"];
            isWork=TRUE;
            break;
        default:
            [nsmstring appendString:@"none\n"];
            break;
    }
    NSLog(@"%@",nsmstring);
    //[delegate didUpdateState:isWork message:nsmstring getStatus:cManager.state];
}

@end
