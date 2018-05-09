//
//  UIViewController+TabbarHomeViewController.m
//  CoolWallet
//
//  Created by bryanLin on 2015/3/19.
//  Copyright (c) 2015年 MAC-BRYAN. All rights reserved.
//

#import "TabbarHomeViewController.h"
#import "TabbarAccountViewController.h"
#import "UIColor+CustomColors.h"
#import "SWRevealViewController.h"
#import "OCAppCommon.h"
#import "CwTxin.h"
#import "CwTxout.h"
#import "CwUnspentTxIndex.h"
#import "NSDate+Localize.h"
#import "AccountBalanceView.h"
#import "BlockChain.h"
#import "CwExchangeManager.h"
#import "TabTransactionDetailViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

NSDictionary *rates;
CwBtcNetWork *btcNet;

@interface TabbarHomeViewController () <UITabBarControllerDelegate>
{
    NSArray *sortedTxKeys;
    bool isFirst;
    CwAccount *account;
}

@property (strong, nonatomic) UIBarButtonItem *addButton;
@property (strong, nonatomic) NSArray *accountButtons;
@property (assign, nonatomic) BOOL waitAccountCreated;
@property (strong, nonatomic) NSMutableArray *txSyncing;

@property (strong, nonatomic) CwTx *selectTx;

@property (weak, nonatomic) IBOutlet AccountBalanceView *balanceView;

@end

@implementation TabbarHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"TabbarHomeViewController, viewDidLoad");
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(setAccountButton) forControlEvents:UIControlEventValueChanged];
    [self.tableTransaction addSubview:self.refreshControl]; //把RefreshControl加到TableView中
    
    self.tableTransaction.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    btcNet = [CwBtcNetWork sharedManager];
    
    isFirst = YES;
    
    self.accountButtons = @[self.btnAccount1, self.btnAccount2, self.btnAccount3, self.btnAccount4, self.btnAccount5];
    self.txSyncing = [NSMutableArray new];
    
    [self.view sendSubviewToBack:self.balanceView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    TabbarAccountViewController *parantViewController = (TabbarAccountViewController *)self.parentViewController;
    [parantViewController.navigationItem setTitle:NSLocalizedString(@"Accounts",nil)];
    self.addButton = parantViewController.addButton;
    [self.addButton setTarget:self];
    [self.addButton setAction:@selector(CreateAccount)];
    parantViewController.delegate = self;
    
    btcNet.delegate = self;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (account == nil) {
        [self showIndicatorView:NSLocalizedString(@"checking data",nil)];
        [self.cwManager.connectedCwCard getModeState];
    } else {
        [self setAccountButton];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    TabbarAccountViewController *parantViewController = (TabbarAccountViewController *)self.parentViewController;
    parantViewController.delegate = nil;
    
    if (btcNet.delegate && btcNet.delegate == self) {
        btcNet.delegate = nil;
    }
    
    self.selectTx = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) checkRecoveryState
{
    BOOL inRecovery = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"recovery_%@", self.cwManager.connectedCwCard.cardId]];
    
    if (inRecovery) {
        [self showHintAlert:NSLocalizedString(@"Recovery incomplete",nil) withMessage:NSLocalizedString(@"Your wallet was not fully recovered, please reset and recover again.",nil) withOKAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.cwManager disconnectCwCard];
        }]];
    }
}

-(void) checkAndLoginExSite
{
    CwExchangeManager *exchange = [CwExchangeManager sharedInstance];
    if (exchange.sessionStatus == ExSessionNone) {
        RACSignal *cardSignal = [[[RACObserve(self.cwManager, connectedCwCard) filter:^BOOL(CwCard *card) {
            return card != nil && card.cardId.length != 0;
        }] map:^RACStream *(CwCard *card) {
            return RACObserve(card, hdwStatus);
        }] switchToLatest];
        
        [[[[cardSignal filter:^BOOL(NSNumber *hdwStatus) {
            return hdwStatus.integerValue != CwHdwStatusInactive && hdwStatus.integerValue != CwHdwStatusWaitConfirm;
        }] take:1]
          subscribeOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground name:NSLocalizedString(@"ExSessionLogin",nil)]]
         subscribeNext:^(id value) {
             [exchange loginExSession];
         }];
    }
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{    
    return [self isLoadingFinish];
}

-(void) getBitcoinRateforCurrency
{
    [self showIndicatorView:NSLocalizedString(@"synchronizing data",nil)];
    
    rates = [[BlockChain new] getCurrencyRates];
    
    //find currId from the rates
    NSNumber *rate = [rates objectForKey:self.cwManager.connectedCwCard.currId];
    
    if (rate==nil) {
        //use USD as default currId
        self.cwManager.connectedCwCard.currId = @"USD";
        rate = [rates objectForKey:@"USD"];
    }
    
    if (rate)
    {
        self.cwManager.connectedCwCard.currRate = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%f", [rate floatValue]*100]];
        
        //update UI
        [self didGetCwCurrRate];
    } else {
        [self performDismiss];
    }
}

#pragma marks - Account Button Actions

- (void)setAccountButton{
    NSLog(@"TabbarHomeViewController, cwAccounts = %lu", (unsigned long)[self.cwManager.connectedCwCard.cwAccounts count]);
    
    for(int i =0; i< [self.cwManager.connectedCwCard.cwAccounts count]; i++) {
        UIButton *accountBtn = [self.accountButtons objectAtIndex:i];
        accountBtn.hidden = NO;
    }
    
    if (self.cwManager.connectedCwCard.cwAccounts.count == self.accountButtons.count) {
        [self.addButton setEnabled:NO];
        [self.addButton setTintColor:[UIColor clearColor]];
    } else {
        [self.addButton setEnabled:YES];
        [self.addButton setTintColor:[UIColor whiteColor]];
    }
    
    if (self.refreshControl.isHidden) {
        UIButton *selectedAccount = [self.accountButtons objectAtIndex:self.cwManager.connectedCwCard.currentAccountId];
        [selectedAccount sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else {
        [self updateBalanceAndTxs:self.cwManager.connectedCwCard.currentAccountId];
    }
    
}

- (IBAction)btnAccount:(id)sender {
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
    
    NSInteger currentAccId = self.cwManager.connectedCwCard.currentAccountId;
    for (UIButton *btn in self.accountButtons) {
        if (sender == btn) {
            self.cwManager.connectedCwCard.currentAccountId = [self.accountButtons indexOfObject:btn];
            [btn setSelected:YES];
        } else {
            [btn setSelected:NO];
        }
    }
    
    account = (CwAccount *) [self.cwManager.connectedCwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)self.cwManager.connectedCwCard.currentAccountId]];
    
    if (currentAccId != self.cwManager.connectedCwCard.currentAccountId || isFirst) {
        [self showIndicatorView:NSLocalizedString(@"synchronizing data",nil)];
        
        [self.cwManager.connectedCwCard setDisplayAccount:self.cwManager.connectedCwCard.currentAccountId];
        [self.cwManager.connectedCwCard getAccountInfo:self.cwManager.connectedCwCard.currentAccountId];
    }
    
    [self SetBalanceText];
    [self SetTxkeys];
}

Boolean setBtnActionFlag;
- (void)SetBalanceText
{
    NSLog(@"TabbarHomeViewController, SetBalanceText, balance: %lld", account.balance);
    
    self.balanceView.account = account;
}

- (void)SetTxkeys
{
    NSLog(@"TabbarHomeViewController, %ld trans = %lu", (long)account.accId, (unsigned long)[account.transactions count]);
    
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

-(void) updateBalance:(NSInteger)accId
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BlockChain *blockChain = [[BlockChain alloc] init];
        [blockChain getBalanceByAccountID:accId];
        NSLog(@"updateBalance: %ld, balance: %lld", (long)accId, account.balance);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"update %ld, current is %ld", (long)accId, (long)self.cwManager.connectedCwCard.currentAccountId);
            if (accId == self.cwManager.connectedCwCard.currentAccountId) {
                [self SetBalanceText];
                [self.cwManager.connectedCwCard setAccount: accId Balance: account.balance];
            } else {
                CwAccount *updateAccount = [self.cwManager.connectedCwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)accId]];
                [self.cwManager.connectedCwCard setAccount: accId Balance: updateAccount.balance];
            }
        });
    });
}

-(void) updateBalanceAndTxs:(NSInteger)accId
{
    NSString *accountId = [NSString stringWithFormat:@"%ld", (long)accId];
    if ([self.txSyncing containsObject:accountId]) {
        [self performDismiss];
        return;
    } else {
        [self.txSyncing addObject:accountId];
        
        [self updateBalance:accId];
        
        //update balance
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [btcNet getTransactionByAccount: accId getAllUtxoCompletion:nil];
        });
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier compare:@"TransactionDetailSegue"] == 0) {
        TabTransactionDetailViewController *target = (TabTransactionDetailViewController *)segue.destinationViewController;
        target.tx = self.selectTx;
    }
}

- (void)CreateAccount{
    if ([self.cwManager.connectedCwCard.hdwAcccountPointer integerValue] < 5) {
        //self.actBusyIndicator.hidden = NO;
        //[self.actBusyIndicator startAnimating];
        [self showIndicatorView:NSLocalizedString(@"Creating Account",nil)];
        
        [self.cwManager.connectedCwCard newAccount:self.cwManager.connectedCwCard.hdwAcccountPointer.integerValue Name:@""];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (account == nil || account.transactions == nil) {
        return 0;
    }
    
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
    
    UILabel *lblTxUTC = (UILabel *)[cell viewWithTag:100];
    lblTxUTC.text = [tx.historyTime_utc cwDateString];
    
    UILabel *lblTxNotes = (UILabel *)[cell viewWithTag:102];
    UILabel *lblTxAmount = (UILabel *)[cell viewWithTag:103];
    lblTxNotes.text = @"";
    
    lblTxAmount.text = (NSString*)[NSString stringWithFormat: @"%@", [tx.historyAmount getBTCDisplayFromUnit]];
    if ([tx.historyAmount.satoshi doubleValue]>0){
        lblTxAmount.text = [NSString stringWithFormat:@"+%@", lblTxAmount.text];
        lblTxAmount.textColor = [UIColor greenColor];
    } else {
        lblTxAmount.textColor = [UIColor redColor];
    }
    for (CwTxout* txout in tx.outputs) {
        NSString* txoutStr = [NSString stringWithFormat:@"%@",txout.tid];
        if ([txoutStr isEqualToString:tx.tx]) {
            lblTxNotes.text = txout.addr;
            break;
        }
    }
    
    return cell;
}

#pragma mark - TableView Delegates

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    self.selectTx = [account.transactions objectForKey:sortedTxKeys[indexPath.row]];
    
    [self performSegueWithIdentifier:@"TransactionDetailSegue" sender:self];
}

#pragma mark - CwCardDelegate

-(void) didGetModeState
{
    NSLog(@"TabbarHomeViewController, card mode = %@", self.cwManager.connectedCwCard.mode);
    if ([self.cwManager.connectedCwCard.mode integerValue] == CwCardModePerso) {
        //goto Setting for Security Policy
        [self performDismiss];
        [self performSegueWithIdentifier:@"SecuritySegue" sender:self];
    }else{
        [self showIndicatorView:NSLocalizedString(@"synchronizing data",nil)];
        [self.cwManager.connectedCwCard syncFromCard];
    }
}

-(void) didGetCwHdwStatus
{
    NSLog(@" TabbarHomeViewController, cwCard.hdwStatus = %@",self.cwManager.connectedCwCard.hdwStatus);
    NSInteger hdwStatus = [self.cwManager.connectedCwCard.hdwStatus integerValue];
    if (hdwStatus == CwHdwStatusInactive || hdwStatus == CwHdwStatusWaitConfirm) {
        //goto New Wallet
        [self performSegueWithIdentifier:@"CreateHdwSegue" sender:self];
    } else {
        [self checkRecoveryState];
        
        [[CwBtcNetWork sharedManager] updateTransactionFees];
        
        [self getBitcoinRateforCurrency];
        [self checkAndLoginExSite];
    }
}

-(void) didGetHosts
{
    NSLog(@"didGetHosts");
}

-(void) didGetCwHdwAccountPointer
{
    //[self performDismiss];
    NSLog(@"TabbarHomeViewController, didGetCwHdwAccointPointer = %@", self.cwManager.connectedCwCard.hdwAcccountPointer);
    if ([self.cwManager.connectedCwCard.hdwAcccountPointer integerValue] == 0) {
        [self CreateAccount];
        self.cwManager.connectedCwCard.currentAccountId = 0;
    }
    else {
        [self setAccountButton];
        //[cwCard getAccounts];
    }
}

-(void) didGetAccountInfo: (NSInteger) accId
{
    NSLog(@"TabbarHomeViewController, didGetAccountInfo = %ld, currentAccountId = %ld", (long)accId, (long)self.cwManager.connectedCwCard.currentAccountId);
    
    if(accId == self.cwManager.connectedCwCard.currentAccountId && !self.waitAccountCreated) {
        isFirst = false;
        [self.cwManager.connectedCwCard getAccountAddresses:accId];
    }
}

-(void) didGetAccountAddresses: (NSInteger) accId
{
    //stop activity indicator of the cess
    //clear the UIActivityIndicatorView
    //create activity indicator on the cell
    
    NSLog(@"TabbarHomeViewController, didGetAccountAddresses = %ld, currentAccountId = %ld", (long)accId, (long)self.cwManager.connectedCwCard.currentAccountId);

    if (accId != self.cwManager.connectedCwCard.currentAccountId) {
        return;
    }
    
    account = (CwAccount *) [self.cwManager.connectedCwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)self.cwManager.connectedCwCard.currentAccountId]];
    
    if (account.lastUpdate == nil) {
        [btcNet registerNotifyByAccount: accId];
        
        [self updateBalanceAndTxs:accId];
    } else {
        [self updateBalance:accId];
        [self performDismiss];
    }
}

-(void) didGetTransactionByAccount:(NSInteger)accId
{
    NSLog(@"TabbarHomeViewController, currAccId: %ld, didGetTransactionByAccount: %ld", (long)self.cwManager.connectedCwCard.currentAccountId, (long)accId);
    //code to be executed in the background
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cwManager.connectedCwCard saveCwCardToFile];
        
        CwAccount *txAccount = (CwAccount *) [self.cwManager.connectedCwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)accId]];
        
        [self.txSyncing removeObject:[NSString stringWithFormat:@"%ld", (long)accId]];
        
        //get address publickey uf the unspent if needed
        for (CwUnspentTxIndex *utx in txAccount.unspentTxs)
        {
            CwAddress *addr;
            //get publickey from address
            if (utx.kcId==0) {
                //External Address
                addr = txAccount.extKeys[utx.kId];
            } else {
                //Internal Address
                addr = txAccount.intKeys[utx.kId];
            }
            
            if (addr.publicKey==nil) {
                [self.cwManager.connectedCwCard getAddressPublickey:accId KeyChainId:utx.kcId KeyId:utx.kId];
            }
        }
        
        if (accId == self.cwManager.connectedCwCard.currentAccountId) {
            NSLog(@"TabbarHomeViewController, prepare to update tx records");
            [self SetTxkeys]; //this includes reloadData
            [self performDismiss];
        }
    });
}

-(void) didNewAccount: (NSInteger)aid
{
    NSLog(@"TabbarHomeViewController, didNewAccount: %ld", (long)aid);
    
    //find CW via BLE
    self.cwManager = [CwManager sharedManager];
    
    [self.cwManager.connectedCwCard genAddress:aid KeyChainId:CwAddressKeyChainExternal];
    
    self.waitAccountCreated = YES;
}

-(void) didSetAccountBalance:(NSInteger)accId
{
    if (setBtnActionFlag) {
        setBtnActionFlag = NO;
    }
    
    if (accId == self.cwManager.connectedCwCard.currentAccountId) {
        [self SetBalanceText];
    }
}

-(void) didGetCwCurrRate
{
    NSLog(@"TabbarHomeViewController, didGetCwCurrRate");
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSString *numberAsString = [numberFormatter stringFromNumber: self.cwManager.connectedCwCard.currRate];
    NSLog(@"TabbarHomeViewController, currRate = %@ ",numberAsString);
    //_lblFaitMoney.text = numberAsString;
    NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithDecimal:[[numberFormatter numberFromString:numberAsString] decimalValue]];
    [self.cwManager.connectedCwCard setCwCurrRate:decNum];
}

-(void) didGenAddress:(CwAddress *)addr
{
    if (self.waitAccountCreated) {
        self.waitAccountCreated = NO;
        
        [self performDismiss];
        [self setAccountButton];
    }
}

- (void) performDismiss
{
    [super performDismiss];
    
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
}

@end
