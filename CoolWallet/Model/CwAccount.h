//
//  CwAccount.h
//  CwTest
//
//  Created by CP Hsiao on 2014/12/16.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CwAccountError.h"
#import "CwBtc.h"
#import "CwTx.h"
#import "CwKeyChain.h"

typedef NS_ENUM (NSInteger, CwAccountStatus) {
    CwAccountStatusInactive = 0x00,
    CwAccountStatusActive = 0x01
};

@interface CwAccount : NSObject <NSCoding>

@property NSInteger accId;
@property NSString *accName;
@property long long balance; //shatoshi (sum of address balance)
@property long long blockAmount; //blocked by Exchange Site
@property NSInteger extKeyPointer;
@property NSInteger intKeyPointer;

@property int64_t tempUnblockAmount; //Exchange Site order block amount, not really unblock

@property NSMutableArray *extKeys;
@property NSMutableArray *intKeys;

@property CwKeychain *externalKeychain;
@property CwKeychain *internalKeychain;

@property NSMutableDictionary *transactions;         // CWTx[]
@property NSMutableArray *unspentTxs;       // CWUnspentTxIndex[]

@property BOOL infoSynced;
@property NSDate *lastUpdate;

-(BOOL) isTransactionSyncing;
-(BOOL) isAllAddressSynced;
-(void) updateFromBlockChainAddrData:(NSDictionary *)data;

- (GenTxErr) genUnsignedTxToAddrByAutoCoinSelection:(NSString*)destAddr change: (NSString*)changeAddr amount:(CwBtc*)amount unsignedTx:(CwTx**)unsignedTx fee:(CwBtc**)fee;
- (NSMutableArray*) genHashesOfTxCopy:(CwTx*)unsignedTx;
- (GenScriptSigErr) genScriptSig:(NSData*)sig pubKey:(NSData*)pubKey scriptSig:(NSData**)scriptSig;
- (GenRawTxDataErr) genRawTxData:(CwTx*)tx scriptSigs:(NSArray*)scriptSigs;
-(NSMutableArray *) getAllAddresses;

@end
