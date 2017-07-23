//
//  CwResetInfo.m
//  CoolWallet
//
//  Created by wen on 2017/7/23.
//  Copyright © 2017年 MAC-BRYAN. All rights reserved.
//

#import "CwResetInfo.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

@interface CwResetInfo ()
@property (strong, nonatomic) NSString *resetKey;
@end

@implementation CwResetInfo

- (instancetype)initWithCardId:(NSString *)cardId
{
    self = [super init];
    if (self) {
        self.cardId = cardId;
    }
    return self;
}

- (NSArray *) rm_excludedProperties
{
    return @[@"cardId"];
}

- (void) setCardId:(NSString *)cardId
{
    BOOL needUpdateInfo = NO;
    if (!_cardId || ![cardId isEqualToString:_cardId]) {
        needUpdateInfo = YES;
    }
    
    _cardId = cardId;
    
    if (needUpdateInfo) {
        CwResetInfo *cachedResetInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:self.resetKey];
        if (cachedResetInfo) {
            NSDictionary *cachedInfo = [RMMapper dictionaryForObject:cachedResetInfo];
            [RMMapper populateObject:self fromDictionary:cachedInfo];
        }
    }
}

- (NSString *) pinOld
{
    if (!_pinOld) {
        _pinOld = @"12345678";
    }
    
    return _pinOld;
}

- (NSString *) pinNew
{
    if (!_pinNew) {
        _pinNew = @"12345678";
    }
    
    return _pinNew;
}

- (NSString *) resetKey
{
    if (self.cardId && !_resetKey) {
        _resetKey = [NSString stringWithFormat:@"reset_%@", self.cardId];
    }
    
    return _resetKey;
}

- (void) saveResetInfo
{
    if (!self.cardId) {
        return;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults rm_setCustomObject:self forKey:self.resetKey];
}

@end
