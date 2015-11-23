//
//  CwAddress.h
//  CwTest
//
//  Created by CP Hsiao on 2014/12/27.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, CwAddressKeyChain) {
    CwAddressKeyChainExternal = 0x00,
    CwAddressKeyChainInternal = 0x01
};

typedef NS_ENUM (NSInteger, CwAddressInfo) {
    CwAddressInfoAddress = 0x00,
    CwAddressInfoPublicKey = 0x01
};

@interface CwAddress : NSObject <NSCoding>

@property NSInteger accountId;
@property NSInteger keyChainId;
@property NSInteger keyId;
@property NSString *address;
@property NSData *publicKey;
@property NSMutableArray *historyTrx;
//@property NSMutableArray *unspendTrx;
@property NSString *note; //not sync with card
@property BOOL registerNotification; //register notification of balance update

@property BOOL historyUpdateFinish;
@property BOOL unspendUpdateFinish;

@end
