//
//  ExOrderDetailViewController.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/28.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "ExOrderDetailViewController.h"
#import "CwExSellOrder.h"
#import "CwExBuyOrder.h"
#import "NSDate+Localize.h"

@interface ExOrderDetailViewController()

@property (weak, nonatomic) IBOutlet UILabel *addressTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *completeOrderBtn;

@end

@implementation ExOrderDetailViewController

-(void) viewDidLoad
{
    if ([self.order isKindOfClass:[CwExSellOrder class]]) {
        self.addressTitleLabel.text = @"Buyer's Address";
        self.completeOrderBtn.hidden = NO;
    } else {
        self.addressTitleLabel.text = @"Receive Address";
        self.completeOrderBtn.hidden = YES;
    }
    
    self.addressLabel.text = self.order.address;
    if (self.order.amountBTC) {
        self.amountLabel.text = [NSString stringWithFormat:@"%@ BTC", self.order.amountBTC];
    }
    if (self.order.price) {
        self.priceLabel.text = [NSString stringWithFormat:@"$%@", self.order.price];
    }
    self.orderNumberLabel.text = [NSString stringWithFormat:@"#%@", self.order.orderId];
    if (self.order.accountId) {
        self.accountLabel.text = [NSString stringWithFormat:@"%@", self.order.accountId];
    }
    if (self.order.expiration) {
        self.timeLabel.text = [self.order.expiration localizeDateString:@"hh:mm a MM/dd/yyyy"];
    }
}

- (IBAction)completeOrder:(UIButton *)sender {
    // prepare ex transaction & sign transaction
}

@end
