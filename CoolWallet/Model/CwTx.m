//
//  CWTx.m
//  iphone_app
//
//  Created by LIN CHIH-HUNG on 2014/10/20.
//  Copyright (c) 2014年 LIN CHIH-HUNG. All rights reserved.
//
#import "CwTx.h"
#import "NSString+HexToData.h"

@implementation CwTx

@synthesize historyAmount = _historyAmount;

-(NSDictionary *) rm_dataKeysForClassProperties
{
    return @{
                @"tx": @"tx",
                @"historyTime_utc": @"time_utc",
                @"confirmations": @"confirmations",
                @"amount_btc": @"amount",
                @"amount_multisig": @"amount_multisig",
             };
}

-(NSArray *) rm_excludedProperties
{
    return @[@"isCompleted", @"tid", @"historyAmount"];
}

-(id) init
{
    self = [super init];
    if (self) {
        self.inputs = [NSMutableArray new];
        self.outputs = [NSMutableArray new];
    }
    
    return self;
}

-(void) setHistoryTime_utc:(NSDate *)historyTime_utc
{
    if ([historyTime_utc isKindOfClass:[NSString class]]) {
        NSString *historyTime = (NSString *)historyTime_utc;
        NSDateFormatter *dateformat = [[NSDateFormatter alloc]init];
        [dateformat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [dateformat setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        historyTime_utc = [dateformat dateFromString:historyTime];
    }
    
    _historyTime_utc = historyTime_utc;
}

-(void) setAmount_btc:(NSNumber *)amount_btc
{
    if (amount_btc == nil) {
        amount_btc = [NSNumber numberWithInt:0];
    }
    
    _historyAmount = [CwBtc BTCWithBTC:amount_btc];
    
    _amount_btc = amount_btc;
}

-(NSData *) tid
{
    if (self.tx == nil || self.tx.length == 0) {
        return nil;
    }

    return [NSString hexstringToData:self.tx];
}

-(NSNumber *) confirmations
{
    if (_confirmations == nil) {
        _confirmations = [NSNumber numberWithInt:0];
    }
    
    return _confirmations;
}

-(BOOL) isCompleted
{
    if (self.inputs == nil || self.outputs == nil) {
        return NO;
    }
    
    if (self.inputs.count == 0 || self.outputs.count == 0) {
        return NO;
    }
    
    return YES;
}

@end