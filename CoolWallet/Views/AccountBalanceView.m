//
//  AccountBalanceView.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/2/2.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import "AccountBalanceView.h"
#import "CwAccount.h"
#import "OCAppCommon.h"
#import "CwManager.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface AccountBalanceView ()

@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *fiatMoneyLabel;
@property (weak, nonatomic) IBOutlet UIView *reservedView
;
@property (weak, nonatomic) IBOutlet UILabel *avalibleAmountLabel;
@property (weak, nonatomic) IBOutlet UILabel *reservedAmountLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;

@property (readwrite) float viewHeight;

@end

@implementation AccountBalanceView

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupViews];
    }
    return self;
}

-(instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

-(instancetype) init
{
    self = [super init];
    if (self) {
        [self setupViews];
    }
    return self;
}

-(void) setupViews
{
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.borderWidth = 1.0;
    
    self.viewHeight = self.frame.size.height;
    self.reservedView.hidden = YES;
    
    [self addObservers];
}

-(void) addObservers
{
    CwManager *cwManager = [CwManager sharedManager];
    
    RACSignal *rateSignal = [RACObserve(cwManager.connectedCwCard, currRate) filter:^BOOL(NSDecimalNumber *rate) {
        return rate.doubleValue > 0;
    }];
    
    RACSignal *currencySignal = [RACObserve(cwManager.connectedCwCard, currId) filter:^BOOL(NSString *currency) {
        return currency != nil && currency.length > 0;
    }];
    
    RACSignal *balanceSignal = [[[RACObserve(self, account) filter:^BOOL(CwAccount *account) {
        return account != nil;
    }] map:^id(CwAccount *account) {
        return RACObserve(account, balance);
    }] switchToLatest];
    
    RACSignal *blockAmountSignal = [[[RACObserve(self, account) filter:^BOOL(CwAccount *account) {
        return account != nil;
    }] map:^id(CwAccount *account) {
        return RACObserve(account, blockAmount);
    }] switchToLatest];
    
    RACSignal *hasBlockAmountSignal = [blockAmountSignal map:^NSNumber *(NSNumber *block) {
        if (block.longLongValue > 0) {
            return @(YES);
        } else {
            return @(NO);
        }
    }];
    
    @weakify(self)
    [[[[[RACSignal combineLatest:@[balanceSignal, rateSignal, currencySignal] reduce:^NSString *(NSNumber *balance, NSDecimalNumber *rate, NSString *currency) {
        OCAppCommon *appCommon = [OCAppCommon getInstance];
        return [NSString stringWithFormat: @"%@ %@", [appCommon convertFiatMoneyString:balance.longLongValue currRate:rate], currency];
    }] filter:^BOOL(NSString *rateCurrency) {
        return self.fiatMoneyLabel != nil;
    }] distinctUntilChanged]
     deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSString *rateCurrency) {
        @strongify(self)
        self.fiatMoneyLabel.text = rateCurrency;
    }];
    
    [[[[[balanceSignal filter:^BOOL(NSNumber *balance) {
        @strongify(self)
        return self.amountLabel != nil;
    }] map:^NSMutableAttributedString *(NSNumber *balance) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:@"bitcoin.png"];
        
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        
        OCAppCommon *appCommon = [OCAppCommon getInstance];
        
        NSMutableAttributedString *myString= [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", [appCommon convertBTCStringformUnit: balance.longLongValue]]];
        [myString insertAttributedString:attachmentString atIndex:0];
        
        return myString;
    }] distinctUntilChanged]
     deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSMutableAttributedString *amount) {
        @strongify(self)
        self.amountLabel.attributedText = amount;
//         self.amountLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:@"100"];
    }];
    
    [[[RACObserve(self.reservedView, hidden) distinctUntilChanged]
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSNumber *hidden) {
        @strongify(self)
        if (hidden.boolValue) {
            self.heightConstraint.constant = self.heightConstraint.constant - self.reservedView.frame.size.height;
        } else {
            self.heightConstraint.constant = self.heightConstraint.constant + self.reservedView.frame.size.height;
        }
        
        [self updateConstraints];
    }];
    
    [[[[[RACSignal combineLatest:@[balanceSignal, blockAmountSignal]] distinctUntilChanged] filter:^BOOL(RACTuple *tuple) {
        return self.avalibleAmountLabel != nil && self.reservedAmountLabel != nil;
    }] deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(RACTuple *tuple) {
        @strongify(self)
        NSNumber *balance = tuple.first;
        NSNumber *block = tuple.last;
        int64_t avalible = balance.longLongValue - block.longLongValue;
        
        OCAppCommon *appCommon = [OCAppCommon getInstance];
        self.avalibleAmountLabel.text = [appCommon convertBTCStringformUnit:avalible];
        self.reservedAmountLabel.text = [appCommon convertBTCStringformUnit:block.longLongValue];
    }];
    
    [[[hasBlockAmountSignal distinctUntilChanged]
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSNumber *hasBlockAmount) {
        @strongify(self)
        self.reservedView.hidden = !hasBlockAmount.boolValue;
        float noneBlockHeight = self.reservedView.frame.origin.y;
        
        if (self.reservedView.hidden) {
            if (self.heightConstraint.constant > noneBlockHeight) {
                self.heightConstraint.constant = noneBlockHeight;
            }
        } else {
            if (self.heightConstraint.constant != self.viewHeight) {
                self.heightConstraint.constant = self.viewHeight;
            }
        }
        
        [self updateConstraints];
    }];
}

@end
