//
//  CwExTx.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/30.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "CwExTx.h"

@interface CwExTx ()

@property (strong, nonatomic, readwrite) NSData *nonce;

@end

@implementation CwExTx

-(instancetype) initWithOrderId:(NSString *)orderId accountId:(NSNumber *)accountId
{
    self = [super init];
    
    if (self) {
        self.orderId = orderId;
        self.accountId = accountId;
    }
    
    return self;
}

-(NSData *) nonce
{
    if (!_nonce) {
        uint8_t randomBytes[16];
        int result = SecRandomCopyBytes(kSecRandomDefault, 16, randomBytes);
        
        NSMutableData *nonce;
        if (result == 0) {
            nonce = [NSMutableData dataWithBytes:&randomBytes length:sizeof(randomBytes)];
        } else {
            nonce = [NSMutableData dataWithData:self.loginHandle];
            int times = sizeof(randomBytes) / sizeof(self.loginHandle) - 1;
            int remainder = sizeof(randomBytes) % sizeof(self.loginHandle);
            for (int i = 0; i < times; i++) {
                [nonce appendData:self.loginHandle];
            }
            if (remainder > 0) {
                [nonce appendData:[self.loginHandle subdataWithRange:NSMakeRange(0, remainder)]];
            }
        }
        
        _nonce = nonce;
    }
    
    return _nonce;
}

@end
