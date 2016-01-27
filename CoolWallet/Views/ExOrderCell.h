//
//  ExOrderCell.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/27.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CwExOrderBase;

@interface ExOrderCell : UITableViewCell

-(void) setOrder:(CwExOrderBase *)order;

@end
