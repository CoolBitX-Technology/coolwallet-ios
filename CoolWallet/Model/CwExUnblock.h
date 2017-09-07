//
//  CwExUnblock.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/3/9.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CwExUnblock : NSObject

@property (strong, nonatomic) NSData *orderID;
@property (strong, nonatomic) NSData *okToken;
@property (strong, nonatomic) NSData *unblockToken;
@property (strong, nonatomic) NSData *mac;
@property (strong, nonatomic) NSData *nonce;

@end
