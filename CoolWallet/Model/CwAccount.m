//
//  CwAccount.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/16.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "CwAccount.h"
#import "tx.h"
#import "CwTx.h"
#import "CwTxin.h"
#import "CwTxout.h"
#import "CwUnspentTxIndex.h"
#import "CwAddress.h"

@implementation CwAccount

-(id) init {
    
    if (self = [super init]) {
        self.extKeys = [[NSMutableArray alloc] init];
        self.intKeys = [[NSMutableArray alloc] init];
        self.transactions = [[NSMutableDictionary alloc] init];
        self.unspentTxs = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInteger:self.accId forKey:@"AccId"];
    [encoder encodeObject:self.accName forKey:@"AccName"];
    [encoder encodeInt64:self.balance forKey:@"AccBalance"];
    [encoder encodeInt64:self.blockAmount forKey:@"BlockAmount"];
    
    [encoder encodeInteger:self.extKeyPointer forKey:@"ExtKeyPtr"];
    [encoder encodeInteger:self.intKeyPointer forKey:@"IntKeyPtr"];
    [encoder encodeObject:self.extKeys forKey:@"ExtKeys"];
    [encoder encodeObject:self.intKeys forKey:@"IntKeys"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self.accId = [decoder decodeIntegerForKey:@"AccId"];
    self.accName = [decoder decodeObjectForKey:@"AccName"];
    self.balance = [decoder decodeInt64ForKey:@"AccBalance"];
    self.blockAmount = [decoder decodeInt64ForKey:@"BlockAmount"];
    
    self.extKeyPointer = [decoder decodeIntegerForKey:@"ExtKeyPtr"];
    self.intKeyPointer = [decoder decodeIntegerForKey:@"IntKeyPtr"];
    self.extKeys = [decoder decodeObjectForKey:@"ExtKeys"];
    self.intKeys = [decoder decodeObjectForKey:@"IntKeys"];
    
    return self;
}

NSComparisonResult txCompare(id unspentTx1,id unspentTx2,void* context)
{
    CwBtc* amount1 = [unspentTx1 amount];
    CwBtc* amount2 = [unspentTx2 amount];
    
    if ([amount1 greater:amount2])
        return NSOrderedAscending;
    else if([amount2 greater:amount1])
        return NSOrderedDescending;
    return NSOrderedSame;
}

- (UnspentTxsSelectionErr)unspentTxsSelection:(CwBtc*)outputAmount selectedUtxs:(NSMutableArray**)selectedUtxs change:(CwBtc**)change fee:(CwBtc**)fee
{
    UnspentTxsSelectionErr err = UNSPENTTXSSELECT_BASE;
    NSArray* sortedUtxs = [_unspentTxs sortedArrayUsingFunction:txCompare context:NULL];
    NSMutableArray* _selectedUtxs = [NSMutableArray arrayWithCapacity:6];
    
    CwBtc* nTotal = [CwBtc BTCWithMBTC:[NSNumber numberWithInt:0]];
    CwBtc* _fee = [CwBtc BTCWithSatoshi:[NSNumber numberWithLongLong:FEERATE]];
    size_t blank = 1024-(34*2+10);
    
    CwBtc *unitFee = [CwBtc BTCWithSatoshi:[NSNumber numberWithLongLong:FEERATE]];
    for (CwUnspentTxIndex* utx in sortedUtxs)
    {
        if(blank >= 149)
        {
            [_selectedUtxs addObject:utx];
            nTotal = [nTotal add:[utx amount]];
            blank -= 149;
        }
        else
        {
            if([nTotal greater:[outputAmount add:_fee]])
                break;
            else
            {
                blank += 1024;
                _fee = [_fee add:unitFee];
            }
        }
    }
    
    if([[outputAmount add:_fee] greater:nTotal])
    {
        err = UNSPENTTXSSELECT_LESS;
    }
    else
    {
        *fee = _fee;
        *selectedUtxs = _selectedUtxs;
        *change = [[nTotal sub:_fee]sub:outputAmount];
        err = UNSPENTTXSSELECT_BASE;
    }
    return err;
}

- (GenTxErr) genUnsignedTxToAddrByAutoCoinSelection:(NSString*)destAddr change: (NSString*)changeAddr amount:(CwBtc*)amount unsignedTx:(CwTx**)unsignedTx fee:(CwBtc**)fee
{
    GenTxErr err = GENTX_BASE;
    CwBtc *_fee;
    CwBtc *_change;
    NSArray *_selectedUtxs;
    if([self unspentTxsSelection:amount selectedUtxs:&_selectedUtxs change:&_change fee:&_fee] != UNSPENTTXSSELECT_BASE)
    {
        err = GENTX_LESS;
    }
    else
    {
        CwTx *_unsignedTx = [[CwTx alloc]init];
        _unsignedTx.txType = TypeUnsignedTx;
        _unsignedTx.inputs = [[NSMutableArray alloc]init];
        for (CwUnspentTxIndex *utx in _selectedUtxs)
        {
            CwTxin *txin = [[CwTxin alloc]init];
            txin.accId = self.accId;
            txin.kcId = [utx kcId];
            txin.kId = [utx kId];
            txin.tid = [utx tid];
            txin.amount = [utx amount];
            txin.n = utx.n;
            txin.scriptPub = [utx scriptPub];
            
            CwAddress *addr;
            //get publickey from address
            if (txin.kcId==0) {
                //External Address
                addr = self.extKeys[txin.kId];
            } else {
                //Internal Address
                addr = self.intKeys[txin.kId];
            }
            
            txin.addr = addr.address;
            txin.pubKey = addr.publicKey;
            
            txin.hashForSign = [[NSData alloc]init]; //init the hash for further usage
            
            [_unsignedTx.inputs addObject:txin];
        }
        
        _unsignedTx.outputs = [[NSMutableArray alloc]init];
        CwTxout *txout = [[CwTxout alloc]init];
        txout.addr = destAddr;
        txout.amount = amount;
        [_unsignedTx.outputs addObject:txout];
        // Fixed address for change here!!
        if([[_change satoshi]longLongValue]!=0)
        {
            txout = [[CwTxout alloc]init];
            txout.addr = changeAddr;
            txout.amount = _change;
            [_unsignedTx.outputs addObject:txout];
        }
        
        *unsignedTx = _unsignedTx;
        *fee = _fee;
    }
    return err;
}

- (NSMutableArray*) genHashesOfTxCopy:(CwTx*)unsignedTx
{
    NSMutableArray *hashes = [NSMutableArray arrayWithCapacity:[unsignedTx.inputs count]];
    Tx *tx;
    tx = (Tx*)calloc(1,sizeof(Tx));
    tx->version = 1;
    tx->txinCnt = (unsigned int)[[unsignedTx inputs]count];
    tx->txoutCnt = (unsigned int)[[unsignedTx outputs]count];
    tx->txinList = (Txin*)calloc(tx->txinCnt, sizeof(Txin));
    tx->txoutList = (Txout*)calloc(tx->txoutCnt, sizeof(Txout));
    tx->lock = 0x00000000;
    
    for(unsigned int i=0;i<[[unsignedTx inputs]count];i++)
    {
        CwTxin* coin = [[unsignedTx inputs]objectAtIndex:i];
        tx->txinList[i].index = (unsigned int)[coin n];
        //reverse tid
        Byte *tid=(Byte *)[[coin tid]bytes];
        Byte revTid[32];
        
        for (int i=0; i<32; i++)
            revTid[i]=tid[31-i];
        memcpy(tx->txinList[i].tx, revTid,32);
        tx->txinList[i].scriptPub = (unsigned char*)[[coin scriptPub]bytes];
        tx->txinList[i].scriptPubLen = [[coin scriptPub]length];
    }
    for(unsigned int i=0;i<[[unsignedTx outputs]count];i++)
    {
        CwTxout* receiver = [[unsignedTx outputs]objectAtIndex:i];
        memcpy(tx->txoutList[i].addr,[[receiver addr]UTF8String],[[receiver addr]length]);
        tx->txoutList[i].value = [[[receiver amount]satoshi]longLongValue];
    }
    
    unsigned char hash[SHA256_DIGEST_SIZE];
    for(int i=0;i<[[unsignedTx inputs]count];i++)
    {
        txCopyHashGen(tx, i, hash);
        NSData* hashOfTxCopy = [NSData dataWithBytes:hash length:SHA256_DIGEST_SIZE];
        ((CwTxin *)(unsignedTx.inputs[i])).hashForSign = hashOfTxCopy;
        [hashes addObject:hashOfTxCopy];
    }
    
    return hashes;
}

- (GenRawTxDataErr) genRawTxData:(CwTx*)tx scriptSigs:(NSArray*)scriptSigs
{
    GenRawTxDataErr err = GENRAWTXDATA_BASE;
    if([tx txType]!=TypeUnsignedTx)
    {
        err = GENRAWTXDATA_NOTSIGNEDTX;
    }
    else
    {
        Tx *ctx = (Tx*)malloc(sizeof(Tx));
        ctx->version = 1;
        ctx->txinCnt = (unsigned int)[[tx inputs]count];
        ctx->txoutCnt = (unsigned int)[[tx outputs]count];
        ctx->lock = 0x00000000;
        ctx->txinList = (Txin*)calloc(ctx->txinCnt,sizeof(Txin));
        ctx->txoutList = (Txout*)calloc(ctx->txoutCnt, sizeof(Txout));
        
        for(int i=0;i<ctx->txinCnt;i++)
        {
            Txin *ctxin = ctx->txinList+i;
            CwTxin *txin = [[tx inputs]objectAtIndex:i];

            //reverse tid
            Byte *tid=(Byte *)[[txin tid]bytes];
            Byte revTid[32];
            
            for (int i=0; i<32; i++)
                revTid[i]=tid[31-i];

            memcpy(ctxin->tx, revTid, 32);
            
            
            ctxin->index = (unsigned int)[txin n];
            ctxin->scriptSigLen = [scriptSigs[i] length];
            ctxin->scriptSig = (unsigned char*)malloc(ctxin->scriptSigLen);
            memcpy(ctxin->scriptSig, [scriptSigs[i] bytes], ctxin->scriptSigLen);
        }
        
        for(int i=0;i<ctx->txoutCnt;i++)
        {
            Txout *ctxout = ctx->txoutList+i;
            CwTxout *txout = [[tx outputs]objectAtIndex:i];
            
            strncpy(ctxout->addr, [[txout addr]cStringUsingEncoding:NSASCIIStringEncoding], 35);
            ctxout->value = [[[txout amount]satoshi]longLongValue];
        }
        
        Byte *rawTx;
        size_t szTx = txToBytes(ctx, &rawTx);
        tx.rawTx = [[NSData alloc]initWithBytes:rawTx length:szTx];
        tx.txType = TypeSignedTx;
    }
    return err;
}


// sig(64bits) = r(32bits) || s(32bits)
// pubKey(64bits) = x(32bits) || y(32bits)
- (GenScriptSigErr) genScriptSig:(NSData*)sig pubKey:(NSData*)pubKey scriptSig:(NSData**)scriptSig
{
    NSRange first = {0,32};
    NSRange last = {32,32};
    Byte cScriptSig[256];
    Byte *pivot = cScriptSig;
    
    pivot += signatureToDER([[sig subdataWithRange:first]bytes], [[sig subdataWithRange:last]bytes], pivot);
    
    *(pivot++) = 0x21;
    *(pivot++) = ((*((Byte*)[pubKey bytes]+63)) & 0x01)==1?0x03:0x02;
    memcpy(pivot,[pubKey bytes],32);
    pivot += 32;
    
    NSData *_scriptSig = [NSData dataWithBytes:cScriptSig length:pivot-cScriptSig];
    *scriptSig = _scriptSig;
    
    return GENSCRIPTSIG_BASE;
}

-(NSMutableArray *) getAllAddresses
{
    if (self.extKeys == nil) {
        return [NSMutableArray new];
    }
    
    NSMutableArray *allAddresses = [NSMutableArray arrayWithArray:self.extKeys];
    if (self.intKeys != nil && self.intKeys.count > 0) {
        [allAddresses addObjectsFromArray:self.intKeys];
    }
    
    return allAddresses;
}

@end
