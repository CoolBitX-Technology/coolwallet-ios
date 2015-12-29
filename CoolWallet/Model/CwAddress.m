//
//  CwAddress.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/27.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "CwAddress.h"

@implementation CwAddress

-(id) init {
    if (self = [super init]) {
        self.historyUpdateFinish = YES;
        self.unspendUpdateFinish = YES;
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInteger:self.accountId forKey:@"AddrAccId"];
    [encoder encodeInteger:self.keyChainId forKey:@"AddrKcid"];
    [encoder encodeInteger:self.keyId forKey:@"AddrKid"];
    [encoder encodeObject:self.address forKey:@"AddrAddress"];
    [encoder encodeObject:self.publicKey forKey:@"AddPubKey"];
    [encoder encodeObject:self.note forKey:@"AddNote"];
    [encoder encodeObject:self.historyTrx forKey:@"AddHistoryTrx"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self.accountId = [decoder decodeIntegerForKey:@"AddrAccId"];
    self.keyChainId = [decoder decodeIntegerForKey:@"AddrKcid"];
    self.keyId = [decoder decodeIntegerForKey:@"AddrKid"];
    self.address = [decoder decodeObjectForKey:@"AddrAddress"];
    self.publicKey = [decoder decodeObjectForKey:@"AddPubKey"];
    self.note = [decoder decodeObjectForKey:@"AddNote"];
    self.historyTrx = [decoder decodeObjectForKey:@"AddHistoryTrx"];
    self.historyUpdateFinish = YES;
    self.unspendUpdateFinish = YES;
    
    return self;
}

@end
