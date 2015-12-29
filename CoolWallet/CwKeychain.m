//
//  CwKeychain.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/12/9.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import "CwKeychain.h"
#import "NSString+Base58.h"

#define retry_limit 10

@interface CwKeychain()

@property (readwrite) NSNumber *keyChainId;

@property (assign, nonatomic) int keyIndex;
@property (assign, nonatomic) int retry_count;

@end

@implementation CwKeychain

- (id) initWithPublicKey:(NSString*)publicKey ChainCode:(NSString *)chainCode KeychainId:(CwKeychainType)keychainType
{
    NSString *version = @"0488B21E"; // main bitcoin net
    NSString *depth = @"00";
    NSString *fingerprint = @"00000000";
    NSString *childNumber = @"00000000";
    
    NSString *key = [publicKey substringToIndex:64];
    NSString *last = [publicKey substringWithRange:NSMakeRange(126, 2)];
    
    unsigned result = 0;
    NSScanner *scanner = [NSScanner scannerWithString:last];
    [scanner scanHexInt:&result];
    if (result % 2 == 0) {
        key = [NSString stringWithFormat:@"02%@", key];
    } else {
        key = [NSString stringWithFormat:@"03%@", key];
    }
    
    NSString *extendedKey = [[NSString stringWithFormat:@"%@%@%@%@%@%@", version, depth, fingerprint, childNumber, chainCode, key] hexToBase58check];
    
    self = [super initWithExtendedKey:extendedKey];
    self.keyChainId = [NSNumber numberWithInt:keychainType];
    self.keyIndex = -1;
    self.retry_count = 0;
    
    return self;
}

-(BTCKey *) getAddressAtIndex:(int)index
{
    if (self.retry_count >= retry_limit) {
        self.retry_count = 0;
        self.keyIndex = index;
        
        return nil;
    }
    
    BTCKey *key = [self keyAtIndex:index];
    if (key == nil) {
        self.retry_count++;
        [self getAddressAtIndex:index+1];
    }
    
    self.keyIndex = index;
    self.retry_count = 0;
    
    return key;
}

-(BTCKey *) genNextAddress
{
    return [self getAddressAtIndex:self.keyIndex+1];
}

-(NSNumber *) currentKeyIndex
{
    return [NSNumber numberWithInt:self.keyIndex];
}

@end
