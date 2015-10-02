//
//  UIViewController+TabSettingBitcoinUnitViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/7/2.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabSettingBitcoinUnitViewController.h"
#import "OCAppCommon.h"

@implementation TabSettingBitcoinUnitViewController
{
    NSArray *menuItems;
}

CwManager *cwManager;
CwCard *cwCard;

- (void)viewDidLoad {
    [super viewDidLoad];
    for(UIView* view in self.navigationController.navigationBar.subviews)
    {
        if(view.tag == 9 || view.tag == 99)
        {
            [view removeFromSuperview];
        }
    }
    
    // Do any additional setup after loading the view.
    menuItems = @[@"BTC", @"mBTC",@"µBTC"];
    
    //find CW via BLE
    cwManager = [CwManager sharedManager];
    cwManager.delegate=self;
    
    //self.actBusyIndicator.hidden = YES;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    cwManager.connectedCwCard.delegate = self;
    
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
    
    NSString *unit = [[OCAppCommon getInstance] BitcoinUnit];
    if([unit compare:@"BTC"] == 0){
        if(indexPath.row == 0) cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else cell.accessoryType = UITableViewCellAccessoryNone;
    }else if([unit compare:@"mBTC"] == 0){
        if(indexPath.row == 1) cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else cell.accessoryType = UITableViewCellAccessoryNone;
    }else if([unit compare:@"µBTC"] == 0){
        if(indexPath.row == 2) cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

#pragma mark - TableView Delegates

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSLog(@"row select = %d",indexPath.row);
    if(indexPath.row == 0) {
        [[OCAppCommon getInstance] setBitcoinUnit:@"BTC"];
    }else if(indexPath.row == 1) {
        [[OCAppCommon getInstance] setBitcoinUnit:@"mBTC"];
    }else if(indexPath.row == 2) {
        [[OCAppCommon getInstance] setBitcoinUnit:@"µBTC"];
    }
    
    NSUserDefaults *profile = [NSUserDefaults standardUserDefaults];
    [profile setObject:[[OCAppCommon getInstance] BitcoinUnit] forKey:@"BitcoinUnit"];
    
    [tableView reloadData];
    //if(indexPath.row == 0) [self performSegueWithIdentifier:@"SettingBitcoinUnit" sender:self];
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
