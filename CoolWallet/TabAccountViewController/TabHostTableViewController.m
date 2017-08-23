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
    
    CwHost *host = [self.cwManager.connectedCwCard.cwHosts objectForKey:[NSString stringWithFormat: @"%ld", (long)indexPath.row]];
    cell.textLabel.text = [NSString stringWithFormat: @"%@", host.hostDescription];
    
    switch (host.hostBindStatus) {
        case CwHostBindStatusEmpty:
            cell.detailTextLabel.text = NSLocalizedString(@"Empty",nil);
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        case CwHostBindStatusRegistered:
            cell.detailTextLabel.text = NSLocalizedString(@"Registered",nil);
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        case CwHostBindStatusConfirmed:
            cell.detailTextLabel.text = NSLocalizedString(@"Confirmed",nil);
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
        [self showIndicatorView:NSLocalizedString(@"approving host",nil)];
        
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
            
            [self showIndicatorView:NSLocalizedString(@"deleting host",nil)];
            
            //remove hosts at index: indexPath.row
            [self.cwManager.connectedCwCard removeHost: indexPath.row];
        } else {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

#pragma marks CwCardDelegates

-(void) didGetHosts
{
    [self performDismiss];
    
    [self.tableView reloadData];
}

-(void) didApproveHost: (NSInteger) hostId
{
    [self performDismiss];
    
    [self.tableView reloadData];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Host Approved",nil)
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles: NSLocalizedString(@"OK",nil),nil];
    [alert show];
}

-(void) didRemoveHost: (NSInteger) hostId
{
    [self performDismiss];
    
    [self.tableView reloadData];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Host Removed",nil)
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles: NSLocalizedString(@"OK",nil),nil];
    [alert show];
}

@end
