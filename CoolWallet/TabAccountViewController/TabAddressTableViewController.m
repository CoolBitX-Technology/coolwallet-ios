//
//  TabAddressTableViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/29.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "TabAddressTableViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "CwAccount.h"
#import "CwAddress.h"

@interface TabAddressTableViewController () <CwManagerDelegate, CwCardDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *segAddress;


- (IBAction)segSelectAddressType:(UISegmentedControl *)sender;

@end

#pragma makrs - Internal properties
CwCard *cwCard;
CwAccount *account;

@implementation TabAddressTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //find CW via BLE
    CwManager *cwManager = [CwManager sharedManager];
    cwCard = cwManager.connectedCwCard;
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", cwCard.currentAccountId]];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void) myCustomBack {
    // Some anything you need to do before leaving
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];    

    cwCard.delegate = self;
    
    [cwCard getAccountAddresses: account.accId];
    
    [self segSelectAddressType: self.segAddress];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (self.segAddress.selectedSegmentIndex==0)
        return account.extKeyPointer;
    else
        return account.intKeyPointer;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddressPrototypeCell" forIndexPath:indexPath];
    
    CwAddress *addr;
    // Configure the cell...
    if (self.segAddress.selectedSegmentIndex==0) {
        addr = (CwAddress *)(account.extKeys[indexPath.row]);
    } else {
        addr = (CwAddress *)(account.intKeys[indexPath.row]);
    }
    
    cell.textLabel.text = addr.address;
    
    // m/44'/0'/0'/0/0
    cell.detailTextLabel.text = [NSString stringWithFormat: @"BIP32 Path: m/44'/0'/%ld'/%ld/%ld", (long)addr.accountId, (long)addr.keyChainId, (long)addr.keyId];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma marks - CwCardDelegate
-(void) didCwCardCommand
{
    
}

-(void) didGetAddressInfo
{
    account = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat: @"%ld", (long)account.accId]];

    [self.tableView reloadData];
}

- (IBAction)segSelectAddressType:(UISegmentedControl *)sender {
    /*
    if (sender.selectedSegmentIndex ==0) {
        //get external address;
        for (int i=0; i<account.extKeyPointer; i++) {
            [cwCard getAddressInfo:account.accId KeyChainId:CwAddressKeyChainExternal KeyId:i];
        }
    } else {
        //get internal address;
        for (int i=0; i<account.intKeyPointer; i++) {
            [cwCard getAddressInfo:account.accId KeyChainId:CwAddressKeyChainInternal KeyId:i];
        }
    }
    */
    [self.tableView reloadData];
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
