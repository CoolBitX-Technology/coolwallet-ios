//
//  TabSettingViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/17.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "TabSettingViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "SWRevealViewController.h"

@interface TabSettingViewController ()  <CwManagerDelegate, CwCardDelegate>
@property CwManager *cwManager;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation TabSettingViewController
{
    NSArray *menuItems;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    menuItems = @[@"ResetCoolWallet", @"BitcoinUnits"];
    menuItems = @[@"ResetCoolWallet"];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //find CW via BLE
    self.cwManager = [CwManager sharedManager];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.cwManager.delegate=self;
    self.cwManager.connectedCwCard.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Configure the cell...
    NSString *CellIdentifier = [menuItems objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if(indexPath.row == 0) {
        
        //[self.navigationController.navigationBar.subviews removeFromSuperview];
        //myImageView.hidden = YES;
    }
    
    return cell;
}

#pragma mark - TableView Delegates

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSLog(@"row select = %ld",indexPath.row);
    //if(indexPath.row == 0) [self performSegueWithIdentifier:@"SettingBitcoinUnit" sender:self];
}

#pragma mark - CwCardDelegate

-(void) didCwCardCommand
{
    
}

-(void) didGetModeState
{
    NSLog(@"mode = %@", self.cwManager.connectedCwCard.mode);

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

-(void) didPersoSecurityPolicy
{
    NSLog(@"didPersoSecurityPolicy");
    /*
    [self.cwManager.connectedCwCard getModeState];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"CW Security Policy Set"
                                                   message: nil
                                                  delegate: self
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
     */
    //[self.cwManager.connectedCwCard getModeState];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
    UIViewController * vc = [sb instantiateViewControllerWithIdentifier:@"CwAccount"];
    [self.revealViewController pushFrontViewController:vc animated:YES];

}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    NSLog(@"didDisconnectCwCard");
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
