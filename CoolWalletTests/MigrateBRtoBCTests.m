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
    NSString *serverSite;
    NSString *allTxsURLStr;
}
@end

@implementation MigrateBRtoBCTests

- (void)setUp {
    [super setUp];
    
    isBlockChain = YES;
    
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
    
    serverSite        = @"https://blockchain.info/";
    allTxsURLStr      = @"rawaddr";
    
    NSArray *dummyAddresses = @[@"12", @"34"];
    NSString *result = [self urlOfMultiAddressAPIWithAddresses: dummyAddresses
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
    
    serverSite        = @"https://blockchain.info/";
    allTxsURLStr      = @"multiaddr";
    
    NSDictionary *historyTxsDic = [network queryHistoryTxs: queryAddresses];
    XCTAssertNotNil(historyTxsDic);
    XCTAssertEqual([historyTxsDic count], [queryAddresses count]);
    XCTAssertEqual([historyTxsDic count], 20);
}

-(void)testDictionaryOfAddressKeyAndCwTxsArrayFromResponse
{
    NSMutableDictionary *data = [self dictionaryOfAddressKeyAndCwTxsArrayFromResponse: [self dummyResponse]];
    XCTAssert(data.count == 2);
    XCTAssertNotNil([data objectForKey: @"392wro2ENHX7CjLeocxNPUWmmPDQzS48JZ"]);
    XCTAssertNotNil([data objectForKey: @"18NZvKMrjHREtW3aqUDDNL1bvKP2xfx3aS"]);
    
    NSArray *arrayOf18NZv = [data objectForKey: @"18NZvKMrjHREtW3aqUDDNL1bvKP2xfx3aS"];
    XCTAssert([arrayOf18NZv count] == 2);
    NSArray *arrayOf392wr = [data objectForKey: @"392wro2ENHX7CjLeocxNPUWmmPDQzS48JZ"];
    XCTAssert([arrayOf392wr count] == 6);
}

#pragma mark - 以下三個方法，在 CwBtcNetwork.m 中有重複
/* 原因：不想在 .h 中 宣告下面三個方法，但是想測試它們，所以此三個方法沒有刪除。 */
-(NSString *)urlOfMultiAddressAPIWithAddresses:(NSArray *)addresses andSite: _serverSite andAPIName: _apiName
{
    return [self urlOfMultiAddressAPIOnBlockChainWithAddresses: addresses andSite: _serverSite andAPIName: _apiName];
}

-(NSString *)urlOfMultiAddressAPIOnBlockChainWithAddresses:(NSArray *)addresses andSite: _serverSite andAPIName: _apiName
{
    return [NSString stringWithFormat:@"%@%@?active=%@", _serverSite, _apiName, [addresses componentsJoinedByString:@"|"]];
}

-(NSMutableDictionary *)dictionaryOfAddressKeyAndCwTxsArrayFromResponse: (NSDictionary *)response {
    NSMutableDictionary *result =  [NSMutableDictionary new];
    
    NSArray *addresses = (NSArray *)response[@"addresses"];
    NSArray *txs = (NSArray *)response[@"txs"];
    double height = [response[@"info"][@"latest_block"][@"height"] doubleValue];

    for (NSDictionary *addressInfo in addresses) {
        NSString *address = addressInfo[@"address"];
        
        NSMutableArray *cwTxs = [NSMutableArray new];
        NSMutableArray *inputs = [NSMutableArray new];
        NSMutableArray *outs = [NSMutableArray new];
        BOOL isInTxInputs = NO;
        BOOL isInTxOut = NO;
        for (NSDictionary *tx in txs) {
            CwTx *cwTx = [CwTx new];
            cwTx.txType = TypeHistoryTx;
            cwTx.tx = tx[@"hash"];
            cwTx.txFee = [CwBtc BTCWithSatoshi: [NSNumber numberWithDouble: [tx[@"fee"] doubleValue]]];
            cwTx.historyTime_utc = [NSDate dateWithTimeIntervalSince1970: [tx[@"time"] doubleValue]];
            cwTx.amount_btc = [NSNumber numberWithDouble:[tx[@"result"] doubleValue]/100000000];
            cwTx.confirmations = [NSNumber numberWithDouble: [tx[@"block_height"] doubleValue] > 0 ? height - [tx[@"block_height"] doubleValue] + 1 : 0];
            for (int i=0; i<[(tx[@"inputs"]) count]; i++) {
                if ([address isEqualToString: tx[@"inputs"][i][@"prev_out"][@"addr"]]) {
                    isInTxInputs = YES;
                    CwTxin *cwTxin = [CwTxin new];
                    cwTxin.tid = tx[@"hash"];
                    cwTxin.addr = address;
                    cwTxin.n = (NSUInteger)tx[@"inputs"][i][@"prev_out"][@"n"];
                    cwTxin.amount = tx[@"inputs"][i][@"prev_out"][@"value"];
                    [inputs addObject: cwTxin];
                }
            }
            for (int i=0; i<[(tx[@"out"]) count]; i++) {
                if ([address isEqualToString: tx[@"out"][i][@"addr"]]) {
                    isInTxOut = YES;
                    CwTxout *cwTxout = [CwTxout new];
                    cwTxout.isSpent = [tx[@"spent"] isEqualToString:@"true"]?YES:NO;
                    cwTxout.addr = address;
                    cwTxout.n = (NSInteger)tx[@"out"][i][@"n"];
                    cwTxout.amount = tx[@"out"][i][@"value"];
                    [outs addObject: cwTxout];
                }
            }
 
            if (isInTxInputs || isInTxOut) {
                cwTx.inputs = inputs;
                cwTx.outputs = outs;
                cwTx.txFee = tx[@"fee"];
                [cwTxs addObject: cwTx];
                isInTxInputs = isInTxOut = NO;
            }
        }
        
        [result setObject:cwTxs forKey: address];
    }
    return result;
}

- (NSDictionary *)dummyResponse
{
    NSError *error;
    NSString *responseString = @"{\"recommend_include_fee\":true,\"sharedcoin_endpoint\":\"https://api.sharedcoin.com\",\"info\":{\"nconnected\":1112,\"conversion\":100000000.00000000,\"symbol_local\":{\"code\":\"USD\",\"symbol\":\"$\",\"name\":\"U.S. dollar\",\"conversion\":29558.68877657,\"symbolAppearsAfter\":false,\"local\":true},\"symbol_btc\":{\"code\":\"BTC\",\"symbol\":\"BTC\",\"name\":\"Bitcoin\",\"conversion\":100000000.00000000,\"symbolAppearsAfter\":true,\"local\":false},\"latest_block\":{\"block_index\":1612596,\"hash\":\"000000000000000000133ef385bbb882fc8ebba215e8fe0edacdcaa54cf18f8a\",\"height\":479787,\"time\":1502268054}},\"wallet\":{\"n_tx\":8,\"n_tx_filtered\":8,\"total_received\":726908,\"total_sent\":726908,\"final_balance\":0},\"addresses\":[{\"address\":\"18NZvKMrjHREtW3aqUDDNL1bvKP2xfx3aS\",\"n_tx\":2,\"total_received\":10000,\"total_sent\":10000,\"final_balance\":0,\"change_index\":0,\"account_index\":0},{\"address\":\"392wro2ENHX7CjLeocxNPUWmmPDQzS48JZ\",\"n_tx\":6,\"total_received\":716908,\"total_sent\":716908,\"final_balance\":0,\"change_index\":0,\"account_index\":0}],\"txs\":[{\"hash\":\"8c425639ce5d0a6704682f385dd4d7386a179932f0b36d9e4d0f5fe9c56654b4\",\"ver\":1,\"vin_sz\":2,\"vout_sz\":1,\"size\":338,\"fee\":343,\"relayed_by\":\"0.0.0.0\",\"lock_time\":0,\"tx_index\":271883223,\"double_spend\":false,\"result\":-10000,\"balance\":0,\"time\":1501549123,\"block_height\":478486,\"inputs\":[{\"prev_out\":{\"value\":10000,\"tx_index\":129257525,\"n\":0,\"spent\":true,\"script\":\"76a91450dd1864f8b2b379e153bda46b392871c500c59e88ac\",\"type\":0,\"addr\":\"18NZvKMrjHREtW3aqUDDNL1bvKP2xfx3aS\"},\"sequence\":4294967295,\"script\":\"47304402204d5fb79896b6b8201eecebf51311937b293cda0615304e60050b4d0bd9e14f28022007f8543e4b2e88022ea6f427ea9c12e9bea7658685c55b969389dc1dd1c65f76012103c16ea0459f2244e8faca51067c04c72558be6302ed7707f710e92f3bd3e69709\"},{\"prev_out\":{\"value\":10000,\"tx_index\":129236749,\"n\":0,\"spent\":true,\"script\":\"76a91445ebade3daba9960e0a43d083535922bd246a74288ac\",\"type\":0,\"addr\":\"17NhxX4JvNdrrXQcfwpLTFkHboGtCoja8j\"},\"sequence\":4294967295,\"script\":\"473044022046357d243f9bcb879b274df082629e241ea907e10f271df2288a55987386831902207c0f65b70f7f84a1149627e17eb25119c2288ddb376fda05b3b2b77164849dd3012102c1343dbce9023b9684dc70208980edeb2008ee7ef4e246f59b2fe6f85c5b7a45\"}],\"out\":[{\"value\":19657,\"tx_index\":271883223,\"n\":0,\"spent\":false,\"script\":\"76a914bf56d99a7cbe6681a91195899a571b8da4b1731088ac\",\"type\":0,\"addr\":\"1JSi75tj65faTRPhWBMU8tZQHxxhjoskyv\"}]},{\"hash\":\"1bb670f8cdff6a4f1e41a0fff48c1939b37e171fbbc2132125ee69361bfc2454\",\"ver\":1,\"vin_sz\":5,\"vout_sz\":2,\"size\":1547,\"fee\":283670,\"relayed_by\":\"176.9.50.168\",\"lock_time\":0,\"tx_index\":271073556,\"double_spend\":false,\"result\":-200000,\"balance\":10000,\"time\":1501230398,\"block_height\":477929,\"inputs\":[{\"prev_out\":{\"value\":100000,\"tx_index\":270918102,\"n\":141,\"spent\":true,\"script\":\"a914d9b1f0be6e8f4d1efa70f8b7cba6daecb63e93e587\",\"type\":0,\"addr\":\"3MY5igodxG6w1ggodqYHaQ75ccrb2UVixr\"},\"sequence\":4294967295,\"script\":\"00473044022001c12feb9edb4e3b4975dff5bee4e45f84ff026aba3270a5155b3faec9edca91022064a501d3d4f5be9e7a455e321d276293db5f151f81196c1bfe918170e01253700147304402206267f31eca6806baffb55809543d6137e745cbd1e267920c33be32f8a22ea48902207d248c8ad75bf13046ebec066b77763846bc2ffc2bd2140a128ed57491f2aad9014c69522102e99e5e316d67670be9fc431969afe9bf50d9d95d291afd739350d441df66defa21023a4e02f4b62571d68f09dd40d99470d4a1305e6d0f11c0388b8266eee34d91fa2102fe0e692db96d8edbdb767d94c2df77b138f9bd0119b67c18fd7775014fcb6a5753ae\"},{\"prev_out\":{\"value\":100000,\"tx_index\":270989204,\"n\":0,\"spent\":true,\"script\":\"a914f454422a4cb1ab63bb2d60caf6f90dac8e8f53a987\",\"type\":0,\"addr\":\"3PxujjLDmYrdnPCBBDP9zQDGffjtqrEXEb\"},\"sequence\":4294967295,\"script\":\"0047304402205e46c269906e336b6f5e0ddc072776670f3e38fb1280b3902f7bbb170c1aea070220711998222d0df8101161ee3779cb62f6b0828e414cfd162d76bba9b40f98ae270148304502210091ef29aeec83744d48ccab5f8c96b15942cca1f2cff4c9ab5f795881de7ed9750220082cd7ecfbb9d8098079609950e44e6e28494fceaf85a49f2046aa8fc2e7d4fe014c695221025df09c6e89c8de5f60eaca4479ede310e39f1a4b1c44610abe0e4dcc6e72a82d21035413a4b9a0b03b8c0a15a05cf2f43c45863ebf6f9f622b4fa709ae9b29ca60f82102d764e4f25e6d19041affcd188ae1677442834b8b2d03b8db3d6eb95a2531362d53ae\"},{\"prev_out\":{\"value\":200000,\"tx_index\":271023468,\"n\":0,\"spent\":true,\"script\":\"a914508dce85a2be87f95b942316d1daa108812622aa87\",\"type\":0,\"addr\":\"392wro2ENHX7CjLeocxNPUWmmPDQzS48JZ\"},\"sequence\":4294967295,\"script\":\"00473044022012affd2fa3e0e3a4712706936e5e034cfe7b22a9c257fb67ff09aa323df47326022048fd4635d886951103e87290090af2055b2ca554edd699c7c37d89e5291bef1901483045022100aacdde6eb6dae4b30105c65528cf77dea7129b74b2c888d9b89a9772a48337b1022075f9619b33f3bb2994e05f801cb4e8a4f4dad97c1b50aed50e2448352106b82b014c69522102c53f84ca8d677aa4c01fe8b904c88476fd566b13f59e5ff1d988252e9ca3a171210306d971e7f850be425dc26198e4f563b08310895e6dfb5fb060dfb788befe69ac210258a53770fa045be50fee960ad3771e44643f2d5bc10ed91456f4ada90215b2f953ae\"},{\"prev_out\":{\"value\":100000,\"tx_index\":270863140,\"n\":0,\"spent\":true,\"script\":\"a9141c630541e1ea9c9b4a0b3ca141db8d2b15f72eb987\",\"type\":0,\"addr\":\"34H7TywPAX1jMtdkoEtJ5Lx33w4drXCabQ\"},\"sequence\":4294967295,\"script\":\"004730440220113c604127515edfcb25dbdb9131bb2a0fe6ce99544d4235dc9b5c1d1c6ca56c02200b7769ab6937597504948a84662a928a2ed3ece74491f69d06289ed51c50618c01473044022059fbea80aff8d8e9ea0c12f73a837d3a18402a372b782261f48029299ee6ba0902203951d713507654a5b8f26ac7d4bf17dde66bd03535d461dc83ab7a2fcbae602e014c69522102d8aa796aec27cedb3e883f20caf5797377fe4cf55a588ec7dd6ce73bd018c7cf2103b0d232cd7d4109879f8f26532f18f0fcdf5361e0b6699e597cfb27558f2c01272103f6a1c45e47bb68d4ead5beb5cf20b78eb47233e664aa0f9b1a42c7693df3f5bb53ae\"},{\"prev_out\":{\"value\":1342457,\"tx_index\":271017219,\"n\":0,\"spent\":true,\"script\":\"a91470c129cf3bc837958aab8e7987f6af639c9281b487\",\"type\":0,\"addr\":\"3ByD1FY18Y4t9XeyosXhawudLR8Go4JTAo\"},\"sequence\":4294967295,\"script\":\"0047304402203e02fdbc629164c0f993bd9950c0a9174de277e6c3d91cec51491c3b4f48ba53022020a4717a92414a78f54cfceee2947e72456e6e204531574667d5d019fe037f270147304402202571bbe142ba9e7bef825b4fa6f303cf3f8942e9bd87d19ecc42e344e5ae05e7022041e8b333babf2c2fa577339c357f32c7228695ce757875de737557661f413e79014c69522102c819026ba8c0bfa0736c82a549526721ee97b0fa5156c1b83bb90728ba7cc62221027a3eeb491bf05629fa48024b2b05728aabec645b8027e1d26738700aa636d4a9210348be1c05815c685499529e9998638af9e44233ed22a6aabf01c834141c221a8253ae\"}],\"out\":[{\"value\":300000,\"tx_index\":271073556,\"n\":0,\"spent\":true,\"script\":\"76a91465b1a01e339ac8b031b7bb1c9d2d53a56ba7679388ac\",\"type\":0,\"addr\":\"1AGi31UmdLjjEuHob9C9qn4vwzeTUQCoKS\"},{\"value\":1258787,\"tx_index\":271073556,\"n\":1,\"spent\":true,\"script\":\"a91403b7b5b7f54f2afaf16a7e2307cd4ce93cf3522987\",\"type\":0,\"addr\":\"322g2W6w3BSEpa4qUdwapUqq4kmC4sX1oY\"}]},{\"hash\":\"8bc8d9dc9923794c6bc8e6b1fe6a06b8e1c811c1fe113ac13b815091f37e81c2\",\"ver\":1,\"vin_sz\":1,\"vout_sz\":1,\"size\":190,\"fee\":58454,\"relayed_by\":\"34.249.200.5\",\"lock_time\":0,\"tx_index\":271023468,\"double_spend\":false,\"result\":200000,\"balance\":210000,\"time\":1501209687,\"block_height\":477897,\"inputs\":[{\"prev_out\":{\"value\":258454,\"tx_index\":270306538,\"n\":1,\"spent\":true,\"script\":\"76a9149f52b42f076850fdf6c4fed45b4df63763b1c9ff88ac\",\"type\":0,\"addr\":\"1FXRWsA4L5NAfjdNShqTvPgM78jynZjJcJ\"},\"sequence\":4294967295,\"script\":\"483045022100ab4f626e0401edd16625aca85ea7e0b40778596976018f01bedfc1107985128a02207a19eba7e69b2391dea589db58f04b6e1c0261f9e7c35be173a900ce6b4c4825012103dcc12108b671aeb95ded3d53b31bee3014a58499009e7d5da1e7ff36b8539f99\"}],\"out\":[{\"value\":200000,\"tx_index\":271023468,\"n\":0,\"spent\":true,\"script\":\"a914508dce85a2be87f95b942316d1daa108812622aa87\",\"type\":0,\"addr\":\"392wro2ENHX7CjLeocxNPUWmmPDQzS48JZ\"}]},{\"hash\":\"8be5e63475ed88304d7fe526e973690b5013167763ec22887a202edbdb1ad41a\",\"ver\":1,\"vin_sz\":4,\"vout_sz\":2,\"size\":1261,\"fee\":144724,\"relayed_by\":\"5.9.139.5\",\"lock_time\":0,\"tx_index\":269060445,\"double_spend\":false,\"result\":-258454,\"balance\":10000,\"time\":1500479496,\"block_height\":476554,\"inputs\":[{\"prev_out\":{\"value\":164500,\"tx_index\":268940450,\"n\":0,\"spent\":true,\"script\":\"a9143e8ab3357445342be13bdff79b344a1f7b509bb387\",\"type\":0,\"addr\":\"37PhyV4NjEk9HYz1kwL3EiuMpuG8GsNCPL\"},\"sequence\":4294967295,\"script\":\"004730440220504d06a1f278ee94afa73e7e797527868f404a3a55c2fac0aa49c8156aad15b0022021eec050d630f2e9a05f37508ec1ce31816e03c9a3cf8f78c9a5e76e9eb330f40148304502210080750fdace6d8361e6c3417eb33d15f303b2165c805fb941c2ad6409d97a29ec02201ead582491e4e0f0ce148eadbae5fbc4a6e0a058608609d2250147d53c6ad568014c6952210368660d66cfe3c280a3ebb1526a45c99dafce9ae6b195ad83f256bf59bb170c9c2103587cf054bb78f3ff432e17918c709bd0242d6dfde42402d88c8b32b6e91a41b5210215cf17b23b71d99c8ecf1b4c13371d6b7c5c18afef0fe09b3bb92d76a30df4cc53ae\"},{\"prev_out\":{\"value\":258454,\"tx_index\":268933461,\"n\":1,\"spent\":true,\"script\":\"a914508dce85a2be87f95b942316d1daa108812622aa87\",\"type\":0,\"addr\":\"392wro2ENHX7CjLeocxNPUWmmPDQzS48JZ\"},\"sequence\":4294967295,\"script\":\"00483045022100dee2c0f2b543be8743e737d7df2d084cfa405ab4e989c0aa41d99ba108f421ae02203d036678aa8a7ec968ad865599f95b57c4d16ae2f773a0c6167608fec1eed4f401483045022100f2149f9f531bad6bbdc1ebeea5f71dfe9c90f91306a14fdb019d3b979b95fc7c02201054382323b472d0411843eb61a9656ccaaa81dc48bed19dc687b202bb0d74ba014c69522102c53f84ca8d677aa4c01fe8b904c88476fd566b13f59e5ff1d988252e9ca3a171210306d971e7f850be425dc26198e4f563b08310895e6dfb5fb060dfb788befe69ac210258a53770fa045be50fee960ad3771e44643f2d5bc10ed91456f4ada90215b2f953ae\"},{\"prev_out\":{\"value\":407166,\"tx_index\":268950432,\"n\":9,\"spent\":true,\"script\":\"a914f7d3a668018fdbda6cc4c3fe00f48c245c13d93f87\",\"type\":0,\"addr\":\"3QHQNdLkjBUPTfaHjY5CSmK8bdWs8MmE5t\"},\"sequence\":4294967295,\"script\":\"004730440220419cb928dbcfef0aae4b61a6e4adfcb67470a6327a497bfc5ef1cadf4acc814b0220676a27d16ff76f0f10c6be097b531f48979d559f803bbf1d79620e7a1d15e84601483045022100e0cb9970374d5e6652ef9a754c6546f7a20d709a6924ec225b8aab0d83fe91d5022001c6ee577a26dd454a421b1b8e146a7bb9069269e4d03191b0ba9417996804b4014c6952210285e905a61d53c89109a807c09d887837044f8b28391379a51447acace3b35980210215c752eec728ca99dcfcb0aa08d46b27a432dfd80812d127b581a998f7b6a95e21028e675cac3804f5687c95600722f085939e27ea2f127507c649a38ae23e18c60a53ae\"},{\"prev_out\":{\"value\":7674465,\"tx_index\":268960115,\"n\":1,\"spent\":true,\"script\":\"a914853cfec9b49cc380c88b74a94afc8d2267dd57f787\",\"type\":0,\"addr\":\"3DqWs5jt428Ufpnh4LTiJnxEZVnE27o5wr\"},\"sequence\":4294967295,\"script\":\"00483045022100ad252075065e8178aa3d660dcfb084bbeee0b2392dbfee09603c0d7365e1065d02202f26578f986fe154b670c345739d303eea986245b9008f5052892c91dc9821f20147304402205adc3c7db2025068fb1b13f145700410b1635ef31a90628b0a6dfef741b9135902204bee9fe904da23b60f4d6a0c8785cdf6d9d4d5a52cfdc297bbaa443b904e03fb014c69522102ac4dc0cd39fc459cb78842838409b637bac711eba6294844369fa8275eb0121a21026913843e50457999170626bc793261410071907ed0b9ef09f2a437cdeea683232102700ecc58bbf64483c3469faffbd5ca5949e4d7bfc585abc1e62c5be015c7c6e353ae\"}],\"out\":[{\"value\":7059861,\"tx_index\":269060445,\"n\":0,\"spent\":true,\"script\":\"a914623b0b058748f0656778ffa10b28e6e878abc88d87\",\"type\":0,\"addr\":\"3AeQsj5oytKJUvJZDELCPd4ckKfPV2PhFK\"},{\"value\":1300000,\"tx_index\":269060445,\"n\":1,\"spent\":true,\"script\":\"76a9144e2a012320a380a7f2ffbfd5174d1441a83fe5e888ac\",\"type\":0,\"addr\":\"188J2UzREaYjSJ5oc3Mctgxn3rrQowKSW4\"}]},{\"hash\":\"ebafa58ebdfc046f5f41fca5e6e72665feea015b47a73d379492118cc1e8aff5\",\"ver\":2,\"vin_sz\":1,\"vout_sz\":2,\"size\":223,\"fee\":30276,\"relayed_by\":\"107.6.174.164\",\"lock_time\":476472,\"tx_index\":268933461,\"double_spend\":false,\"result\":258454,\"balance\":268454,\"time\":1500435326,\"block_height\":476473,\"inputs\":[{\"prev_out\":{\"value\":1676794843,\"tx_index\":268930691,\"n\":0,\"spent\":true,\"script\":\"76a914524ec4c8c9c6949345019506cf5647b7d6dbfa8888ac\",\"type\":0,\"addr\":\"18WCmg89XFJa4u8UnFmizq2UpzE6sEMgp7\"},\"sequence\":4294967294,\"script\":\"47304402202efdf38b76341c3c232df72158627c61c062ba458918b4df9efb04fc2f301f630220043bea472823174909e277da1b9cb394115fed0bc415117d35d196fb759cdd60012103c00e1c516c0e24a939ca2de27fab17646e32018309fa860ba39da8063a828af2\"}],\"out\":[{\"value\":258454,\"tx_index\":268933461,\"n\":1,\"spent\":true,\"script\":\"a914508dce85a2be87f95b942316d1daa108812622aa87\",\"type\":0,\"addr\":\"392wro2ENHX7CjLeocxNPUWmmPDQzS48JZ\"}]},{\"hash\":\"bd26d9fe8fe2755bdbcb8c555978208752047e1da1586afdfaa626d7d9cf06d1\",\"ver\":1,\"vin_sz\":9,\"vout_sz\":3,\"size\":2759,\"fee\":576230,\"relayed_by\":\"82.96.64.6\",\"lock_time\":0,\"tx_index\":261578312,\"double_spend\":false,\"result\":-258454,\"balance\":10000,\"time\":1497843821,\"block_height\":471911,\"inputs\":[{\"prev_out\":{\"value\":253237,\"tx_index\":261513757,\"n\":458,\"spent\":true,\"script\":\"a91425c85b25284ca3a587f4368ae6b1e83f7c78833e87\",\"type\":0,\"addr\":\"358nwd5fXfp8aaNxmXmCGK7qjuDE9b1tCj\"},\"sequence\":4294967295,\"script\":\"004830450221008ac00a341837d584fc3ccd3abb71c9a253283ff24565220467ce468b860cf33102207b9d7bc60c497a6ae0b3d42837c848d7a62eb02a484f36027c3dc36aa3b3a50b014730440220430bdba53d92f71b6186706eb1f304770e7ef79dbc2721533b5bff0361c1be16022043be837ec390de360711aba4e0878a37f281375ecdf4651b18ef0bbc03584457014c69522103e7451a98f8273163275fe9aa6d0127460755d99f56d8662eb43b74ddfda1566f2103cf2fd9b6a3d93c1452d573da706a800aa735e66e998bdd120a00a103717735db2102072d0a6d8a4e7b05cd73a3d15426f3559435ea1ff065ee5b7af6989e0e43310453ae\"},{\"prev_out\":{\"value\":258454,\"tx_index\":261513479,\"n\":0,\"spent\":true,\"script\":\"a914508dce85a2be87f95b942316d1daa108812622aa87\",\"type\":0,\"addr\":\"392wro2ENHX7CjLeocxNPUWmmPDQzS48JZ\"},\"sequence\":4294967295,\"script\":\"00473044022007744568d4fb0f61d1404229773e19390815f4686a8c5d7bc7ca1a472935946a0220329f42abf04461d6e0f41da1e73e953671cb48a5e5c78e4cc6d60b062707a46f01473044022014d8693a12052de7cc5c027123dfcd26e4bc0b078470a6377b9ed3628d8eebfb02207f24c6de5dfdfc57148e7845e593196424515b8d5734cc4601f0f0cd0a43784f014c69522102c53f84ca8d677aa4c01fe8b904c88476fd566b13f59e5ff1d988252e9ca3a171210306d971e7f850be425dc26198e4f563b08310895e6dfb5fb060dfb788befe69ac210258a53770fa045be50fee960ad3771e44643f2d5bc10ed91456f4ada90215b2f953ae\"},{\"prev_out\":{\"value\":262892,\"tx_index\":261519813,\"n\":52,\"spent\":true,\"script\":\"a914c061839d875ba844f37f7198bdeb47adea90879787\",\"type\":0,\"addr\":\"3KEEUmv32SvCTZvSho2RoU8YhQH4nFqq2V\"},\"sequence\":4294967295,\"script\":\"00483045022100fc403b5e2743063e071ca1f055cc6517495f65b894f93e5c585afb17d156ce9b022021f4a4d6f435bfe64fae9e34accad5d7523b5c84446b940c8da05ee0be4ba57201483045022100af2fca15ef3b1dd96a6694845242e843d311b97e40062c9ae1b290e5f6aacc0d022049e69747263df12f4817c3e0fcb8d71a263db99124d36158a0e55ead5a282ab4014c6952210379cdf4754fc3af374c68a7bf7bd0b095423ec122083a2c2d331351c8efa138192102a26185228fce420ff9a7dbf7e9901b6616a74e02e322ae8011abc6b4ad62200721036d182d45734545381d75b8fa6505179323949fe3e25ecdf24e79bcd8763f7b1f53ae\"},{\"prev_out\":{\"value\":447845,\"tx_index\":261470221,\"n\":160,\"spent\":true,\"script\":\"a914ee9969c90e2da4bc1cd323e01885d2d723bff81f87\",\"type\":0,\"addr\":\"3PScXY6yaAgDtKkFGvUbGTsRhtbeVHySuK\"},\"sequence\":4294967295,\"script\":\"00483045022100e9e4f8f200f1a516bca924c6f182450b24145b23f414df891e698aa7ea8a1f2a022056f758dd692f712885aae142084c33928fdafa03404f6aaeb4d746ea19663c160147304402205da32ce00ed0207583e06138636256011d20b52ebe41cde387e0d590a776bcdf02203774f6643d4f3a59fd153ae562651604a9c6197c07b84119d32b314b50bf6daf014c695221024622ebab3b8fcadf2b95e2ef5772c990dcfe6ee39e46d3c5a4aa6caf36e6d49f2103843077008d4837722e1d01988c4ef4c05482b614d5b790b0f462cd28d4b646742103ab3be20163734fe1fa7c1e9e00f45867dd22be72ca4b3d7dda892e5e6d2ba5f653ae\"},{\"prev_out\":{\"value\":4561487,\"tx_index\":261535932,\"n\":0,\"spent\":true,\"script\":\"a9144e68c20afe4cbf7d1fec4445c579f287657f6ca587\",\"type\":0,\"addr\":\"38qc8DdcpoZ4afM8VjjsBYv9TRskHg8NmT\"},\"sequence\":4294967295,\"script\":\"0047304402201d2b63d27da4caee7c352040afe5f143315324d257d8116c1b68af72d73026be0220614d17e8a781b376d6925795ccffee03717fda87283ad52abdb78ac46271bb5c01483045022100b295a4bb9433ebe097002f84cd924c02039e8cd1de6ad19f2b569055af16542e02201ea91c200468e992ffbaa13f86fec20814de91e72213936da680a3fc3316ad07014c695221035cba2de7bb31513e9ed0ca8f11d09f74286e6ddf36de49f22f0b5465da05e3a321026a6ceca76dc4d860d300170aaa4c1e7a0d0e1965d48a1b0580813844e334ca6c21020add2662c70711297260ffbbaf58f5f6425cd09026f8445072786810f03a4a4e53ae\"},{\"prev_out\":{\"value\":423469,\"tx_index\":261513757,\"n\":552,\"spent\":true,\"script\":\"a914156c1f3958a685d1de1faf21b24af3c11ef4a61687\",\"type\":0,\"addr\":\"33eHe21mSb2kR3Ym5Z3XzMgdozSEYdDaEE\"},\"sequence\":4294967295,\"script\":\"0047304402207595b7805df0a4b9c83b5bca1d470c509c635d40859d940ffc07394a27bdaca102201b3a5bda0c6723704cbff0042bc71a3dc630ac08883209961237ccff2e1a2e810147304402205f975b1fca66a7a221ec3d7292ebefde8653fc34833a4f053c8cdf87a9d03565022074ffae9f4becb090d5b9dffa4ed641d87d6d9539cd0e4b6c3abb8b9aad9e137a014c695221028e8f4d331b6f4ed82f8b9af0facfc3a83960693f226502a2bf68c80cc8091be42102847267310ea969e0f070c35c3e781e4c7b00c6586461058d63227cc9b2a4c7fe2103b5bfed10f9e36396837eb01e4e184bb93cb552d7e820ca0ce8a0255fb452f7a253ae\"},{\"prev_out\":{\"value\":293605,\"tx_index\":261513757,\"n\":1384,\"spent\":true,\"script\":\"a91465e8b8735ca3060920a6b3456f3b13244b33b83787\",\"type\":0,\"addr\":\"3Ayrxd6YbJcvui7yJpLrgMgcgCyCWjAbkU\"},\"sequence\":4294967295,\"script\":\"00473044022010d83e4cc6d3499c6e3310f8bb824691142dc224ca6c059143324cc82dc9598c02202fc3a7b3fec84ae902b7d7d9e68adefe6876fa61485818fa2ecdb3ae9b8f08ad0147304402207ef69646a3d116beb4754e27b0981c14065dee81c1bc149d98276ed42ae8c233022040542d207d3f6ba440522111482cae27c18af8cf5049ab039ae33e1624595e72014c69522103e734d180e920a02ce5a21d726cc9619ced030783698f0ad2fa0655377b60f1c02102fcc5b63c22d44e68f9de73bd87659d1e6260a81baad11e5dff2bcb30b10f667521025fbac22adfecfd483b739c876f35722a84c9d7c71817b806a7a9dd836e731e0153ae\"},{\"prev_out\":{\"value\":497437,\"tx_index\":261514894,\"n\":0,\"spent\":true,\"script\":\"a9143a63ca414ebb9ff94f9bff5a44ca2be4f9287b5d87\",\"type\":0,\"addr\":\"371kfCq72kFAWcw9EpQF4373fNfK8Rr8bx\"},\"sequence\":4294967295,\"script\":\"00473044022015e81371aaa39e578137250cf26e594308a58112773b20c283d4500d18382be00220245397c276e9c98b1484f089aebeaa05190368bf1776e811ed29d60a8cb58c2e014830450221008b29253c821818a1102a3f7dae3479ad18644a3388acbf2d45bde41eb7fe7e3d02205b99f5cf6b0852bdfc7332af614b34929be19997c7b675c31c18563c06625b89014c695221030a8b4f4e850d174f9b86b421667273787e11ba39eab69eb033be2cc16e301cb021023ccd728cf60269751df30dadc5d125ba33eb4ec184f4b40aec1e8462f821e9402103c5f3dd89dff58bc4ee07cbcb4cb998ea310404e94e0543b465034c98ddeb948753ae\"},{\"prev_out\":{\"value\":2386157490,\"tx_index\":261539394,\"n\":1,\"spent\":true,\"script\":\"a9144d324bdcea9d5c138b4356272e827f1aac70d5c287\",\"type\":0,\"addr\":\"38jCCxxfvBWkczJnZTH4Yg5bkN5zwWHRUx\"},\"sequence\":4294967295,\"script\":\"00473044022016b8f10ad0df838c6098525fc4dd3d5407edae7e65dea16d39c3104ff9bbd102022046e64fdbc6907b0a2b1bb5440c7c06f762bbec7f8d88fe46ed5647ba6cb0f33d014730440220331a659be3bcbf2536709cd39951486b9334f95c2046c68b08f4f0c4f03e712c02202418e3d61cd1b78a8a425abce03336f3aaf336eb4b57ac9d094ba29cefb0dc72014c6952210222311a403eac0a121e587d2aa53e549f08863fc393d0383f576103647be219f02102539a8a234d6b26af7fbfc5d348bb300ffe387d1da2c623f97d9ff1b3a0b95db72103186fcaca72871db6cd8bfee12057f34196238a52b3e474281dc44e0a4c6e51f853ae\"}],\"out\":[{\"value\":1449330000,\"tx_index\":261578312,\"n\":0,\"spent\":true,\"script\":\"a914afa4e6079d52ad239b77d52789cf01694368de7687\",\"type\":0,\"addr\":\"3HhjiU1PLjPH8GkbdAcxpfCnjHv7s1xnoM\"},{\"value\":900949686,\"tx_index\":261578312,\"n\":1,\"spent\":true,\"script\":\"a914060a46a2b74a780381f483b9a221bfad2c83019d87\",\"type\":0,\"addr\":\"32ExHgHiSszQr1ysv4UaLz13AAgeLyAwRx\"},{\"value\":42300000,\"tx_index\":261578312,\"n\":2,\"spent\":true,\"script\":\"a914055c231160f76a9e56f47550f63f5c613fb1d29287\",\"type\":0,\"addr\":\"32BMgHwAbDm8iJBdeQifpJP2orgNxNABjK\"}]},{\"hash\":\"28881e18d542856bc39077b937cefc25edb05d2eaa938b9550016958d115b218\",\"ver\":2,\"vin_sz\":1,\"vout_sz\":2,\"size\":223,\"fee\":59594,\"relayed_by\":\"83.149.70.48\",\"lock_time\":471860,\"tx_index\":261513479,\"double_spend\":false,\"result\":258454,\"balance\":268454,\"time\":1497815981,\"block_height\":471861,\"inputs\":[{\"prev_out\":{\"value\":1813857627,\"tx_index\":261511373,\"n\":1,\"spent\":true,\"script\":\"76a9141258313f67a6b4dfc951ca48ccd14c0ce11300c588ac\",\"type\":0,\"addr\":\"12fzpAf7EwxyNTg6bageA1xjkNBbYf19RQ\"},\"sequence\":4294967294,\"script\":\"473044022016c3d18233e2110f2d79a2b921b376351ecaafc945327dc7afdf176dd25db7aa02207195e3a3ee6a8fc1b18275008fdb54d4add8f2de5df4b950b9423ad16dd85ab3012103cf18618c155609bf3de67652e5eb7b47c36696036ed427271c6452ef787899bb\"}],\"out\":[{\"value\":258454,\"tx_index\":261513479,\"n\":0,\"spent\":true,\"script\":\"a914508dce85a2be87f95b942316d1daa108812622aa87\",\"type\":0,\"addr\":\"392wro2ENHX7CjLeocxNPUWmmPDQzS48JZ\"}]},{\"hash\":\"77ece658481de00f3848d36cc675b405d9d1b827321635e5bfa6e51015afee97\",\"ver\":1,\"vin_sz\":2,\"vout_sz\":2,\"size\":373,\"fee\":20000,\"relayed_by\":\"127.0.0.1\",\"lock_time\":0,\"tx_index\":129257525,\"double_spend\":false,\"result\":10000,\"balance\":10000,\"time\":1455645765,\"block_height\":398734,\"inputs\":[{\"prev_out\":{\"value\":10000,\"tx_index\":129257516,\"n\":0,\"spent\":true,\"script\":\"76a914a7e10b3f621f9b6bfad5a79671b9a37dde86ed8188ac\",\"type\":0,\"addr\":\"1GJfSN2MCzK8RBWiS1JUHfHzyAYLWkseqB\"},\"sequence\":4294967295,\"script\":\"48304502210092dd887d884209a707ebf6eea70d910bc81484648130daec8e51611c9cc53cd4022032f6086099fdbbf1b0d54c8686960a38520a96ab43e850aeb472cbc14d060413012103e4aacb7275dbb86e1209f89f5a7a34b5ec9f77d6f8525339e9e9c67e083bbed4\"},{\"prev_out\":{\"value\":77491,\"tx_index\":129234763,\"n\":2,\"spent\":true,\"script\":\"76a914b9a78e387a69f494f9e483975f7b41f5cfd33cc388ac\",\"type\":0,\"addr\":\"1HvejTEW7m9CiTkZ8JvbDXx4c5aTJuMXVo\"},\"sequence\":4294967295,\"script\":\"47304402207c41499a988b9009c13dad8562b93e4ceec7fd597c6acc771389ef824a8530aa022053549084018179621a2a8e413a10546002c6b8dc71cdafb894eec9f42a481f8a0121024c2c6201856303fe8463d1e16678b4c5c662696fc60752ede2b908b272d468f6\"}],\"out\":[{\"value\":10000,\"tx_index\":129257525,\"n\":0,\"spent\":true,\"script\":\"76a91450dd1864f8b2b379e153bda46b392871c500c59e88ac\",\"type\":0,\"addr\":\"18NZvKMrjHREtW3aqUDDNL1bvKP2xfx3aS\"}]}]}";
    NSData *data = [responseString dataUsingEncoding: NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData: data
                                           options: NSJSONReadingMutableLeaves
                                             error: &error];
}


@end
