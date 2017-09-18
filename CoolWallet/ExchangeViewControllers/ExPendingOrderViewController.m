//
//  ExMatchedOrderViewController.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/27.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "ExPendingOrderViewController.h"
#import "ExOrderCell.h"
#import "ExOrderDetailViewController.h"
#import "CwExchangeManager.h"
#import "CwExchange.h"
#import "CwExSellOrder.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

#define ExPlaceOrderURL @"http://xsm.coolbitx.com:8080/signup"

@interface ExPendingOrderViewController() <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) BOOL hasOpenOrders;
@property (assign, nonatomic) BOOL hasPendingOrders;
@property (strong, nonatomic) CwExOrderBase *selectOrder;
@property (strong, nonatomic) CwExchange *exchange;
@property (assign, nonatomic) CGFloat defaultOpenOrdersViewHeight;

@property (weak, nonatomic) IBOutlet UIView *openOrdersView;
@property (weak, nonatomic) IBOutlet UIView *noOrderView;
@property (weak, nonatomic) IBOutlet UIView *pendingOrderView;
@property (weak, nonatomic) IBOutlet UITableView *tableViewSell;
@property (weak, nonatomic) IBOutlet UITableView *tableViewBuy;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *openOrdersViewHeightConstraint;

@end

@implementation ExPendingOrderViewController

-(void) viewDidLoad
{
    self.defaultOpenOrdersViewHeight = self.openOrdersViewHeightConstraint.constant;
    
    self.openOrdersView.layer.borderWidth = 0.5;
    self.openOrdersView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.openOrdersView.layer.cornerRadius = 3;
    
    CwExchangeManager *exManager = [CwExchangeManager sharedInstance];
    [exManager requestPendingOrders];
    [exManager requestOpenOrders];
    
    self.exchange = exManager.exchange;
    
    @weakify(self)
    RAC(self, hasOpenOrders) = [RACObserve(self.exchange, openOrders) map:^NSNumber *(id value) {
        @strongify(self)
        BOOL enabled = self.exchange.openOrders != nil && self.exchange.openOrders.count > 0;
        
        return @(enabled);
    }];
    
    RAC(self, hasPendingOrders) = [RACSignal combineLatest:@[RACObserve(self.exchange, pendingSellOrders), RACObserve(self.exchange, pendingBuyOrders)] reduce:^NSNumber *(NSArray *sellOrders, NSArray *buyOrders) {
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
    
    [[RACObserve(self, hasOpenOrders) subscribeOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSNumber *has) {
         @strongify(self)
         self.openOrdersView.hidden = !has.boolValue;
         
         if (has.boolValue) {
             self.openOrdersViewHeightConstraint.constant = self.defaultOpenOrdersViewHeight;
         } else {
             self.openOrdersViewHeightConstraint.constant = 0;
         }
         
         [self.openOrdersView updateConstraints];
    }];
    
    [RACObserve(self, hasPendingOrders) subscribeNext:^(id has) {
         @strongify(self)
         if (has) {
             self.noOrderView.hidden = YES;
             self.pendingOrderView.hidden = NO;
         } else {
             self.noOrderView.hidden = NO;
             self.pendingOrderView.hidden = YES;
         }
    }];
    
    [[[RACObserve(self.exchange, pendingSellOrders) distinctUntilChanged]
      filter:^BOOL(id value) {
        return value != nil;
    }] subscribeNext:^(id value) {
        @strongify(self)
        [self.tableViewSell reloadData];
    }];
    
    [[[RACObserve(self.exchange, pendingBuyOrders) distinctUntilChanged]
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
        [cell setOrder:(CwExOrderBase *)[self.exchange.pendingSellOrders objectAtIndex:indexPath.row]];
    } else if ([tableView isEqual:self.tableViewBuy]) {
        [cell setOrder:(CwExOrderBase *)[self.exchange.pendingBuyOrders objectAtIndex:indexPath.row]];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:self.tableViewSell]) {
        return self.exchange.pendingSellOrders.count;
    } else if ([tableView isEqual:self.tableViewBuy]) {
        return self.exchange.pendingBuyOrders.count;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectOrder = nil;
    if ([tableView isEqual:self.tableViewSell] && indexPath.row < self.exchange.pendingSellOrders.count) {
        self.selectOrder = (CwExOrderBase *)[self.exchange.pendingSellOrders objectAtIndex:indexPath.row];
    } else if ([tableView isEqual:self.tableViewBuy] && indexPath.row < self.exchange.pendingBuyOrders.count) {
        self.selectOrder = (CwExOrderBase *)[self.exchange.pendingBuyOrders objectAtIndex:indexPath.row];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (self.selectOrder != nil) {
        [self performSegueWithIdentifier:@"ExOrderDetailSegue" sender:self];
    }
}

-(BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableViewSell) {
        return YES;
    }
    
    return NO;
}

-(NSArray<UITableViewRowAction *> *) tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *cancel = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Cancel" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        CwExSellOrder *sellOrder = [strongSelf.exchange.pendingSellOrders objectAtIndex:indexPath.row];
        
        __weak typeof(strongSelf) _weakSelf = strongSelf;
        [[CwExchangeManager sharedInstance] cancelOrderWithOrderId:sellOrder.orderId withSuccess:^{
            
        } error:^(NSError *error) {
            NSString *errorMessage = [error.userInfo objectForKey:@"error"];
            if (!errorMessage) {
                errorMessage = @"Failed to cancel order, please try again";
            }
            __strong typeof(weakSelf) strongSelf = _weakSelf;
            [strongSelf showHintAlert:nil withMessage:errorMessage withOKAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        }];
    }];
    
    return @[cancel];
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
