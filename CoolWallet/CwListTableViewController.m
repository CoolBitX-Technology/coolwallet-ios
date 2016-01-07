//
//  CwListTableViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/11/27.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "CwListTableViewController.h"
#import "CwInfoViewController.h"
#import "CwCard.h"
#import "KeychainItemWrapper.h"

@interface CwListTableViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@property (strong, nonatomic) NSMutableArray *cwCards;
@property (strong, nonatomic) CwCard *myCw;
@property NSIndexPath *cellIndex;
@end

@implementation CwListTableViewController

@synthesize tablev_cwlist;
@synthesize view_connecting;

NSString *segueIdentifier;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.cwCards = [[NSMutableArray alloc] init];

    //find CW via BLE
    self.cwMgr = [CwManager sharedManager];
    
    self.tablev_cwlist.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [self.versionLabel setText:[NSString stringWithFormat:@"V%@", version]];    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.cwMgr.delegate = self;
    
    self.cwCards = nil;
    
    [self.tablev_cwlist reloadData];
    
    //[super didReceiveMemoryWarning];
}

-(void)viewDidAppear:(BOOL)animated {
    [self.cwMgr scanCwCards];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
-(void) refreshCwCards {
    [self.cwMgr scanCwCards];
}*/


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.cwCards count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //CwInfoViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CwInfoViewCell" forIndexPath:indexPath];
    
    NSLog(@"tableView");
    
    static NSString *CellIdentifier = @"CwInfoViewCell";
    CwInfoViewCell *cell = (CwInfoViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        cell = [[[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil] objectAtIndex:0];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    CwCard *cw = [self.cwCards objectAtIndex:indexPath.row];
    NSLog(@"name = %@, cardName = %@, curr= %@",cw.bleName, cw.cardName, [NSString stringWithFormat:@"%@", cw.rssi]);
    cell.lb_CwName.text = cw.bleName;
    //cell.lb_CwSerial.text = [NSString stringWithFormat:@"%@", cw.rssi];
    
    if (self.cellIndex.row == indexPath.row)
    {
        NSLog(@"not hidden");
        //cell.ContentView.hidden = false;
        cell.bt_connect.hidden = NO;
        cell.bt_reset.hidden = NO;
        
    }
    else
    {
        NSLog(@"hidden");
        cell.bt_connect.hidden = YES;
        cell.bt_reset.hidden = YES;
    }
    
    [cell.bt_connect setTag:indexPath.row];
    [cell.bt_connect addTarget:self action:@selector(btnConnectClicked:event:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.bt_connect setTag:indexPath.row];
    [cell.bt_reset addTarget:self action:@selector(btnResetClicked:event:) forControlEvents:UIControlEventTouchUpInside];

    return cell;
}

- (void) btnConnectClicked:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currenTouchPosition = [touch locationInView:self.tablev_cwlist];
    NSIndexPath *indexPath = [self.tablev_cwlist indexPathForRowAtPoint:currenTouchPosition];
    NSLog(@"btnConnectClicked : indexpath = %ld",indexPath.row);
    
    if(indexPath != nil) {
        segueIdentifier = @"CwRegisterHostSegue";
        //[self PushCwSegue:@"CwInfoSegue" index:indexPath];
        [self ConnectCwCardIndex:indexPath];
        //[self PushCwSegue:@"CwRegisterHostSegue" index:indexPath];
        [self showIndicatorView:@"Connecting..."];
    }
}

- (void) btnResetClicked:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currenTouchPosition = [touch locationInView:self.tablev_cwlist];
    NSIndexPath *indexPath = [self.tablev_cwlist indexPathForRowAtPoint:currenTouchPosition];
    NSLog(@"btnResetClicked : indexpath = %d",indexPath.row);
    
    if(indexPath != nil) {
        segueIdentifier = @"CwResetSegue";
        [self ConnectCwCardIndex:indexPath];
        [self showIndicatorView:@"Connecting..."];
        //[self PushCwSegue:@"CwResetSegue" index:indexPath];
        
    }
}

- (void)ConnectCwCardIndex:(NSIndexPath *)indexPath {
    self.cellIndex = indexPath;
    
    self.myCw = [self.cwCards objectAtIndex:indexPath.row];
    
    /*
    //fill the UUID as the credential
    self.myCw.devCredential = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];*/
    //Get UUID from Keychain if any
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"CwAppUUID" accessGroup:nil];
    
    //get uuid form key chain
    NSString *uuid =[keychain objectForKey:(id)CFBridgingRelease(kSecAttrService)];
    
    if (uuid==nil) {
        uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        //store UUID to Keychain if no
        [keychain setObject:uuid forKey:(id)CFBridgingRelease(kSecAttrService)];
    }
    
    self.myCw.devCredential = uuid;
    
    //[self.cwMgr stopScan];
    [self.cwMgr connectCwCard:self.myCw];
}

- (void)PushCwSegue:(NSString *)identifier //index:(NSIndexPath *)indexPath
{
    NSLog(@"PushCwSegue = %@",segueIdentifier);
    
    [self performSegueWithIdentifier:identifier sender:self];
    
    //[self tableView:self.tablev_cwlist accessoryButtonTappedForRowWithIndexPath:indexPath];
}

#pragma mark - TableView Delegates

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    self.cellIndex = indexPath;
    
    self.myCw = [self.cwCards objectAtIndex:indexPath.row];
    
    [self.tablev_cwlist reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == self.cellIndex.row) return 110;
    else return 70;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"accessoryButtonTappedForRowWithIndexPath");
    
    [self.tablev_cwlist reloadData];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSLog(@"prepareForSegue");
    if([[segue identifier] isEqualToString:@"CwInfoSegue"]) {
        CwInfoViewController *vc = [segue destinationViewController];
        vc.cwCard = self.myCw;
    }else if([[segue identifier] isEqualToString:@"CwResetSegue"]) {
        NSLog(@"CwResetSegue");
        //CwInfoViewController *vc = [segue destinationViewController];
    }else if([[segue identifier] isEqualToString:@"CwRegisterHostSegue"]) {
        NSLog(@"CwRegisterHostSegue");
        //CwInfoViewController *vc = [segue destinationViewController];
    }
}

#pragma mark - CwManager Delegate
/*
-(void) didCwManagerReady;
{
    [self.cwMgr scanCwCards];
}*/

-(void) didScanCwCards: (NSMutableArray *) cwCards
{
    BOOL shouldReload = NO;
    if (cwCards.count != self.cwCards.count) {
        shouldReload = YES;
    } else {
        for (CwCard *card in cwCards) {
            if ([card.peripheral.name isEqualToString:@"CoolWallet "]) {
                continue;
            }
            
            NSArray *searchResult = [self.cwCards filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.peripheral.name == %@", card.peripheral.name]];
            if (searchResult.count <= 0) {
                shouldReload = YES;
                break;
            }
        }
        
        if (!shouldReload) {
            for (CwCard *card in self.cwCards) {
                NSArray *searchResult = [cwCards filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.peripheral.name == %@", card.peripheral.name]];
                if (searchResult.count <= 0) {
                    [self.cwCards removeObject:card];
                    shouldReload = YES;
                }
            }
        }
    }
    
    if (shouldReload) {
        self.cwCards = [NSMutableArray arrayWithArray:cwCards];
        
        self.view_connecting.hidden = YES;
        self.tablev_cwlist.hidden = NO;
        
        [self.tablev_cwlist reloadData];
    }
}

-(void) didConnectCwCard:(CwCard *)cwCard
{
    NSLog(@"table didConnectCwCard");
    [self performDismiss];
    [self PushCwSegue:segueIdentifier];
}

-(void) didDisconnectCwCard: (CwCard *) cwCard
{
    [self performDismiss];
    //Add a notification to the system
//    UILocalNotification *notify = [[UILocalNotification alloc] init];
//    notify.alertBody = [NSString stringWithFormat:@"CW Disconnected"];
//    notify.soundName = UILocalNotificationDefaultSoundName;
//    notify.applicationIconBadgeNumber=1;
//    [[UIApplication sharedApplication] presentLocalNotificationNow: notify];
    
    self.cwCards = nil;
    [self.tablev_cwlist reloadData];
    [self.cwMgr scanCwCards];
}

#pragma mark - CwCard Delegate
-(void) didPrepareService
{
    NSLog(@"didPrepareService");
}

-(void) didGetModeState
{
    //self.lblMode.text = [@(self.cwCard.mode) stringValue];
    //self.lblState.text = [@(self.cwCard.state) stringValue];
    NSLog(@"mode = %@",self.myCw.mode);
    [self.tablev_cwlist reloadData];

}

- (void) showIndicatorView:(NSString *)Msg {
    mHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:mHUD];
    
    mHUD.dimBackground = YES;
    mHUD.labelText = Msg;
    
    [mHUD show:YES];
}

- (void) performDismiss
{
    if(mHUD != nil) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }
}
@end
