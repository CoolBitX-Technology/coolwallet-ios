//
//  SidebarViewController.m
//  SidebarDemo
//
//  Created by Simon on 29/6/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "SidebarViewController.h"
#import "APPData.h"
#import "CwExchangeSettings.h"

@interface SidebarViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) NSArray *menuItems;
@end

@implementation SidebarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.versionLabel setText:[APPData sharedInstance].version];
    
    if (enableExchangeSite) {
        self.menuItems = @[@"title", @"HostDevices", @"CoolWalletCard", @"Security", @"Settings", @"Exchange", @"Logout"];
    } else {
        self.menuItems = @[@"title", @"HostDevices", @"CoolWalletCard", @"Security", @"Settings", @"Logout"];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static NSString *CellIdentifier = @"Cell";
    NSString *CellIdentifier = [self.menuItems objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    return cell;
}

@end
