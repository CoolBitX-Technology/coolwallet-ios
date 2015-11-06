//
//  BlockChain.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/10/26.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import "CwAddress.h"
#import "CwAccount.h"
#import "CwManager.h"
#import "SRWebSocket+CW.h"

#import "BlockChain.h"

@interface BlockChain()

@property (strong, nonatomic) CwCard *cwCard;
@property (strong, nonatomic) SRWebSocket *webSocket;

@end

@implementation BlockChain

- (id) init
{
    self = [super init];
    
    self.webSocket = [SRWebSocket sharedSocket];
    
    CwManager *cwManager = [CwManager sharedManager];
    self.cwCard = cwManager.connectedCwCard;
    
    return self;
}

-(GetBalanceByAddrErr) getBalanceByAccountID:(NSInteger)accountID
{
    CwAccount *account = [self.cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)accountID]];
    
    NSString *addresses = [self joinAddressesByAccount:account];
    if (addresses == nil) {
        return GETBALANCEBYADDR_JSON;
    }
    
    NSString *requestUrl = [NSString stringWithFormat:@"%@%@", BlockChainBaseURL, MultiAddrAPI];
    NSDictionary *params = @{@"active": addresses};
    
    [self getRequestUrl:requestUrl params:params success:^(NSDictionary *data) {
        [account updateFromBlockChainAddrData:data];
        [self.cwCard.cwAccounts setObject:account forKey:[NSString stringWithFormat: @"%ld", accountID]];
    } failure:^(NSError *err) {
        NSLog(@"error: %@", err.description);
    }];
    
    return GETBALANCEBYADDR_BASE;
}

-(void) getUnspentByAccountID:(NSInteger)accountID
{
    CwAccount *account = [self.cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", accountID]];
    
    NSString *addresses = [self joinAddressesByAccount:account];
    if (addresses == nil) {
        return;
    }
    
    NSString *requestUrl = [NSString stringWithFormat:@"%@%@", BlockChainBaseURL, UnspentAPI];
    
    [self getRequestUrl:requestUrl params:nil success:^(NSDictionary *data) {
        
        [self.cwCard.cwAccounts setObject:account forKey:[NSString stringWithFormat: @"%ld", accountID]];
    } failure:^(NSError *err) {
        NSLog(@"error: %@", err.description);
    }];
    
    return;
}

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

-(NSString *) joinAddressesByAccount:(CwAccount *)account
{
    NSMutableArray *addresses = [NSMutableArray new];
    for (CwAddress *cwAddress in [account getAllAddresses]) {
        if (cwAddress.address == nil) {
            continue;
        }
        [addresses addObject:cwAddress.address];
    }
    
    if (addresses.count == 0) {
        return nil;
    }
    
    NSString *result = [addresses componentsJoinedByString:@"|"];
    NSLog(@"%@", result);
    return result;
}

@end
