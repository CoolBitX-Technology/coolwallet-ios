//
//  TabHostTableViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/17.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "TabHostTableViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "CwHost.h"
#import "SWRevealViewController.h"

@interface TabHostTableViewController ()  <CwManagerDelegate, CwCardDelegate>
@property CwManager *cwManager;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation TabHostTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cwManager = [CwManager sharedManager];
}

- (void)goback{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.cwManager.connectedCwCard.delegate = self;

    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];

    [self.cwManager.connectedCwCard getHosts];
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
    return [self.cwManager.connectedCwCard.cwHosts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HostPrototypeCell" forIndexPath:indexPath];
    
    // Configure the cell...
    CwHost *host = [self.cwManager.connectedCwCard.cwHosts objectForKey:[NSString stringWithFormat: @"%ld", (long)indexPath.row]];
    //cell.textLabel.text = [NSString stringWithFormat: @"%ld %@", (long)indexPath.row, host.hostDescription];
    cell.textLabel.text = [NSString stringWithFormat: @"%@", host.hostDescription];
    switch (host.hostBindStatus) {
        case CwHostBindStatusEmpty:
            cell.detailTextLabel.text = @"Empty";
            break;
        case CwHostBindStatusRegistered:
            cell.detailTextLabel.text = @"Registered";
            break;
        case CwHostBindStatusConfirmed:
            cell.detailTextLabel.text = @"Confirmed";
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
    }
        
    return cell;
}

#pragma mark - TableView Delegates

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    CwHost *host = [self.cwManager.connectedCwCard.cwHosts objectForKey:[NSString stringWithFormat: @"%ld", (long)indexPath.row]];

    //filter only registered host
    if (host.hostBindStatus==CwHostBindStatusRegistered)
    {
        self.actBusyIndicator.hidden = NO;
        [self.actBusyIndicator startAnimating];
        
        //confirm the Host
        [self.cwManager.connectedCwCard approveHost: indexPath.row];
        
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CwHost *host = [self.cwManager.connectedCwCard.cwHosts objectForKey:[NSString stringWithFormat: @"%ld", (long)indexPath.row]];
    
    //filter current hostId and filter empty (0x00) host
    if (self.cwManager.connectedCwCard.hostId.integerValue != indexPath.row  && host.hostBindStatus != CwHostBindStatusEmpty) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        CwHost *host = [self.cwManager.connectedCwCard.cwHosts objectForKey:[NSString stringWithFormat: @"%ld", (long)indexPath.row]];
        
        //filter current hostId and filter empty (0x00) host
        if (self.cwManager.connectedCwCard.hostId.integerValue != indexPath.row  && host.hostBindStatus != CwHostBindStatusEmpty) {
            self.actBusyIndicator.hidden = NO;
            [self.actBusyIndicator startAnimating];
            
            //remove hosts at index: indexPath.row
            [self.cwManager.connectedCwCard removeHost: indexPath.row];
        } else {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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

#pragma marks CwCardDelegates
-(void) didCwCardCommand
{
    [self.actBusyIndicator stopAnimating];
    self.actBusyIndicator.hidden = YES;
}

-(void) didGetHosts
{
    [self.tableView reloadData];
}

-(void) didApproveHost: (NSInteger) hostId
{
    CwHost *host = [self.cwManager.connectedCwCard.cwHosts objectForKey:[NSString stringWithFormat: @"%ld", (long)hostId]];
    
    //create activity indicator on the cell
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow:hostId inSection: 0]];
    cell.textLabel.text = [NSString stringWithFormat: @"%ld %@", (long)hostId, host.hostDescription];
    
    switch (host.hostBindStatus) {
        case CwHostBindStatusEmpty:
            cell.detailTextLabel.text = @"Empty";
            break;
        case CwHostBindStatusRegistered:
            cell.detailTextLabel.text = @"Registered";
            break;
        case CwHostBindStatusConfirmed:
            cell.detailTextLabel.text = @"Confirmed";
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
    }
    
    [self.tableView reloadData];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Host Approved"
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
}


-(void) didRemoveHost: (NSInteger) hostId
{
    CwHost *host = [self.cwManager.connectedCwCard.cwHosts objectForKey:[NSString stringWithFormat: @"%ld", (long)hostId]];
    
    //create activity indicator on the cell
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow:hostId inSection: 0]];
    cell.textLabel.text = [NSString stringWithFormat: @"%ld %@", (long)hostId, host.hostDescription];
    
    switch (host.hostBindStatus) {
        case CwHostBindStatusEmpty:
            cell.detailTextLabel.text = @"Empty";
            break;
        case CwHostBindStatusRegistered:
            cell.detailTextLabel.text = @"Registered";
            break;
        case CwHostBindStatusConfirmed:
            cell.detailTextLabel.text = @"Confirmed";
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
    }
    
    [self.tableView reloadData];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Host Removed"
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
