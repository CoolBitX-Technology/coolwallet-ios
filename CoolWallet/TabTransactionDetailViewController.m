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
#import "CwTxin.h"
#import "CwTxout.h"
#import "OCAppCommon.h"

@implementation TabTransactionDetailViewController

@synthesize TxKey;

CwManager *cwManager;
CwCard *cwCard;
CwAccount *account;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"";
    //find CW via BLE
    cwManager = [CwManager sharedManager];
    cwManager.delegate=self;
    cwCard = cwManager.connectedCwCard;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    cwCard.delegate = self;
    
    [self SetTxDetailData:TxKey];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) SetTxDetailData:(id)key
{
    NSLog(@"key = %@", key);
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%d", cwCard.currentAccountId]];
    
    CwTx *tx = [account.transactions objectForKey:key];
    NSLog(@"tx utc = %@",[NSString stringWithFormat: @"%@", tx.historyTime_utc]);
    NSLog(@"tx amount = %@", [NSString stringWithFormat: @"%.6f", tx.historyAmount.BTC.doubleValue]);
    NSLog(@"tid = %@",[[NSString alloc] initWithData:tx.tid encoding:NSUTF8StringEncoding]);
    NSLog(@"confirm = %d",tx.confirmations);
    NSLog(@"input = %@",tx.inputs);
    NSLog(@"output = %@",tx.outputs);
    
    NSString *BTCAmount = [tx.historyAmount getBTCDisplayFromUnit];
    if([tx.historyAmount.BTC doubleValue] >=0) {
        _lblTxType.text = @"Receive from";
        _lblTxAmount.text = [NSString stringWithFormat: @"+%@", BTCAmount];
        if(tx.inputs.count > 0) {
            CwTxin* txin = (CwTxin *)[tx.inputs objectAtIndex:0];
            _lblTxAddr.text = txin.addr;
        }
    }else{
        _lblTxType.text = @"Send to";
        _lblTxAmount.text = [NSString stringWithFormat: @"%@", BTCAmount];
        if(tx.outputs.count > 0) {
            CwTxout* txout = (CwTxout *)[tx.outputs objectAtIndex:0];
            _lblTxAddr.text = txout.addr;
        }
    }
    
    if(cwCard.currRate != nil) {
        double fiat = [tx.historyAmount.BTC doubleValue] * ([cwCard.currRate doubleValue]/100 );
        _lblTxFiatMoney.text = [NSString stringWithFormat:@"%.2f %@",fiat, cwCard.currId];
    }
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd MMM yyyy hh:mm a"];
    _lblTxDate.text = [format stringFromDate:tx.historyTime_utc];
    //_lblTxDate.text = [NSString stringWithFormat: @"%@", tx.historyTime_utc];
    _lblTxConfirm.text = [NSString stringWithFormat:@"%ld",tx.confirmations];
   // NSString* responseString = [[NSString alloc] initWithData:responseData encoding:NSNonLossyASCIIStringEncoding];
    //_lblTxId.text = [[NSString alloc] initWithData:tx.tid encoding:NSUTF8StringEncoding];
    
    NSString *tid = [NSString stringWithFormat:@"%@", [self dataToHexstring: tx.tid]];
    _lblTxId.text = tid;
    
}

- (NSString*) dataToHexstring:(NSData*)data
{
    NSString *hexStr = [NSString stringWithFormat:@"%@",data];
    NSRange range = {1,[hexStr length]-2};
    hexStr = [[hexStr substringWithRange:range] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    return hexStr;
}

#pragma mark - CwCardDelegate

-(void) didCwCardCommand
{
    NSLog(@"didCwCardCommand");
    if (cwCard.cardId)
        [cwCard saveCwCardToFile];
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    //Add a notification to the system
    UILocalNotification *notify = [[UILocalNotification alloc] init];
    notify.alertBody = [NSString stringWithFormat:@"%@ Disconnected", cardName];
    notify.soundName = UILocalNotificationDefaultSoundName;
    notify.applicationIconBadgeNumber=1;
    [[UIApplication sharedApplication] presentLocalNotificationNow: notify];
    
    // Get the storyboard named secondStoryBoard from the main bundle:
    UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    // Load the view controller with the identifier string myTabBar
    // Change UIViewController to the appropriate class
    UIViewController *listCV = (UIViewController *)[secondStoryBoard instantiateViewControllerWithIdentifier:@"CwMain"];
    // Then push the new view controller in the usual way:
    [self.parentViewController presentViewController:listCV animated:YES completion:nil];
}

- (IBAction)btnBlockchain:(id)sender {
    NSString *url = [NSString stringWithFormat:@"https://blockchain.info/tx/%@", _lblTxId.text];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}
@end
