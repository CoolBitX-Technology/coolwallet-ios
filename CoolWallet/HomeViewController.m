//
//  UIViewController+HomeViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2014/10/16.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import "HomeViewController.h"
#import "WalletTableCell.h"
#import "OCAppCommon.h"

@interface HomeViewController ()

@end

@implementation HomeViewController : UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Home", nil);
    //self.navigationItem.titleView.backgroundColor = [UIColor blueColor];
    
    SWRevealViewController *revealController = [self revealViewController];
    
    //[revealController panGestureRecognizer];
    //[revealController tapGestureRecognizer];
    
     UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home-icon"]
     style:UIBarButtonItemStyleBordered target:nil action:@selector(revealToggle:)];
     
     self.navigationItem.leftBarButtonItem = revealButtonItem;
     
    
     UIBarButtonItem *rightRevealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu-icon"]
     style:UIBarButtonItemStyleBordered target:revealController action:@selector(rightRevealToggle:)];
     
     self.navigationItem.rightBarButtonItem = rightRevealButtonItem;
    
    self.WalletTableView.delegate = self;
    self.WalletTableView.dataSource = self;
    
    NSInteger Mode = [[NSUserDefaults standardUserDefaults]integerForKey:@"AccountMode"];
    
    if(Mode == 1) {
        
    }else{
        
    }
     
}

#pragma marl - UITableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //return 1;
    return [[[OCAppCommon getInstance] WalletArray] count];
    //return [MenuArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"WalletTableCell";
    WalletTableCell *cell = (WalletTableCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //WalletTableCell *cell = [[[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil] objectAtIndex:0];
    if (!cell)
    {
        cell = [[[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil] objectAtIndex:0];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    //NSString *number = [NSString stringWithFormat:@"%d", indexPath.row+1];
    //[cell.ContentView setFrame:CGRectMake(0, 110, 300, 500)];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Grab a handle to the reveal controller, as if you'd do with a navigtion controller via self.navigationController.
    SWRevealViewController *revealController = self.revealViewController;
    
    // selecting row
    NSInteger row = indexPath.row;
    
    // if we are trying to push the same row or perform an operation that does not imply frontViewController replacement
    // we'll just set position and return

    // otherwise we'll create a new frontViewController and push it with animation
    
    UIViewController *newFrontController = nil;
    
    if (row == 0)
    {
        NSLog(@"row = 0");
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Wallet" bundle:nil];
        //[self presentViewController:[storyboard instantiateViewControllerWithIdentifier:@"TestViewController"] animated:YES completion:nil];
        newFrontController = [storyboard instantiateInitialViewController];
    }
    /*
    else if(row == 1){
        //newFrontController = [[QRcodeScanViewContoller alloc] init];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"NewWallet" bundle:nil];
        //[self presentViewController:[storyboard instantiateViewControllerWithIdentifier:@"TestViewController"] animated:YES completion:nil];
        newFrontController = [storyboard instantiateInitialViewController];
        
        //[revealController presentViewController:[storyboard instantiateInitialViewController] animated:YES completion:nil];
    }
    else if(row == 2){
        //newFrontController = [[MyNumberViewController alloc] init];
    }
    else if (row == 3)
    {
        //newFrontController = [[MapViewController alloc] init];
    }*/
    
    if(newFrontController != nil) {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:newFrontController];
        [revealController pushFrontViewController:navigationController animated:YES];
    }
    _presentedRow = row;  // <- store the presented row
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    return @"";
}


@end
