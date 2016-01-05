//
//  SidebarViewController.m
//  SidebarDemo
//
//  Created by Simon on 29/6/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "SidebarViewController.h"

@interface SidebarViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) NSArray *menuItems;
@end

@implementation SidebarViewController{
    NSArray *menuItems;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [self.versionLabel setText:[NSString stringWithFormat:@"V%@", version]];
    
#if DEBUG
    [self.versionLabel setText:[NSString stringWithFormat:@"%@(%@)", self.versionLabel.text, [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
#endif
    
    menuItems = @[@"title", @"HostDevices", @"CoolWalletCard",@"Security",@"Settings",@"Logout"];
    
//    NSArray *widthConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
//                                                                        options: NSLayoutFormatDirectionLeadingToTrailing
//                                                                        metrics:nil
//                                                                          views:@{@"view" : self.versionLabel}];
//    NSArray *centerConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
//                                                                         options: NSLayoutFormatDirectionLeadingToTrailing
//                                                                         metrics:nil
//                                                                           views:@{@"view" : self.versionLabel}];
//    [self.versionLabel.superview addConstraints:widthConstraints];
//    [self.versionLabel.superview addConstraints:centerConstraints];
    
    NSLog(@"self.versionLabel.width = %f", self.versionLabel.frame.size.width);
}

-(void)viewDidLayoutSubviews
{
    NSLog(@"view.width = %f", self.view.frame.size.width);
    NSLog(@"self.versionLabel.width = %f", self.versionLabel.frame.size.width);
    NSLog(@"self.SideTableView.width = %f", self.SideTableView.frame.size.width);
    
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
    return menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static NSString *CellIdentifier = @"Cell";
    NSString *CellIdentifier = [menuItems objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    return cell;
}

@end
