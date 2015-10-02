//
//  UIViewController+TabCreateWalletSelectViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/8/31.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabCreateWalletSelectViewController.h"

@implementation TabCreateWalletSelectViewController
{
    NSArray *menuItems;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    menuItems = @[@"CreateNewWallet", @"RecoverOldWallet"];
    
    //find CW via BLE
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    NSLog(@"row select = %d",indexPath.row);
    //if(indexPath.row == 0) [self performSegueWithIdentifier:@"SettingBitcoinUnit" sender:self];
}

@end
