//
//  UIViewController+TabTransactionDetailViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/7/8.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabTransactionDetailViewController.h"
#import "CwAccount.h"
#import "CwBtcNetWork.h"
#import "CwTx.h"
#import "CwTxin.h"
#import "CwTxout.h"
#import "OCAppCommon.h"
#import "NSDate+Localize.h"
#import "NSString+HexToData.h"

@interface TabTransactionDetailViewController()
@property (weak, nonatomic) IBOutlet UILabel *lblCurrency;

@end

@implementation TabTransactionDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:NSLocalizedString(@"Transaction details",nil)];
    
    [self SetTxDetailData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) SetTxDetailData
{    
    NSString *BTCAmount = [self.tx.historyAmount getBTCDisplayFromUnit];
    if([self.tx.historyAmount.BTC doubleValue] >=0) {
        _lblTxType.text = NSLocalizedString(@"Receive from",nil);
        _lblTxAmount.text = [NSString stringWithFormat: @"+%@", BTCAmount];
        _lblTxAddr.text = @"";
        
        for (CwTxin* txin in self.tx.inputs) {
            NSString* txinStr = [NSString stringWithFormat:@"%@",txin.tid];
            if ([txinStr isEqualToString:self.tx.tx]) {
                _lblTxAddr.text = txin.addr;
                break;
            }
        }
        
    }else{
        _lblTxType.text = NSLocalizedString(@"Send to",nil);
        _lblTxAmount.text = [NSString stringWithFormat: @"%@", BTCAmount];
        
        for (CwTxout* txout in self.tx.outputs) {
            NSString* txoutStr = [NSString stringWithFormat:@"%@",txout.tid];
            if ([txoutStr isEqualToString:self.tx.tx]) {
                _lblTxAddr.text = txout.addr;
                break;
            }
        }
    }
    
    if(self.cwManager.connectedCwCard.currRate != nil) {
        [self.lblCurrency setText:self.cwManager.connectedCwCard.currId];
        
        double fiat = [self.tx.historyAmount.BTC doubleValue] * ([self.cwManager.connectedCwCard.currRate doubleValue]/100 );
        _lblTxFiatMoney.text = [NSString stringWithFormat:@"%.2f",fiat];
    }
    
    _lblTxDate.text = [self.tx.historyTime_utc cwDateString];
    _lblTxConfirm.text = [NSString stringWithFormat:@"%@", self.tx.confirmations];
    
    NSString *tid = [NSString dataToHexstring: self.tx.tid];
    _lblTxId.text = tid;
    
}

- (IBAction)btnBlockchain:(id)sender {
    NSString *url = [NSString stringWithFormat:@"https://blockchain.info/tx/%@", _lblTxId.text];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}
@end
