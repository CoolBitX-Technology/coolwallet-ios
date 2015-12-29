//
//  CwKeychain.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/12/9.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTCKeychain.h>
#import <CoreBitcoin/BTCKey.h>

typedef NS_ENUM (NSInteger, CwKeychainType) {
    CwKeyChainExternal = 0x00,
    CwKeyChainInternal = 0x01
};

@interface CwKeychain : BTCKeychain

@property (readonly) NSNumber *keyChainId;
@property (readonly) NSNumber *currentKeyIndex;

/** init keychain
 *  @param publicKey 64 bytes hex string
 *  @param chainCode 32 bytes hex string
 *  @param keychainType CwKeyChainExternal/CwKeyChainInternal
 */
- (id) initWithPublicKey:(NSString*)publicKey ChainCode:(NSString *)chainCode KeychainId:(CwKeychainType)keychainType;

-(BTCKey *) getAddressAtIndex:(int)index;
-(BTCKey *) genNextAddress;

@end
