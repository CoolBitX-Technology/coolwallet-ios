//
//  ExOrderCell.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/27.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "ExOrderCell.h"
#import "CwExOrderBase.h"
#import "NSDate+Localize.h"

@interface ExOrderCell()

@property (weak, nonatomic) IBOutlet UILabel *amountBTCLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@implementation ExOrderCell

-(void) setOrder:(CwExOrderBase *)order
{
    if (order.amountBTC) {
        self.amountBTCLabel.text = [NSString stringWithFormat:@"%@", order.amountBTC];
    } else {
        self.amountBTCLabel.text = @"--";
    }
    
    if (order.price) {
        self.priceLabel.text = [NSString stringWithFormat:@"$%@", order.price];
    } else {
        self.priceLabel.text = @"--";
    }
    
    if (order.expiration) {
        self.timeLabel.text = [order.expiration exDateString];
    } else {
        self.timeLabel.text = @"--";
    }
    
}

@end
