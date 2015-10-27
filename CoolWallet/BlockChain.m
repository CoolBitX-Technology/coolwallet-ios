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
    CwAccount *account = [self.cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", accountID]];
    
    NSMutableArray *cwAddresses = [account getAllAddresses];
    NSMutableArray *addresses = [NSMutableArray new];
    for (CwAddress *cwAddress in cwAddresses) {
        if (cwAddress.address == nil) {
            continue;
        }
        [addresses addObject:cwAddress.address];
    }
    
    if (addresses.count == 0) {
        return GETBALANCEBYADDR_JSON;
    }
    
    NSString *requestUrl = [NSString stringWithFormat:@"https://blockchain.info/multiaddr?active=%@", [self joinAddresses:addresses]];
    NSLog(@"%@", [addresses componentsJoinedByString:@"|"]);
    
    NSURL *url = [NSURL URLWithString:[requestUrl stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    if (data) {
        NSDictionary *json =[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (json == nil) {
            return GETBALANCEBYADDR_JSON;
        }
        
        NSDictionary *wallet = [json objectForKey:@"wallet"];
        NSDictionary *addresses = [json objectForKey:@"addresses"];
        if (wallet == nil || addresses == nil) {
            return GETBALANCEBYADDR_JSON;
        }
        
        NSNumber *balance = [wallet objectForKey:@"final_balance"];
        account.balance = balance.longLongValue;
        
        NSMutableDictionary *addrBalances = [NSMutableDictionary new];
        for (NSDictionary *addr in addresses) {
            NSNumber *balance = [NSNumber numberWithLongLong:(int64_t)[addr objectForKey:@"final_balance"]];
            [addrBalances setObject:balance forKey:[addr objectForKey:@"address"]];
        }
        
        for (NSString *addr in addresses) {
            NSNumber *addrBalance = [addrBalances objectForKey:addr];
            if (addrBalance == nil) {
                continue;
            }
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.address = %@", addr];
            NSArray *searchResult = [cwAddresses filteredArrayUsingPredicate:predicate];
            if (searchResult.count == 0) {
                continue;
            }
            
            CwAddress *cwAddress = [searchResult objectAtIndex:0];
            if (cwAddress.keyChainId == CwAddressKeyChainExternal) {
                NSInteger index = [account.extKeys indexOfObject:cwAddress];
                
                cwAddress.balance = addrBalance.longLongValue;
                [account.extKeys replaceObjectAtIndex:index withObject:cwAddress];
            } else {
                NSInteger index = [account.intKeys indexOfObject:cwAddress];
                
                cwAddress.balance = addrBalance.longLongValue;
                [account.intKeys replaceObjectAtIndex:index withObject:cwAddress];
            }
            
        }
        
        [self.cwCard.cwAccounts setObject:account forKey:[NSString stringWithFormat: @"%ld", accountID]];
    }
    
    return GETBALANCEBYADDR_BASE;
}

-(NSString *) joinAddresses:(NSArray *)addresses
{
    return [addresses componentsJoinedByString:@"|"];
}

@end
