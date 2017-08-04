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
    
    cwAddress.address = @"1Gp7iCzDGMZiV55Kt8uKsux6VyoHe1aJaN";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Test Case

- (void)testUnspent {
    NSMutableArray *addrUnspentTxs;
    GetUnspentTxsByAddrErr error = [network getUnspentTxsByAddr:cwAddress.address unspentTxs:&addrUnspentTxs];
    XCTAssert(error == GETUNSPENTTXSBYADDR_BASE);
}

//- (void)testURLFormate {
//    NSString *serverSite;
//    NSString *unspentTxsURLStr;
//    serverSite  = @"https://blockchain.info/";
//    unspentTxsURLStr  = @"unspent?active=";
//    
//    NSString *urlA = @"https://blockchain.info/unspent?active=1Gp7iCzDGMZiV55Kt8uKsux6VyoHe1aJaN";
//    NSString *urlB = [network urlOfUnspent: serverSite apiName: unspentTxsURLStr address: cwAddress.address];
//    XCTAssertTrue([urlA isEqualToString:urlB]);
//}

@end
