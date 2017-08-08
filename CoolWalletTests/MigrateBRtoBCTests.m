//
//  MigrateBRtoBCTests.m
//  CoolWallet
//
//  Created by Monroe Chiang on 2017/7/31.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CwBtcNetWork.h"

#import "CwUnspentTxIndex.h"
#import "NSString+HexToData.h"

// For -(NSDictionary *) queryHistoryTxs:(NSArray *)addresses
#import "NSUserDefaults+RMSaveCustomObject.h"
#import "CwTx.h"
#import "CwTxin.h"
#import "CwTxout.h"

@interface MigrateBRtoBCTests : XCTestCase
{
    CwBtcNetWork *network;
    CwAddress *cwAddress;
    
    BOOL isBlockChain;
    NSArray *queryAddresses;
}
@end

@implementation MigrateBRtoBCTests

- (void)setUp {
    [super setUp];
    
    isBlockChain = NO;
    
    network = [CwBtcNetWork new];
    cwAddress = [CwAddress new];
    
    cwAddress.address = @"1Gp7iCzDGMZiV55Kt8uKsux6VyoHe1aJaN";
    
    queryAddresses = [NSArray arrayWithObjects: @"1JXrpmxRUmdSpQGzxkmxmTfS3T5tDZi7LF", @"1M3Lwi9PCyteRgJDRZJhVBWQzdJShhVUDB", @"1Jim7VEmW149tRKiPWZDUWZdSucWS5wWBv", @"17j7uPe96AugnAShk8oYFss8GiDgqtJbSm", @"12CLhTSd6iV6K2UNctQ2B51CBwTYcLgkws", @"16qyiXi8D7dELtqtH8isvhZMYQCg4DAi8y", @"186qLTg1ABsQHxkeHnFSL9DXNrTfSapTuY", @"1B6ovUpThqahodrFR33Q8vZyw2jLhdWmX7", @"1Jvduq1NkZy1zpJvVZzchssNfLV9DEpctQ", @"1PQnd1GbEG3LWi53cjYhiP1EA53tDhiKwY", @"1AgR9WG4ydAuu4QcWBUsyKTmU49F9FcPEk", @"1CzwJhzvkyQ1d6Mo4jZTufxdhozTMcizpP", @"16HQmdb6oaajqaHSiFryRis5iz765m8Vtj", @"1CazYuLaYn8iPcyrNZuTt9wD2vNdftwqrg", @"1EfZ2tvHvzJQ7davNT4LXsfQKQvqEizxJL", @"1GiTqTRPjqxoodioQCTD1MYjF5ksLcdV92", @"12oVUPgbu5EgnrER4JVB1mcxTVhpc1Lrdx", @"15nUUswZGgVLtVbs2QrC9kfyiGiRqeAxpf", @"19Tj8jTx7MB8MS7GNWL18RS5whd6XAJdBf", @"1GbEDAQgnywniWqvwmcHJyNCMegBg4BGDB", nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Test Case

-(void)testUrlOfMultiAddressAPIOnBlockChainWithAddresses {
    NSString *serverSite;
    NSString *allTxsURLStr;
    
    serverSite        = @"https://blockchain.info/";
    allTxsURLStr      = @"rawaddr";
    
    NSArray *dummyAddresses = @[@"12", @"34"];
    NSString *result = [self urlOfMultiAddressAPIOnBlockChainWithAddresses: dummyAddresses
                                                                   andSite:serverSite
                                                                andAPIName:allTxsURLStr];
    
    XCTAssertEqualObjects(result, @"https://blockchain.info/rawaddr?active=12|34");
}

- (void)testUnspent {
    NSMutableArray *addrUnspentTxs;
    GetUnspentTxsByAddrErr error = [network getUnspentTxsByAddr:cwAddress.address unspentTxs:&addrUnspentTxs];
    XCTAssert(error == GETUNSPENTTXSBYADDR_BASE);
}

- (void)testQueryHistoryTxs {
    NSDictionary *historyTxsDic = [self queryHistoryTxs: queryAddresses];
    XCTAssertNotNil(historyTxsDic);
    XCTAssertEqual([historyTxsDic count], [queryAddresses count]);
    XCTAssertEqual([historyTxsDic count], 20);
}

-(NSString *)addressFromData:(NSDictionary *)data {
   return [data objectForKey:@"address"];
}

-(NSArray *)transcationsFromData:(NSDictionary *)data {
    return [self getAddrTxs: [[data objectForKey:@"data"] objectForKey:@"txs"]];
}

-(NSMutableDictionary *)resultFromResponse:(NSDictionary *)dic {
    
    NSMutableDictionary *result = [NSMutableDictionary new];
    
    for (NSDictionary *aData in [self convertToArray: [dic objectForKey:@"data"]]) {
        if ([[self addressFromData: aData] isEqualToString:@""]) {
            continue;
        }
        [result setObject:[self getAddrTxs: [self transcationsFromData: aData]]
                   forKey: [self addressFromData: aData]];
    }
    
    return result;
}

-(NSArray *)convertToArray:(NSObject *)obj {
    if (![obj isKindOfClass: [NSArray class]]) {
        NSMutableArray *result = [NSMutableArray new];
        [result addObject: obj];
        return result;
    }
    return (NSArray *)obj;
}

#pragma mark - 要改寫的 API
-(NSDictionary *) queryHistoryTxs:(NSArray *)addresses
{
    NSString *serverSite;
    NSString *allTxsURLStr;

    serverSite        = @"https://blockchain.info/";
    allTxsURLStr      = @"rawaddr";
    
    if (!isBlockChain) {
        serverSite        = @"https://btc.blockr.io/api/v1";
        allTxsURLStr      = @"address/txs";
    }
    
    NSString *requestUrl = [self urlOfMultiAddressAPIWithAddresses: addresses
                                                                   andSite: serverSite
                                                                andAPIName: allTxsURLStr];
    
    NSMutableDictionary *result = [NSMutableDictionary new];
    [self getRequestUrl:requestUrl params:nil success:^(NSDictionary *data) {
        
        if ([self isResponseNotOK: data]) {
            return;
        }
        [result addEntriesFromDictionary: [self resultFromResponse: data]];
        
    } failure:^(NSError *err) {
        NSLog(@"error: %@", err.description);
    }];
    
    NSDictionary *unconfirmedTxs = [self queryUnConfirmedTxs:addresses];
    for (NSString *key in unconfirmedTxs) {
        NSArray *unconfirmedTx = [unconfirmedTxs objectForKey:key];
        if (unconfirmedTx.count == 0) {
            continue;
        }
        NSMutableArray *transactionTxs = [NSMutableArray arrayWithArray:[result objectForKey:key]];
        if (transactionTxs == nil) {
            transactionTxs = [NSMutableArray new];
        }
        [transactionTxs addObjectsFromArray:unconfirmedTx];
        [result setObject:transactionTxs forKey:key];
    }
    
    return result;
}

#pragma mark -

-(NSString *)urlOfMultiAddressAPIWithAddresses:(NSArray *)addresses andSite: serverSite andAPIName: apiName
{
    return [self urlOfMultiAddressAPIOnBlockrWithAddresses: addresses andSite: serverSite andAPIName: apiName];
}

-(NSString *)urlOfMultiAddressAPIOnBlockrWithAddresses:(NSArray *)addresses andSite: serverSite andAPIName: apiName
{
    return [NSString stringWithFormat:@"%@/%@/%@", serverSite, apiName, [addresses componentsJoinedByString:@","]];
}

-(NSString *)urlOfMultiAddressAPIOnBlockChainWithAddresses:(NSArray *)addresses andSite: serverSite andAPIName: apiName
{
    return [NSString stringWithFormat:@"%@%@?active=%@", serverSite, apiName, [addresses componentsJoinedByString:@"|"]];
}

-(BOOL)isResponseNotOK:(NSDictionary *)response {
    NSNumber *code = [response objectForKey:@"code"];
    if (code.intValue != 200) {
        return YES;
    }
    return NO;
}

- (BOOL)isSingleData:(NSDictionary *) data {
    return ![[data objectForKey:@"data"] isKindOfClass:[NSArray class]];
}

#pragma mark -

-(NSDictionary *) queryUnConfirmedTxs:(NSArray *)addresses
{
    static const NSString *serverSite        = @"https://btc.blockr.io/api/v1";
    static const NSString *unconfirmTxsURLStr = @"address/unconfirmed"; //query address unconfirmed txs, get the txs detail by tx/info
    
    NSString *requestUrl = [NSString stringWithFormat:@"%@/%@/%@",serverSite,unconfirmTxsURLStr, [addresses componentsJoinedByString:@","]];
    
    NSDateFormatter *dateformat = [[NSDateFormatter alloc]init];
    [dateformat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [dateformat setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    NSMutableDictionary *result = [NSMutableDictionary new];
    [self getRequestUrl:requestUrl params:nil success:^(NSDictionary *data) {
        NSNumber *code = [data objectForKey:@"code"];
        if (code.intValue != 200) {
            NSLog(@"fail: %@, from url: %@", [data objectForKey:@"message"], requestUrl);
            return;
        }
        
        if ([[data objectForKey:@"data"] isKindOfClass:[NSArray class]]) {
            NSArray *dataList = [data objectForKey:@"data"];
            for (NSDictionary *addrData in dataList) {
                NSArray *txs = [addrData objectForKey:@"unconfirmed"];
                if (txs.count == 0) {
                    continue;
                }
                NSMutableArray *addrTxs = [self getAddrTxs:txs];
                [result setObject:addrTxs forKey:[addrData objectForKey:@"address"]];
            }
        } else {
            NSDictionary *addrData = [data objectForKey:@"data"];
            NSArray *txs = [addrData objectForKey:@"unconfirmed"];
            if (txs.count > 0) {
                NSMutableArray *addrTxs = [self getAddrTxs:txs];
                [result setObject:addrTxs forKey:[addrData objectForKey:@"address"]];
            }
        }
        
    } failure:^(NSError *err) {
        NSLog(@"error: %@", err.description);
    }];
    
    return result;
}

-(void) queryTxInfo:(NSString *)tid success:(void(^)(NSMutableArray *inputs, NSMutableArray *outputs))success fail:(void(^)(NSError *err))fail
{
    NSError *_err;
    NSURLResponse *_response;
    
    static const NSString *serverSite        = @"https://btc.blockr.io/api/v1";
    static const NSString *txInfoURLStr      = @"tx/info";         //query tx infos
    
    NSData *data = [self HTTPRequestUsingGETMethodFrom:[NSString stringWithFormat:@"%@/%@/%@", serverSite,txInfoURLStr,tid] err:&_err response:&_response];
    
    if (_err)
    {
        fail(_err);
        return;
    }
    else
    {
        NSDictionary *txDetail=[NSJSONSerialization JSONObjectWithData:data options:0 error:&_err];
        if(!(!_err && [@"success" isEqualToString:txDetail[@"status"]] && txDetail[@"data"]))
        {
            fail(_err);
            return;
        }
        else
        {
            NSArray *txIns = txDetail[@"data"][@"vins"];
            NSArray *txOuts = txDetail[@"data"][@"vouts"];
            
            NSMutableArray *inputs = [NSMutableArray new];
            NSMutableArray *outputs = [NSMutableArray new];
            
            for (NSDictionary *txIn in txIns)
            {
                NSString *address = txIn[@"address"];
                int64_t amountNum = (int64_t)([txIn[@"amount"] doubleValue] * 1e8 + ([txIn[@"amount"] doubleValue]<0.0? -.5:.5));
                CwBtc* amount = [CwBtc BTCWithSatoshi: [NSNumber numberWithLongLong:amountNum]];
                NSInteger n = [txIn[@"n"] integerValue];
                NSData* tid = [NSString hexstringToData:txIn[@"vout_tx"]];
                
                CwTxin *txin = [[CwTxin alloc] init];
                txin.tid = tid;
                txin.addr = address;
                txin.n = n;
                txin.amount = amount;
                
                [inputs addObject:txin];
            }
            
            for (NSDictionary *txOut in txOuts)
            {
                NSString *address = txOut[@"address"];
                int64_t amountNum = (int64_t)([txOut[@"amount"] doubleValue] * 1e8 + ([txOut[@"amount"] doubleValue]<0.0? -.5:.5));
                CwBtc* amount = [CwBtc BTCWithSatoshi: [NSNumber numberWithLongLong:amountNum]];
                
                NSInteger n = [txOut[@"n"] integerValue];
                BOOL isSpent = [txOut[@"is_spent"] boolValue];
                
                CwTxout *txout = [[CwTxout alloc] init];
                txout.addr = address;
                txout.amount = amount;
                txout.n = n;
                txout.isSpent = isSpent;
                
                [outputs addObject:txout];
            }
            
            success(inputs, outputs);
        }
    }
}

#pragma mark - 輔助方法

-(void) getRequestUrl:(NSString *)url params:(NSDictionary *)params success:(void(^)(NSDictionary *json))success failure:(void(^)(NSError *err))failure
{
    if (params != nil && params.count > 0) {
        NSMutableArray *paramArray = [NSMutableArray new];
        for (NSString *key in params.keyEnumerator.allObjects) {
            NSString *value = [params objectForKey:key];
            [paramArray addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
        }
        
        url = [NSString stringWithFormat:@"%@?%@", url, [paramArray componentsJoinedByString:@"&"]];
    }
    
    NSURL *requestUrl = [NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    //    NSData *data = [NSData dataWithContentsOfURL:requestUrl];
    
    NSURLResponse *_response = nil;
    NSError *_err = nil;
    NSURLRequest *request = [NSURLRequest requestWithURL:requestUrl];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&_response error:&_err];
    
    if (data) {
        NSError *error;
        NSDictionary *json =[NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if (json == nil) {
            failure(error);
        } else {
            success(json);
        }
    } else {
        failure(_err);
    }
}

-(NSMutableArray *) getAddrTxs:(NSArray *)txs
{
    NSMutableArray *addrTxs = [NSMutableArray new];
    for (NSDictionary *txData in txs) {
        CwTx *tx = [self parseAddrTxData:txData];
        if (tx == nil) {
            continue;
        }
        [addrTxs addObject:tx];
    }
    
    return addrTxs;
}

-(CwTx *) parseAddrTxData:(NSDictionary *)txData
{
    CwTx *tx = [RMMapper objectWithClass:[CwTx class] fromDictionary:txData];
    tx.txType = TypeHistoryTx;
    
    //get trxdetails
    [self performSelectorInBackground:@selector(queryTxDetail:) withObject:tx];
    
    NSLog(@"    tid:%@ amount:%@", tx.tid, tx.historyAmount.satoshi);
    
    return tx;
}

-(void) queryTxDetail:(CwTx *)tx
{
    CwTx *cachedTx = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:tx.tx];
    NSLog(@"queryTxDetail, %@, %@", tx.tx, cachedTx);
    if (cachedTx == nil || cachedTx.confirmations.intValue < 6 || cachedTx.inputs.count == 0 || cachedTx.outputs.count == 0) {
        NSString *tid = [NSString dataToHexstring:tx.tid];
        [self queryTxInfo:tid success:^(NSMutableArray *inputs, NSMutableArray *outputs) {
            [tx.inputs addObjectsFromArray:inputs];
            [tx.outputs addObjectsFromArray:outputs];
            
            [[NSUserDefaults standardUserDefaults] rm_setCustomObject:tx forKey:tx.tx];
        } fail:^(NSError *err) {
            NSLog(@"error %@ at query Tx info: %@", err, tid);
        }];
    } else {
        tx.inputs = cachedTx.inputs;
        tx.outputs = cachedTx.outputs;
        
        [[NSUserDefaults standardUserDefaults] rm_setCustomObject:tx forKey:tx.tx];
    }
}


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
