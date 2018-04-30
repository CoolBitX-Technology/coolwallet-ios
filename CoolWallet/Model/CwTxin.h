//
//  CwTxin.h
//  CwTest
//
//  Created by LIN CHIH-HUNG on 2014/9/2.
//  Copyright (c) 2014年 LIN CHIH-HUNG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CwBtc.h"

@interface CwTxin : NSObject

@property NSData* tid; //transaction ID
@property NSUInteger n;
@property CwBtc* amount;
@property NSUInteger accId;
@property NSUInteger kcId;
@property NSUInteger kId;
@property NSString *addr;
@property NSData *pubKey;       //publickey from card
@property NSData *hashForSign;  //hash of the transaciton to be signed
@property NSData *signature;    //64bytes of signature
@property NSData *scriptPub;
@property BOOL sendToCard;      //true: sent to card, false: not send yet

@end
