//
//  ExMatchedOrderViewController.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/27.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "ExMatchedOrderViewController.h"
#import "ExMatchOrderVM.h"
#import "ExOrderCell.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface ExMatchedOrderViewController() <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) ExMatchOrderVM *vm;
@property (weak, nonatomic) IBOutlet UITableView *tableViewSell;
@property (weak, nonatomic) IBOutlet UITableView *tableViewBuy;

@end

@implementation ExMatchedOrderViewController

-(void) viewDidLoad
{
    UIImage* myImage = [UIImage imageNamed:@"ex_icon.png"];
    UIImageView* myImageView = [[UIImageView alloc] initWithImage:myImage];
    
    float x = self.navigationController.navigationBar.frame.size.width/2 - 80;
    myImageView.frame = CGRectMake(x, 8, 30, 30);
    [self.navigationController.navigationBar addSubview:myImageView];
    
    self.vm = [ExMatchOrderVM new];
    [self.vm requestMatchedOrders];
    
    @weakify(self)
    [[RACObserve(self.vm, matchedSellOrders) filter:^BOOL(id value) {
        return value != nil;
    }] subscribeNext:^(id value) {
        NSLog(@"matchedSellOrders: %@", value);
        @strongify(self)
        [self.tableViewSell reloadData];
    }];
    
    [[RACObserve(self.vm, matchedBuyOrders) filter:^BOOL(id value) {
        return value != nil;
    }] subscribeNext:^(id value) {
        NSLog(@"matchedBuyOrders: %@", value);
        @strongify(self)
        [self.tableViewBuy reloadData];
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ExOrderCell *cell = (ExOrderCell *)[tableView dequeueReusableCellWithIdentifier:@"OrderCell"];

    if ([tableView isEqual:self.tableViewSell]) {
        [cell setOrder:[self.vm.matchedSellOrders objectAtIndex:indexPath.row]];
    } else if ([tableView isEqual:self.tableViewBuy]) {
        [cell setOrder:[self.vm.matchedBuyOrders objectAtIndex:indexPath.row]];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:self.tableViewSell]) {
        return self.vm.matchedSellOrders.count;
    } else if ([tableView isEqual:self.tableViewBuy]) {
        return self.vm.matchedBuyOrders.count;
    }
    
    return 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [tableView dequeueReusableCellWithIdentifier:@"HeaderCell"];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 22;
}

@end
