//
//  UIViewController+TabbarHomeViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/3/19.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabbarHomeViewController.h"
#import "UIColor+CustomColors.h"
#import "SWRevealViewController.h"
#import "OCAppCommon.h"
#import "CwTxin.h"
#import "CwTxout.h"
#import "CwUnspentTxIndex.h"

CwBtcNetWork *btcNet;
CwAccount *account;
NSArray *sortedTxKeys;

NSDictionary *rates;
NSInteger rowSelect;

bool isFirst = YES;

@interface TabbarHomeViewController ()

@property (strong, nonatomic) NSArray *accountButtons;
@property (assign, nonatomic) BOOL waitAccountCreated;

@end

@implementation TabbarHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"TabbarHomeViewController, viewDidLoad");
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(setAccountButton) forControlEvents:UIControlEventValueChanged];
    [self.tableTransaction addSubview:self.refreshControl]; //把RefreshControl加到TableView中
    
    //find CW via BLE
    cwManager = [CwManager sharedManager];
    
    cwCard = cwManager.connectedCwCard;
    
    btcNet = [CwBtcNetWork sharedManager];

    cwManager.delegate = self;
    cwCard.delegate = self;
    btcNet.delegate = self;
    
    self.accountButtons = @[self.btnAccount1, self.btnAccount2, self.btnAccount3, self.btnAccount4, self.btnAccount5];
    NSLog(@"111");
    [self getBitcoinRateforCurrency];
    NSLog(@"222");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    cwManager.delegate = self;
    cwCard.delegate = self;
    btcNet.delegate = self;
    
    NSLog(@"accid = %ld",cwCard.currentAccountId);
    if (account != nil) {
        [self setAccountButton];
    }
    //[self showIndicatorView:@"synchronizing data"];
    //self.actBusyIndicator.hidden = NO;
    //[self.actBusyIndicator startAnimating];
    
}

-(void)viewDidAppear:(BOOL)animated {
    NSLog(@"TabbarHomeViewController, viewDidAppear");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) getBitcoinRateforCurrency
{
    rates = [btcNet getCurrRate];
    
    //find currId from the rates
    NSNumber *rate = [rates objectForKey:cwCard.currId];
    
    if (rate==nil) {
        //use USD as default currId
        cwCard.currId = @"USD";
        rate = [rates objectForKey:@"USD"];
    }
    
    if (rate)
    {
        cwCard.currRate = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%f", [rate floatValue]*100]];
        
        //update UI
        [self didGetCwCurrRate];
    }
}

#pragma marks - Account Button Actions

- (void)setAccountButton{
    NSLog(@"TabbarHomeViewController, cwAccounts = %ld", [cwCard.cwAccounts count]);
    
    for(int i =0; i< [cwCard.cwAccounts count]; i++) {
        UIButton *accountBtn = [self.accountButtons objectAtIndex:i];
        accountBtn.hidden = NO;
        
        if (i == self.accountButtons.count-1) {
            accountBtn.enabled = YES;
            self.btnAddAccount.hidden = YES;
            self.imgAddAccount.hidden = YES;
        }
    }
    
    NSLog(@"accid = %ld, refresh? %d,%d",cwCard.currentAccountId, self.refreshControl.isHidden, self.refreshControl.isRefreshing);
    if (self.refreshControl.isHidden) {
        UIButton *selectedAccount = [self.accountButtons objectAtIndex:cwCard.currentAccountId];
        [selectedAccount sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else {
        [self updateBalanceAndTxs:cwCard.currentAccountId];
    }
    
}

- (IBAction)btnAccount:(id)sender {
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
    
    NSInteger currentAccId = cwCard.currentAccountId;
    for (UIButton *btn in self.accountButtons) {
        if (sender == btn) {
            cwCard.currentAccountId = [self.accountButtons indexOfObject:btn];
            [btn setBackgroundColor:[UIColor colorAccountBackground]];
            [btn setSelected:YES];
        } else {
            [btn setBackgroundColor:[UIColor blackColor]];
            [btn setSelected:NO];
        }
    }
    
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", cwCard.currentAccountId]];
    
    if (currentAccId != cwCard.currentAccountId || isFirst) {
        [self showIndicatorView:@"synchronizing data"];
        
        [cwCard setDisplayAccount:cwCard.currentAccountId];
        [cwCard getAccountInfo:cwCard.currentAccountId];
    }
    
    [self SetBalanceText];
    [self SetTxkeys];
}

Boolean setBtnActionFlag;
- (void)SetBalanceText
{
    NSLog(@"TabbarHomeViewController, SetBalanceText, balance: %lld", account.balance);
    
    _lblBalance.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertBTCStringformUnit: (int64_t)account.balance], [[OCAppCommon getInstance] BitcoinUnit]];
    
    _lblFaitMoney.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertFiatMoneyString:(int64_t)account.balance currRate:cwManager.connectedCwCard.currRate], cwCard.currId];
}

- (void)SetTxkeys
{
    NSLog(@"TabbarHomeViewController, %ld trans = %ld", account.accId, [account.transactions count]);
    
    if([account.transactions count] == 0 ) {
        [_tableTransaction reloadData];
        return;
    }
    
    //sorting account transactions
    sortedTxKeys = [account.transactions keysSortedByValueUsingComparator: ^(id obj1, id obj2) {
        NSDate *d1 = ((CwTx *)obj1).historyTime_utc;
        NSDate *d2 = ((CwTx *)obj2).historyTime_utc;
        
        if ([d1 compare:d2] == NSOrderedAscending)
            return (NSComparisonResult)NSOrderedDescending;
        if ([d1 compare:d2] == NSOrderedDescending)
            return (NSComparisonResult)NSOrderedAscending;
            //return (NSComparisonResult)NSOrderedDescending;
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    
    [_tableTransaction reloadData];
}

-(void) updateBalanceAndTxs:(NSInteger)accId
{
    //update balance
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Do background work
        [btcNet getBalanceByAccount: accId];
        [btcNet getTransactionByAccount: accId];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //Update UI
            NSLog(@"update %ld, current is %ld", accId, cwCard.currentAccountId);
            if (accId == cwCard.currentAccountId) {
                [self SetBalanceText];
                [cwCard setAccount: accId Balance: account.balance];
            } else {
                CwAccount *updateAccount = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", accId]];
                [cwCard setAccount: accId Balance: updateAccount.balance];
            }
        });
    });
    
//    [btcNet getBalanceByAccount: accId]; //this will update the CwCard.account
//    if (accId == cwCard.currentAccountId) {
//        [self SetBalanceText];
//        [cwCard setAccount: accId Balance: account.balance];
//    } else {
//        CwAccount *updateAccount = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", accId]];
//        [cwCard setAccount: accId Balance: updateAccount.balance];
//    }
//    
//    [btcNet getTransactionByAccount: accId]; //this will update the CwCard.transaction
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier compare:@"TransactionDetailSegue"] == 0) {
        id page = segue.destinationViewController;
        id TxKey = sortedTxKeys[rowSelect];
        [page setValue:TxKey forKey:@"TxKey"];
    }
}

#pragma marks - Actions
- (IBAction)btnAddAccount:(id)sender {
    [self CreateAccount];
}

- (void)CreateAccount{
    if (cwCard.hdwAcccountPointer < 5) {
        //self.actBusyIndicator.hidden = NO;
        //[self.actBusyIndicator startAnimating];
        [self showIndicatorView:@"Creating Account"];
        
        [cwCard newAccount:cwCard.hdwAcccountPointer Name:@""];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [account.transactions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"table view count =%d", account.transactions.count);
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TransactionViewCell" forIndexPath:indexPath];
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TransactionViewCell"];
    }
    
    if((sortedTxKeys.count - 1) < indexPath.row) return cell;
    CwTx *tx = [account.transactions objectForKey:sortedTxKeys[indexPath.row]];
    //CwTx *tx = [account.transactions objectForKey: [NSString stringWithFormat:@"%d",indexPath.row]];
    
    UILabel *lblTxUTC = (UILabel *)[cell viewWithTag:100];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd MMM yyyy h:mm a"];
    lblTxUTC.text = [format stringFromDate:tx.historyTime_utc];
    
    //lblTxUTC.text = [NSString stringWithFormat: @"%@", tx.historyTime_utc];
    UILabel *lblTxNotes = (UILabel *)[cell viewWithTag:102];
    //lblTxNotes.text = [NSString stringWithFormat: @"%@", tx.tid];
    UILabel *lblTxAmount = (UILabel *)[cell viewWithTag:103];
    
    lblTxAmount.text = [NSString stringWithFormat: @"%@", [[OCAppCommon getInstance] convertBTCStringformUnit: tx.historyAmount.satoshi.longLongValue]];
    if ([tx.historyAmount.satoshi intValue]>0){
        lblTxAmount.text = [NSString stringWithFormat:@"+%@", lblTxAmount.text];
        lblTxAmount.textColor = [UIColor greenColor];
        
        if(tx.inputs.count > 0) {
            CwTxin* txin = (CwTxin *)[tx.inputs objectAtIndex:0];
            lblTxNotes.text = txin.addr;
        }
    }else{
        lblTxAmount.textColor = [UIColor redColor];
        
        if(tx.outputs.count > 0) {
            CwTxout* txout = (CwTxout *)[tx.outputs objectAtIndex:0];
            lblTxNotes.text = txout.addr;
        }
    }
    return cell;
}

#pragma mark - TableView Delegates

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    rowSelect = indexPath.row;
    [self performSegueWithIdentifier:@"TransactionDetailSegue" sender:self];
}

#pragma marks - CwCardDelegate

-(void) didCwCardCommand
{
    NSLog(@"TabbarHomeViewController, didCwCardCommand");
//    if(isFirst && cwCard.hdwAcccountPointer > 0) [self setAccountButton];
    [cwCard saveCwCardToFile];
    
    //[self.actBusyIndicator stopAnimating];
    //self.actBusyIndicator.hidden = YES;
}

-(void) didCwCardCommandError:(NSInteger)cmdId ErrString:(NSString *)errString
{
    NSString *msg = [NSString stringWithFormat:@"Cmd %02lX %@", (long)cmdId, errString];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Command Error"
                                                   message: msg
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    
    [alert show];
}

-(void) didGetModeState
{
    NSLog(@"TabbarHomeViewController, card mode = %ld", cwCard.mode);
    if (cwCard.mode ==CwCardModePerso) {
        //goto Setting for Security Policy
        [self performSegueWithIdentifier:@"SecuritySegue" sender:self];
    }else{
        [self showIndicatorView:@"synchronizing data"];
        [cwCard syncFromCard];
    }
}

-(void) didGetCwHdwStatus
{
    NSLog(@" TabbarHomeViewController, cwCard.hdwStatus = %ld",cwCard.hdwStatus);
    if (cwCard.hdwStatus == CwHdwStatusInactive || cwCard.hdwStatus == CwHdwStatusWaitConfirm) {
        //goto New Wallet
        [self performSegueWithIdentifier:@"CreateHdwSegue" sender:self];
    }
}

-(void) didGetCwHdwAccountPointer
{
    //[self performDismiss];
    NSLog(@"TabbarHomeViewController, didGetCwHdwAccointPointer = %ld", cwCard.hdwAcccountPointer);
    if (cwCard.hdwAcccountPointer == 0) {
        [self CreateAccount];
        cwCard.currentAccountId = 0;
    }
    else {
        [self setAccountButton];
        //[cwCard getAccounts];
    }
}

/*
 -(void) didGetAccounts
 {
 //[self.tableView reloadData];
 }
*/

-(void) didGetAccountInfo: (NSInteger) accId
{
    NSLog(@"TabbarHomeViewController, didGetAccountInfo = %ld, currentAccountId = %ld", accId, cwCard.currentAccountId);
    
    if(accId == cwCard.currentAccountId) {
        [cwCard getAccountAddresses:accId];
    }
}

-(void) didGetAccountAddresses: (NSInteger) accId
{
    //stop activity indicator of the cess
    //clear the UIActivityIndicatorView
    //create activity indicator on the cell
    
    NSLog(@"TabbarHomeViewController, didGetAccountAddresses = %ld, currentAccountId = %ld", accId, cwCard.currentAccountId);
    
    if (accId != cwCard.currentAccountId) {
        return;
    }
    
    NSLog(@"TabbarHomeViewController, %ld, transitions: %@", account.accId, account.transactions);
    if (account.transactions==nil) {
        //get balance and transaction when there is no transaction yet.
        
        dispatch_queue_t queue = dispatch_queue_create("com.dtco.CoolWallet", NULL);
        
        dispatch_async(queue, ^{
            [btcNet registerNotifyByAccount: accId];
            
            [self updateBalanceAndTxs:accId];
        });
    } else {
        [self performDismiss];
    }
}

-(void) didGetTransactionByAccount:(NSInteger)accId
{
    NSLog(@"TabbarHomeViewController, currAccId: %ld, didGetTransactionByAccount: %ld", cwCard.currentAccountId, accId);
    //code to be executed in the background
    dispatch_async(dispatch_get_main_queue(), ^{
        //code to be executed on the main thread when background task is finished
        //NSLog(@"account tx count = %lu", (unsigned long)account.transactions.count );
        //[cwCard setAccount: accId Balance: account.balance];
        
        CwAccount *txAccount = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", accId]];
        
        //get address publickey uf the unspent if needed
        for (CwUnspentTxIndex *utx in txAccount.unspentTxs)
        {
            CwAddress *addr;
            //get publickey from address
            if (utx.kcId==0) {
                //External Address
                addr = account.extKeys[utx.kId];
            } else {
                //Internal Address
                addr = account.intKeys[utx.kId];
            }
            
            if (addr.publicKey==nil)
                [cwCard getAddressPublickey:accId KeyChainId:utx.kcId KeyId:utx.kId];
        }
        
        if (accId == cwCard.currentAccountId) {
            NSLog(@"TabbarHomeViewController, prepare to update tx records");
            [self SetTxkeys]; //this includes reloadData
            [self performDismiss];
        }
    });
}

-(void) didNewAccount: (NSInteger)aid
{
    NSLog(@"TabbarHomeViewController, didNewAccount: %ld", aid);
    
    //find CW via BLE
    cwManager = [CwManager sharedManager];
    
    cwCard = cwManager.connectedCwCard;
    [cwCard genAddress:aid KeyChainId:CwAddressKeyChainExternal];
    
    self.waitAccountCreated = YES;
}

-(void) didSetAccountBalance
{
    if (setBtnActionFlag) {
        setBtnActionFlag = NO;
    }
}

-(void) didGetCwCurrRate
{
    NSLog(@"TabbarHomeViewController, didGetCwCurrRate");
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSString *numberAsString = [numberFormatter stringFromNumber: cwManager.connectedCwCard.currRate];
    NSLog(@"TabbarHomeViewController, currRate = %@ ",numberAsString);
    //_lblFaitMoney.text = numberAsString;
    NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithDecimal:[[numberFormatter numberFromString:numberAsString] decimalValue]];
    [cwManager.connectedCwCard setCwCurrRate:decNum];
    
    _lblFaitMoney.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertFiatMoneyString:(int64_t)account.balance currRate:cwManager.connectedCwCard.currRate], cwCard.currId];
    //self.txtExchangeRage.text = numberAsString;
}


-(void) didSetCwCurrRate
{
    //get mode state
    [cwCard getModeState];
}

-(void) didGenAddress:(CwAddress *)addr
{
    NSLog(@"addr: %@, keyChainId = %ld", addr, addr.keyChainId);
    if (self.waitAccountCreated) {
        self.waitAccountCreated = NO;
        
        [self performDismiss];
        [self setAccountButton];
        
    }
}


- (void) showIndicatorView:(NSString *)Msg {
    if (mHUD != nil) {
        mHUD.labelText = Msg;
        return;
    }
    
    mHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:mHUD];
    
    //如果设置此属性则当前的view置于后台
    mHUD.dimBackground = YES;
    mHUD.labelText = Msg;
    
    [mHUD show:YES];
}

- (void) performDismiss
{
    if(mHUD != nil) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        //[mHUD removeFromSuperview];
        //[mHUD release];
        mHUD = nil;
    }
    
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    NSLog(@"TabbarHomeViewController, didDisconnectCwCard");
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

@end
