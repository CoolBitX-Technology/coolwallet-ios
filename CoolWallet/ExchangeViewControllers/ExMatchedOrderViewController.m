//
//  ExMatchedOrderViewController.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/27.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "ExMatchedOrderViewController.h"
#import "ExOrderCell.h"
#import "ExOrderDetailViewController.h"
#import "CwExchangeManager.h"
#import "CwExchange.h"
#import "CwExSellOrder.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

#define ExPlaceOrderURL @"http://xsm.coolbitx.com:8080/signup"

@interface ExMatchedOrderViewController() <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) BOOL hasMatchedOrders;
@property (strong, nonatomic) CwExOrderBase *selectOrder;
@property (strong, nonatomic) CwExchange *exchange;

@property (weak, nonatomic) IBOutlet UIView *noOrderView;
@property (weak, nonatomic) IBOutlet UIView *matchedOrderView;
@property (weak, nonatomic) IBOutlet UITableView *tableViewSell;
@property (weak, nonatomic) IBOutlet UITableView *tableViewBuy;

@end

@implementation ExMatchedOrderViewController

-(void) viewDidLoad
{
    CwExchangeManager *exManager = [CwExchangeManager sharedInstance];
    [exManager requestMatchedOrders];
    
    self.exchange = exManager.exchange;
    
    RAC(self, hasMatchedOrders) = [RACSignal combineLatest:@[RACObserve(self.exchange, matchedSellOrders), RACObserve(self.exchange, matchedBuyOrders)] reduce:^NSNumber *(NSArray *sellOrders, NSArray *buyOrders) {
        BOOL enabled = NO;
        if (sellOrders != nil && buyOrders != nil) {
            enabled = sellOrders.count > 0 || buyOrders.count > 0;
        }
        
        return @(enabled);
    }];
    
    self.tableViewSell.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableViewBuy.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self addObservers];
}

-(void) viewWillAppear:(BOOL)animated
{
    if (self.selectOrder != nil) {
        if ([self.selectOrder isKindOfClass:[CwExSellOrder class]]) {
            [self.tableViewSell reloadData];
        }
        self.selectOrder = nil;
    }
}

-(void) addObservers
{
    @weakify(self)
    CwExchangeManager *exManager = [CwExchangeManager sharedInstance];
    if (!exManager.cardInfoSynced) {
        [self showIndicatorView:@"Sync card info"];
        [[[RACObserve(exManager, cardInfoSynced) filter:^BOOL(NSNumber *synced) {
            return synced.boolValue;
        }] subscribeOn:[RACScheduler mainThreadScheduler]]
         subscribeNext:^(NSNumber *synced) {
            [self performDismiss];
        }];
    }
    
    [[RACObserve(self, hasMatchedOrders) filter:^BOOL(id value) {
        @strongify(self)
        return self.exchange.matchedSellOrders != nil && exManager.exchange.matchedBuyOrders != nil;
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
    
    [[[RACObserve(self.exchange, matchedSellOrders) distinctUntilChanged] filter:^BOOL(id value) {
        return value != nil;
    }] subscribeNext:^(id value) {
        @strongify(self)
        NSLog(@"matchedSellOrders, %@", value);
        [self.tableViewSell reloadData];
    }];
    
    [[[RACObserve(self.exchange, matchedBuyOrders) distinctUntilChanged] filter:^BOOL(id value) {
        return value != nil;
    }] subscribeNext:^(id value) {
        @strongify(self)
        NSLog(@"matchedBuyOrders, %@", value);
        [self.tableViewBuy reloadData];
    }];
    
    [[[NSUserDefaults standardUserDefaults] rac_valuesForKeyPath:[NSString stringWithFormat:@"exchange_%@", exManager.card.cardId] observer:self]
     subscribeNext:^(CwExchange *newExchange) {
        [self.tableViewSell reloadData];
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
        [cell setOrder:[self.exchange.matchedSellOrders objectAtIndex:indexPath.row]];
    } else if ([tableView isEqual:self.tableViewBuy]) {
        [cell setOrder:[self.exchange.matchedBuyOrders objectAtIndex:indexPath.row]];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:self.tableViewSell]) {
        return self.exchange.matchedSellOrders.count;
    } else if ([tableView isEqual:self.tableViewBuy]) {
        return self.exchange.matchedBuyOrders.count;
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
    if ([tableView isEqual:self.tableViewSell] && indexPath.row < self.exchange.matchedSellOrders.count) {
        self.selectOrder = [self.exchange.matchedSellOrders objectAtIndex:indexPath.row];
    } else if ([tableView isEqual:self.tableViewBuy] && indexPath.row < self.exchange.matchedBuyOrders.count) {
        self.selectOrder = [self.exchange.matchedBuyOrders objectAtIndex:indexPath.row];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (self.selectOrder != nil) {
        [self performSegueWithIdentifier:@"ExOrderDetailSegue" sender:self];
    }
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
