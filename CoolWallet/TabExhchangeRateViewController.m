//
//  UIViewController+TabExhchangeRateViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/9/1.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabExhchangeRateViewController.h"
#import "BlockChain.h"

@implementation TabExhchangeRateViewController
{
    NSDictionary *rates;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    for(UIView* view in self.navigationController.navigationBar.subviews)
    {
        if(view.tag == 9 || view.tag == 99)
        {
            [view removeFromSuperview];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self showIndicatorView:NSLocalizedString(@"Load...",nil)];
    
    [self performSelectorOnMainThread:@selector(getCurrRate) withObject:nil waitUntilDone:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) getCurrRate
{
    NSLog(@"getCurrRate");
    rates = [[BlockChain new] getCurrencyRates];
    
    [self performDismiss];
    
    //find currId from the rates
//    NSNumber *rate = [rates objectForKey:self.cwManager.connectedCwCard.currId];
    [_tableExchangeRate reloadData];
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
    return rates.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ExchangeRateCell" forIndexPath:indexPath];
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ExchangeRateCell"];
    }
    NSArray *currIds=[rates allKeys];
    
    UILabel *lblRate = (UILabel *)[cell viewWithTag:100];
    lblRate.text = [currIds objectAtIndex:indexPath.row];
    
    if(self.cwManager.connectedCwCard.currId != nil && [self.cwManager.connectedCwCard.currId compare:lblRate.text] == 0) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - TableView Delegates

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSArray *currIds=[rates allKeys];
    
    self.cwManager.connectedCwCard.currId = [currIds objectAtIndex:indexPath.row];
    
    //find currId from the rates
    NSNumber *rate = [rates objectForKey:self.cwManager.connectedCwCard.currId];
    
    if (rate==nil) {
        //use USD as default currId
        rate = [rates objectForKey:@"USD"];
    }
    
    if (rate)
    {
        self.cwManager.connectedCwCard.currRate = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%f", [rate floatValue]*100]];
        
        //[self didGetCwCurrRate];
        
        //[self btnUpdateExchangeRate: self];
    }
    /*
    NSUserDefaults *profile = [NSUserDefaults standardUserDefaults];
    [profile setObject:[[OCAppCommon getInstance] BitcoinUnit] forKey:@"BitcoinUnit"];
    */
    [tableView reloadData];
    //if(indexPath.row == 0) [self performSegueWithIdentifier:@"SettingBitcoinUnit" sender:self];
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
