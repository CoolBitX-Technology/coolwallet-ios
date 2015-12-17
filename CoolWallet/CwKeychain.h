//
//  CwKeychain.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/12/9.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, CwKeychainType) {
    CwKeyChainExternal = 0x00,
    CwKeyChainInternal = 0x01
};

@interface CwKeychain : NSObject

@property NSNumber *keyChainId;
@property NSData *publicKey;
@property NSData *chainCode;

@end
