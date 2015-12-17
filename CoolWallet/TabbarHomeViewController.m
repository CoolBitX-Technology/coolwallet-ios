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
#import "NSDate+Localize.h"

#import "BlockChain.h"

CwBtcNetWork *btcNet;
CwAccount *account;
NSArray *sortedTxKeys;

NSDictionary *rates;
NSInteger rowSelect;

bool isFirst = YES;

@interface TabbarHomeViewController ()
{
//    CwCard *cwCard;
}

@property (strong, nonatomic) NSArray *accountButtons;
@property (assign, nonatomic) BOOL waitAccountCreated;
@property (strong, nonatomic) NSMutableArray *txSyncing;

@end

@implementation TabbarHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"TabbarHomeViewController, viewDidLoad");
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(setAccountButton) forControlEvents:UIControlEventValueChanged];
    [self.tableTransaction addSubview:self.refreshControl]; //把RefreshControl加到TableView中
    
    btcNet = [CwBtcNetWork sharedManager];

    btcNet.delegate = self;
    
    self.accountButtons = @[self.btnAccount1, self.btnAccount2, self.btnAccount3, self.btnAccount4, self.btnAccount5];
    self.txSyncing = [NSMutableArray new];
    
    [self performSelectorOnMainThread:@selector(getBitcoinRateforCurrency) withObject:nil waitUntilDone:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    btcNet.delegate = self;
    
    NSLog(@"accid = %ld",self.cwManager.connectedCwCard.currentAccountId);
    if (account != nil) {
        [self setAccountButton];
    } else if (self.cwManager.connectedCwCard.currentAccountId != 0) {
        self.cwManager.connectedCwCard.currentAccountId = 0;
        [self.cwManager.connectedCwCard setDisplayAccount:0];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    self.cwManager.delegate = nil;
    self.cwManager.connectedCwCard.delegate = nil;
    btcNet.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) getBitcoinRateforCurrency
{
    [self showIndicatorView:@"synchronizing data"];
    
    rates = [btcNet getCurrRate];
    
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
    NSLog(@"TabbarHomeViewController, cwAccounts = %ld", [self.cwManager.connectedCwCard.cwAccounts count]);
    
    for(int i =0; i< [self.cwManager.connectedCwCard.cwAccounts count]; i++) {
        UIButton *accountBtn = [self.accountButtons objectAtIndex:i];
        accountBtn.hidden = NO;
        
        if (i == self.accountButtons.count-1) {
            accountBtn.enabled = YES;
            self.btnAddAccount.hidden = YES;
            self.imgAddAccount.hidden = YES;
        }
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
            [btn setBackgroundColor:[UIColor colorAccountBackground]];
            [btn setSelected:YES];
        } else {
            [btn setBackgroundColor:[UIColor blackColor]];
            [btn setSelected:NO];
        }
    }
    
    account = (CwAccount *) [self.cwManager.connectedCwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", self.cwManager.connectedCwCard.currentAccountId]];
    
    if (currentAccId != self.cwManager.connectedCwCard.currentAccountId || isFirst) {
        [self showIndicatorView:@"synchronizing data"];
        
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
    
    _lblBalance.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertBTCStringformUnit: (int64_t)account.balance], [[OCAppCommon getInstance] BitcoinUnit]];
    
    _lblFaitMoney.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertFiatMoneyString:(int64_t)account.balance currRate:self.cwManager.connectedCwCard.currRate], self.cwManager.connectedCwCard.currId];
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
    NSString *accountId = [NSString stringWithFormat:@"%ld", accId];
    if ([self.txSyncing containsObject:accountId]) {
        return;
    } else {
        [self.txSyncing addObject:accountId];
        
        //update balance
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //Do background work
            BlockChain *blockChain = [[BlockChain alloc] init];
            [blockChain getBalanceByAccountID:accId];
            
            [btcNet getTransactionByAccount: accId];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //Update UI
                NSLog(@"update %ld, current is %ld", accId, self.cwManager.connectedCwCard.currentAccountId);
                if (accId == self.cwManager.connectedCwCard.currentAccountId) {
                    [self SetBalanceText];
                    [self.cwManager.connectedCwCard setAccount: accId Balance: account.balance];
                } else {
                    CwAccount *updateAccount = [self.cwManager.connectedCwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", accId]];
                    [self.cwManager.connectedCwCard setAccount: accId Balance: updateAccount.balance];
                }
            });
        });
    }
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
    if ([self.cwManager.connectedCwCard.hdwAcccountPointer integerValue] < 5) {
        //self.actBusyIndicator.hidden = NO;
        //[self.actBusyIndicator startAnimating];
        [self showIndicatorView:@"Creating Account"];
        
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
    //CwTx *tx = [account.transactions objectForKey: [NSString stringWithFormat:@"%d",indexPath.row]];
    
    UILabel *lblTxUTC = (UILabel *)[cell viewWithTag:100];
    lblTxUTC.text = [tx.historyTime_utc cwDateString];
    
    //lblTxUTC.text = [NSString stringWithFormat: @"%@", tx.historyTime_utc];
    UILabel *lblTxNotes = (UILabel *)[cell viewWithTag:102];
    //lblTxNotes.text = [NSString stringWithFormat: @"%@", tx.tid];
    UILabel *lblTxAmount = (UILabel *)[cell viewWithTag:103];
    
    lblTxAmount.text = [NSString stringWithFormat: @"%@", [tx.historyAmount getBTCDisplayFromUnit]];
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

-(void) didGetModeState
{
    NSLog(@"TabbarHomeViewController, card mode = %@", self.cwManager.connectedCwCard.mode);
    if ([self.cwManager.connectedCwCard.mode integerValue] == CwCardModePerso) {
        //goto Setting for Security Policy
        [self performDismiss];
        [self performSegueWithIdentifier:@"SecuritySegue" sender:self];
    }else{
        [self showIndicatorView:@"synchronizing data"];
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
    NSLog(@"TabbarHomeViewController, didGetAccountInfo = %ld, currentAccountId = %ld", accId, self.cwManager.connectedCwCard.currentAccountId);
    
    if(accId == self.cwManager.connectedCwCard.currentAccountId) {
        [self.cwManager.connectedCwCard getAccountAddresses:accId];
    }
}

-(void) didGetAccountAddresses: (NSInteger) accId
{
    //stop activity indicator of the cess
    //clear the UIActivityIndicatorView
    //create activity indicator on the cell
    
    NSLog(@"TabbarHomeViewController, didGetAccountAddresses = %ld, currentAccountId = %ld", accId, self.cwManager.connectedCwCard.currentAccountId);

    if (accId != self.cwManager.connectedCwCard.currentAccountId) {
        return;
    }
    
    account = (CwAccount *) [self.cwManager.connectedCwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", self.cwManager.connectedCwCard.currentAccountId]];
    
    if (account.lastUpdate == nil) {
        if (account.transactions.count > 0) {
            [self performDismiss];
        }
        
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
    NSLog(@"TabbarHomeViewController, currAccId: %ld, didGetTransactionByAccount: %ld", self.cwManager.connectedCwCard.currentAccountId, accId);
    //code to be executed in the background
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cwManager.connectedCwCard saveCwCardToFile];
        
        CwAccount *txAccount = (CwAccount *) [self.cwManager.connectedCwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", accId]];
        
        [self.txSyncing removeObject:[NSString stringWithFormat:@"%ld", accId]];
        
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
    NSLog(@"TabbarHomeViewController, didNewAccount: %ld", aid);
    
    //find CW via BLE
    self.cwManager = [CwManager sharedManager];
    
    [self.cwManager.connectedCwCard genAddress:aid KeyChainId:CwAddressKeyChainExternal];
    
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
    NSString *numberAsString = [numberFormatter stringFromNumber: self.cwManager.connectedCwCard.currRate];
    NSLog(@"TabbarHomeViewController, currRate = %@ ",numberAsString);
    //_lblFaitMoney.text = numberAsString;
    NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithDecimal:[[numberFormatter numberFromString:numberAsString] decimalValue]];
    [self.cwManager.connectedCwCard setCwCurrRate:decNum];
    
    _lblFaitMoney.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertFiatMoneyString:(int64_t)account.balance currRate:self.cwManager.connectedCwCard.currRate], self.cwManager.connectedCwCard.currId];
    //self.txtExchangeRage.text = numberAsString;
}


-(void) didSetCwCurrRate
{
    //get mode state
    [self.cwManager.connectedCwCard getModeState];
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
