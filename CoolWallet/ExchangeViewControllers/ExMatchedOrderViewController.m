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
//#import "QuartzCore/QuartzCore.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

#define ExPlaceOrderURL @"http://xsm.coolbitx.com:8080/signup"

@interface ExMatchedOrderViewController() <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) BOOL hasVerifyOrders;
@property (assign, nonatomic) BOOL hasMatchedOrders;
@property (strong, nonatomic) CwExOrderBase *selectOrder;
@property (strong, nonatomic) CwExchange *exchange;
@property (assign, nonatomic) CGFloat defaultUnclarifyViewHeight;

@property (weak, nonatomic) IBOutlet UIView *unclarifyOrderView;
@property (weak, nonatomic) IBOutlet UIView *noOrderView;
@property (weak, nonatomic) IBOutlet UIView *matchedOrderView;
@property (weak, nonatomic) IBOutlet UITableView *tableViewSell;
@property (weak, nonatomic) IBOutlet UITableView *tableViewBuy;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *unclarifyViewHeightConstraint;

@end

@implementation ExMatchedOrderViewController

-(void) viewDidLoad
{
    self.defaultUnclarifyViewHeight = self.unclarifyViewHeightConstraint.constant;
    
    self.unclarifyOrderView.layer.borderWidth = 0.5;
    self.unclarifyOrderView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.unclarifyOrderView.layer.cornerRadius = 3;
    
    CwExchangeManager *exManager = [CwExchangeManager sharedInstance];
    [exManager requestMatchedOrders];
    [exManager requestUnclarifyOrders];
    
    self.exchange = exManager.exchange;
    
    @weakify(self)
    RAC(self, hasVerifyOrders) = [RACObserve(self.exchange, unclarifyOrders) map:^NSNumber *(id value) {
        @strongify(self)
        BOOL enabled = self.exchange.unclarifyOrders != nil && self.exchange.unclarifyOrders.count > 0;
        
        return @(enabled);
    }];
    
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
        [self showIndicatorView:NSLocalizedString(@"Sync card info",nil)];
        [[[RACObserve(exManager, cardInfoSynced) filter:^BOOL(NSNumber *synced) {
            return synced.boolValue;
        }] subscribeOn:[RACScheduler mainThreadScheduler]]
         subscribeNext:^(NSNumber *synced) {
            [self performDismiss];
        }];
    }
    
    [[RACObserve(self, hasVerifyOrders) subscribeOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSNumber *has) {
         @strongify(self)
         self.unclarifyOrderView.hidden = !has.boolValue;
         
         if (has.boolValue) {
             self.unclarifyViewHeightConstraint.constant = self.defaultUnclarifyViewHeight;
         } else {
             self.unclarifyViewHeightConstraint.constant = 0;
         }
         
         [self.unclarifyOrderView updateConstraints];
    }];
    
    [RACObserve(self, hasMatchedOrders) subscribeNext:^(id has) {
         @strongify(self)
         if (has) {
             self.noOrderView.hidden = YES;
             self.matchedOrderView.hidden = NO;
         } else {
             self.noOrderView.hidden = NO;
             self.matchedOrderView.hidden = YES;
         }
    }];
    
    [[[RACObserve(self.exchange, matchedSellOrders) distinctUntilChanged]
      filter:^BOOL(id value) {
        return value != nil;
    }] subscribeNext:^(id value) {
        @strongify(self)
        [self.tableViewSell reloadData];
    }];
    
    [[[RACObserve(self.exchange, matchedBuyOrders) distinctUntilChanged]
      filter:^BOOL(id value) {
        return value != nil;
    }] subscribeNext:^(id value) {
        @strongify(self)
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
