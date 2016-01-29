//
//  ExOrderDetailViewController.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/28.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "BaseViewController.h"

@class CwExOrderBase;

@interface ExOrderDetailViewController : BaseViewController

@property (strong, nonatomic) CwExOrderBase *order;

@end
