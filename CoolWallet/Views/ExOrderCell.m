//
//  ExOrderCell.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/27.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "ExOrderCell.h"
#import "CwExOrderBase.h"
#import "CwExSellOrder.h"

#import "NSDate+Localize.h"
#import "UIColor+CustomColors.h"

@interface ExOrderCell()

@property (weak, nonatomic) IBOutlet UILabel *orderIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountBTCLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@implementation ExOrderCell

-(void) setOrder:(CwExOrderBase *)order
{
    if (order.orderId && self.orderIdLabel) {
        self.orderIdLabel.text = [NSString stringWithFormat:@"#%@", order.orderId];
    } else {
        self.orderIdLabel.text = @"--";
    }
    
    if (order.amountBTC && self.amountBTCLabel) {
        self.amountBTCLabel.text = [NSString stringWithFormat:@"%@", order.amountBTC];
    } else {
        self.amountBTCLabel.text = @"--";
    }
    
    if (order.price && self.priceLabel) {
        self.priceLabel.text = [NSString stringWithFormat:@"$%@", order.price];
    } else {
        self.priceLabel.text = @"--";
    }
    
    if (order.expiration && self.timeLabel) {
        self.timeLabel.text = [order.expiration exDateString];
    } else {
        self.timeLabel.text = @"--";
    }
    
    [self updateTextColor:order];
}

-(void) updateTextColor:(CwExOrderBase *)order
{
    if (![order isKindOfClass:[CwExSellOrder class]]) {
        return;
    }
    
    CwExSellOrder *sellOrder = (CwExSellOrder *)order;
    if (sellOrder.submitted && sellOrder.submitted.boolValue == YES) {
        UIColor *gold = [UIColor colorGold];
        [self.orderIdLabel setTextColor:gold];
        [self.amountBTCLabel setTextColor:gold];
        [self.priceLabel setTextColor:gold];
        [self.timeLabel setTextColor:gold];
    }
}

@end
