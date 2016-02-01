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
#import "ExOrderDetailViewController.h"
#import "CwExchange.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

#define ExPlaceOrderURL @"http://xsm.coolbitx.com:8080/signup"

@interface ExMatchedOrderViewController() <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) ExMatchOrderVM *vm;
@property (assign, nonatomic) BOOL hasMatchedOrders;
@property (strong, nonatomic) CwExOrderBase *selectOrder;

@property (weak, nonatomic) IBOutlet UIView *noOrderView;
@property (weak, nonatomic) IBOutlet UIView *matchedOrderView;
@property (weak, nonatomic) IBOutlet UITableView *tableViewSell;
@property (weak, nonatomic) IBOutlet UITableView *tableViewBuy;

@end

@implementation ExMatchedOrderViewController

-(void) viewDidLoad
{    
    self.vm = [ExMatchOrderVM new];
    [self.vm requestMatchedOrders];
    
    RAC(self, hasMatchedOrders) = [RACSignal combineLatest:@[RACObserve(self.vm, matchedSellOrders), RACObserve(self.vm, matchedBuyOrders)] reduce:^NSNumber *(NSArray *sellOrders, NSArray *buyOrders) {
        BOOL enabled = NO;
        if (sellOrders != nil && buyOrders != nil) {
            enabled = sellOrders.count > 0 || buyOrders.count > 0;
        }
        
        return @(enabled);
    }];
    
    [self addObservers];
}

-(void) viewWillDisappear:(BOOL)animated
{
    self.selectOrder = nil;
}

-(void) addObservers
{
    @weakify(self)
    CwExchange *exchange = [CwExchange sharedInstance];
    if (!exchange.cardInfoSynced) {
        [self showIndicatorView:@"Sync card info"];
        [[[RACObserve(exchange, cardInfoSynced) filter:^BOOL(NSNumber *synced) {
            return synced.boolValue;
        }] subscribeOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSNumber *synced) {
            [self performDismiss];
        }];
    }
    
    [[RACObserve(self, hasMatchedOrders) filter:^BOOL(id value) {
        @strongify(self)
        return self.vm.matchedSellOrders != nil && self.vm.matchedBuyOrders != nil;
    }] subscribeNext:^(id has) {
        @strongify(self)
        if (has) {
            self.noOrderView.hidden = YES;
            self.matchedOrderView.hidden = NO;
        } else {
            self.noOrderView.hidden = NO;
            self.matchedOrderView.hidden = YES;
        }
    }];
    
    [[RACObserve(self.vm, matchedSellOrders) filter:^BOOL(id value) {
        return value != nil;
    }] subscribeNext:^(id value) {
        @strongify(self)
        [self.tableViewSell reloadData];
    }];
    
    [[RACObserve(self.vm, matchedBuyOrders) filter:^BOOL(id value) {
        return value != nil;
    }] subscribeNext:^(id value) {
        @strongify(self)
        [self.tableViewBuy reloadData];
    }];
}

- (IBAction)placeOrder:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ExPlaceOrderURL]];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectOrder = nil;
    if ([tableView isEqual:self.tableViewSell]) {
        self.selectOrder = [self.vm.matchedSellOrders objectAtIndex:indexPath.row];
    } else if ([tableView isEqual:self.tableViewBuy]) {
        self.selectOrder = [self.vm.matchedBuyOrders objectAtIndex:indexPath.row];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    [self performSegueWithIdentifier:@"ExOrderDetailSegue" sender:self];
}

-(BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"ExOrderDetailSegue"]) {
        return self.selectOrder != nil;
    }
    
    return YES;
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ExOrderDetailSegue"]) {
        ExOrderDetailViewController *targetController = (ExOrderDetailViewController *)[segue destinationViewController];
        targetController.order = self.selectOrder;
    }
}

@end
