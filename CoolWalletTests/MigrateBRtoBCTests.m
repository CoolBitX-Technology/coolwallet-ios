//
//  MigrateBRtoBCTests.m
//  CoolWallet
//
//  Created by Monroe Chiang on 2017/7/31.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

//
//  
//

#import <XCTest/XCTest.h>
#import "CwBtcNetWork.h"

#import "CwUnspentTxIndex.h"
#import "NSString+HexToData.h"

@interface MigrateBRtoBCTests : XCTestCase
{
    CwBtcNetWork *network;
    CwAddress *cwAddress;
    
    BOOL isBlockChain;
}
@end

@implementation MigrateBRtoBCTests

- (void)setUp {
    [super setUp];
    
    isBlockChain = YES;
    
    network = [CwBtcNetWork new];
    cwAddress = [CwAddress new];
    
    if (!isBlockChain) {
    cwAddress.address = @"18NZvKMrjHREtW3aqUDDNL1bvKP2xfx3aS";
    return;
    }
    cwAddress.address = @"1Gp7iCzDGMZiV55Kt8uKsux6VyoHe1aJaN";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Test Case

- (void)testUnspent {
    NSMutableArray *addrUnspentTxs;
    GetUnspentTxsByAddrErr error = [self getUnspentTxsByAddr:cwAddress.address unspentTxs:&addrUnspentTxs];
    XCTAssert(error == GETUNSPENTTXSBYADDR_BASE);
}

- (void)testExchangeRate {
}

- (void)testURLFormate {
    NSString *serverSite;
    NSString *unspentTxsURLStr;
    serverSite  = @"https://blockchain.info/";
    unspentTxsURLStr  = @"unspent?active=";
    
    NSString *urlA = @"https://blockchain.info/unspent?active=1Gp7iCzDGMZiV55Kt8uKsux6VyoHe1aJaN";
    NSString *urlB = [self urlOfUnspent: serverSite apiName: unspentTxsURLStr address: cwAddress.address];
    XCTAssertTrue([urlA isEqualToString:urlB]);
}

#pragma mark - 需要進行置換的方法

- (GetUnspentTxsByAddrErr) getUnspentTxsByAddr:(NSString*)addr unspentTxs:(NSMutableArray**)unspentTxs
{
    NSError *errorForAPIInvoke;
    NSURLResponse *responseOfAPIInvoke = nil;
    
    NSString *serverSite;
    NSString *unspentTxsURLStr;
    serverSite  = @"https://btc.blockr.io/api/v1";
    unspentTxsURLStr  = @"address/unspent";
    
    if (isBlockChain) {
    serverSite  = @"https://blockchain.info/";
    unspentTxsURLStr  = @"unspent?active=";
    }
    
    NSString *urlOfUnspent = [self urlOfUnspent:serverSite apiName:unspentTxsURLStr address:addr];
    NSData *dataOfAPIResponse = [self HTTPRequestUsingGETMethodFrom: urlOfUnspent
                                                                err: &errorForAPIInvoke
                                                           response: &responseOfAPIInvoke];
    
    GetUnspentTxsByAddrErr errorForUnspentTxsByAddr = GETUNSPENTTXSBYADDR_BASE;
    
    if(errorForAPIInvoke)
    {
        errorForUnspentTxsByAddr = GETUNSPENTTXSBYADDR_NETWORK;
    }
    else
    {
        NSDictionary *responseBodyInJSON = [NSJSONSerialization JSONObjectWithData: dataOfAPIResponse
                                                                           options: 0
                                                                             error: &errorForAPIInvoke];
        
        if(![self isResponseValidForError: errorForAPIInvoke andBody: responseBodyInJSON])
        {
            errorForUnspentTxsByAddr = GETUNSPENTTXSBYADDR_JSON;
            NSLog(@"unspent error: %@", responseBodyInJSON);
        }
        else
        {
            NSArray* rawUnspentTxs = [self unspentTxs: responseBodyInJSON];
            NSMutableArray *_unspentTxs = [[NSMutableArray alloc] initWithCapacity:[rawUnspentTxs count]];
            
            for (NSDictionary *rawUnspentTx in rawUnspentTxs)
            {
                CwUnspentTxIndex *unspentTx = [[CwUnspentTxIndex alloc] init];
                unspentTx.amount = [self satoshiAmounAfterParsing: rawUnspentTx];
                unspentTx.tid = [self tidAfterParsing: rawUnspentTx];
                unspentTx.scriptPub = [self scriptPubAfterParsing: rawUnspentTx];
                unspentTx.n = [self nAfterParsing:rawUnspentTx];
                unspentTx.confirmations = [self confirmationsAfterParsing: rawUnspentTx];
                
                [_unspentTxs addObject:unspentTx];
                
                NSLog(@">>>>>> tid:%@ n:%lu amount:%@", unspentTx.tid, (unsigned long)unspentTx.n, unspentTx.amount.satoshi);
            }
            *unspentTxs = _unspentTxs;
        }
    }
    
    return errorForUnspentTxsByAddr;
}

- (NSDictionary *) getCurrRate
{
    GetCurrErr err = GETCURR_BASE;
    
    NSError *_err = nil;
    
    NSString *stringURL = [NSString stringWithFormat:@"%@/%@/",serverSite,currencyURLStr];
    NSURL *url = [NSURL URLWithString:stringURL];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    if(data)
    {
        NSDictionary *JSON =[NSJSONSerialization JSONObjectWithData:data options:0 error:&_err];
        if(_err || ![@"success" isEqualToString:JSON[@"status"]] || !(JSON[@"data"][0][@"rates"]))
        {
            err = CETCURR_JSON;
        }
        else
        {
            err = GETCURR_BASE;
            NSMutableDictionary *rates = [JSON[@"data"][0][@"rates"] mutableCopy];
            
            //get BTC to USD rate
            NSNumber *btcRate = [rates objectForKey:@"BTC"];
            
            [rates removeObjectForKey:@"BTC"];
            
            [rates enumerateKeysAndObjectsUsingBlock: ^(id currId, id currRate, BOOL *stop) {
                currRate = [NSNumber numberWithFloat: (((NSNumber *)currRate).floatValue/((NSNumber *)btcRate).floatValue)];
                [rates setObject:currRate forKey:currId];
            }];
            
            /*
             for (NSString* currId in rates) {
             NSNumber *currRate = [rates objectForKey:currId];
             
             //calculate the rate against BTC
             currRate =[NSNumber numberWithFloat: (currRate.floatValue/btcRate.floatValue)];
             
             [rates setObject:currRate forKey:currId];
             }*/
            
            return rates;
        }
    }
    else
    {
        err = GETCURR_NETWORK;
    }
    
    return nil;
}

#pragma mark - 輔助方法

- (NSNumber *) confirmationsAfterParsing: (NSDictionary *)rawUnspentTx
{
    return [NSNumber numberWithInteger:[[rawUnspentTx objectForKey:@"confirmations"] unsignedIntegerValue]];
}

- (NSUInteger) nAfterParsing: (NSDictionary *)rawUnspentTx {
    if (!isBlockChain) {
    return [rawUnspentTx[@"n"] unsignedIntegerValue];
    }
    
    /* for BlockChain.info */
    return [rawUnspentTx[@"tx_output_n"] unsignedIntegerValue];
}

- (NSData *)scriptPubAfterParsing: (NSDictionary *)rawUnspentTx {
    return [NSString hexstringToData:rawUnspentTx[@"script"]];
}

- (CwBtc *)satoshiAmounAfterParsing:(NSDictionary *)rawUnspentTx {
    
    if (!isBlockChain) {
    double amountValue = [rawUnspentTx[@"amount"] doubleValue];
    int64_t amountNum = (int64_t)(amountValue * 1e8 + (amountValue < 0.0 ? -.5:.5));
    return [CwBtc BTCWithSatoshi: [NSNumber numberWithLongLong:amountNum]];
    }

    /* for BlockChain.info */
    int64_t amountNum = (int64_t)[rawUnspentTx[@"value"] doubleValue];
    return [CwBtc BTCWithSatoshi: [NSNumber numberWithLongLong:amountNum]];
}

- (NSData *)tidAfterParsing:(NSDictionary *)rawUnspentTx {
    if (!isBlockChain) {
    NSData *tid = [NSString hexstringToData:rawUnspentTx[@"tx"]];
    return [NSData dataWithData:tid];
    }
    
    /* for BlockChain.info */
    return [NSString hexstringToData:rawUnspentTx[@"tx_hash_big_endian"]];
}

- (NSString *) urlOfUnspent:(NSString *)serverSite apiName:(NSString *)unspentTxsURLStr address:(NSString *) addr {
    if (!isBlockChain) {
    return [NSString stringWithFormat:@"%@/%@/%@?unconfirmed=1", serverSite, unspentTxsURLStr, addr];
    }
    
    /* for BlockChain.info */
    return [NSString stringWithFormat:@"%@%@%@", serverSite, unspentTxsURLStr, addr];
}

- (BOOL) isResponseValidForError:(NSError *)errorForAPIInvoke andBody:(NSDictionary *)responseBodyInJSON {
    if (!isBlockChain) {
    return (!errorForAPIInvoke &&
            [self isResponseOK: responseBodyInJSON] &&
            responseBodyInJSON[@"data"] &&
            [self unspentTxs: responseBodyInJSON]);
    }
    
    /* for BlockChain.info */
    return [self isResponseOK: responseBodyInJSON];
}

- (BOOL) isResponseOK:(NSDictionary *)responseBodyInJSON {
    if (!isBlockChain) {
    return [@"success" isEqualToString: responseBodyInJSON[@"status"]];
    }
    
    /* for BlockChain.info */
    NSString *rootKeyInUnspentResponseJSON = @"unspent_outputs";
    return ([responseBodyInJSON[rootKeyInUnspentResponseJSON] count] > 0);
}

- (NSArray *) unspentTxs:(NSDictionary *)responseBodyInJSON {
    if (!isBlockChain) {
    return responseBodyInJSON[@"data"][@"unspent"];
    }
    
    /* for BlockChain.info */
    NSString *rootKeyInUnspentResponseJSON = @"unspent_outputs";
    return responseBodyInJSON[rootKeyInUnspentResponseJSON];
}

#pragma mark - Internal Functions (CwBtcNetwork.m)

- (NSData*) HTTPRequestUsingGETMethodFrom:(NSString*)urlStr err:(NSError**)_err response:(NSURLResponse**)_response
{
    NSURL *url = [[NSURL alloc]initWithString:urlStr];
    NSMutableURLRequest *httpRequest = [[NSMutableURLRequest alloc]init];
    
    [httpRequest setURL:url];
    [httpRequest setHTTPMethod:@"GET"];
    [httpRequest setHTTPBody:nil];
    
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:httpRequest];
    NSData *data = [NSURLConnection sendSynchronousRequest:httpRequest returningResponse:_response error:_err];
    
    return data;
}

@end
