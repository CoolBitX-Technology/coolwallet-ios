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
    self.amountBTCLabel.text = [NSString stringWithFormat:@"%@", order.amountBTC];
    self.priceLabel.text = [NSString stringWithFormat:@"$%@", @"450.45"];
    self.timeLabel.text = [order.expiration exDateString];
}

@end
