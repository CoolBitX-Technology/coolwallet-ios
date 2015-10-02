//
//  UITableViewController+TabAddressBookViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/4/29.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabAddressBookViewController.h"

@implementation TabAddressBookViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //add CW Logo
    UIImage* myImage = [UIImage imageNamed:@"addressbook.png"];
    UIImageView* myImageView = [[UIImageView alloc] initWithImage:myImage];
    
    myImageView.frame = CGRectMake(70, 5, 30, 30);
    [self.navigationController.navigationBar addSubview:myImageView];
    /*
    //change navigation bar font
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    [self.navigationController.navigationBar setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                      [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                                      shadow, NSShadowAttributeName,
                                                                      [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:21.0], NSFontAttributeName, nil]];
     */
}

@end
