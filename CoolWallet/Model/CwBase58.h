//
//  CwBase58.h
//  CwTest
//
//  Created by Coolbitx on 2015/8/30.
//  Copyright (c) 2015年 CoolBitX Technology Ltd. All rights reserved.
//

#ifndef CwTest_CwBase58_h
#define CwTest_CwBase58_h

#define BITCOIN_PUBKEY_ADDRESS      0
#define BITCOIN_SCRIPT_ADDRESS      5
#define BITCOIN_PUBKEY_ADDRESS_TEST 111
#define BITCOIN_SCRIPT_ADDRESS_TEST 196
#define BITCOIN_PRIVKEY             128
#define BITCOIN_PRIVKEY_TEST        239

#define BIP38_NOEC_PREFIX      0x0142
#define BIP38_EC_PREFIX        0x0143
#define BIP38_NOEC_FLAG        (0x80 | 0x40)
#define BIP38_COMPRESSED_FLAG  0x20
#define BIP38_LOTSEQUENCE_FLAG 0x04
#define BIP38_INVALID_FLAG     (0x10 | 0x08 | 0x02 | 0x01)

@interface CwBase58: NSObject

+ (NSString *)base58WithData:(NSData *)d;
+ (NSData *)base58ToData: (NSString *) address;
@end


#endif
