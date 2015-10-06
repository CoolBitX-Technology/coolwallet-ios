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

CwBtcNetWork *btcNet;
CwAccount *account;
NSArray *sortedTxKeys;

NSDictionary *rates;
NSInteger rowSelect;

bool isFirst = YES;

@implementation TabbarHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    
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
    
    [self getBitcoinRateforCurrency];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    cwManager.delegate = self;
    cwCard.delegate = self;
    btcNet.delegate = self;
    
     NSLog(@"accid = %d",cwCard.currentAccountId);
    //[self showIndicatorView:@"synchronizing data"];
    //self.actBusyIndicator.hidden = NO;
    //[self.actBusyIndicator startAnimating];
    
}

-(void)viewDidAppear:(BOOL)animated {
    NSLog(@"viewDidAppear");
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
    NSLog(@"cwAccounts = %ld", [cwCard.cwAccounts count]);
    for(int i =0; i< [cwCard.cwAccounts count]; i++) {
        if(i == 0) {
            _btnAccount1.hidden = NO;
        }else if(i == 1) {
            _btnAccount2.hidden = NO;
        }else if(i == 2) {
            _btnAccount3.hidden = NO;
        }else if(i == 3) {
            _btnAccount4.hidden = NO;
        }else if(i == 4) {
            _btnAccount5.hidden = NO;
            _btnAccount5.enabled = YES;
            _btnAddAccount.hidden = YES;
            _imgAddAccount.hidden = YES;
        }
        
    }
    NSLog(@"accid = %ld",cwCard.currentAccountId);
    if([cwCard.cwAccounts count] == 1) {
        [_btnAccount1 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }else{
        switch (cwCard.currentAccountId) {
            case 0:
                [_btnAccount1 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            case 1:
                [_btnAccount2 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            case 2:
                [_btnAccount3 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            case 3:
                [_btnAccount4 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            case 4:
                [_btnAccount5 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            default:
                break;
        }
    }
    
}

- (IBAction)btnAccount1:(id)sender {
    [_btnAccount1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [_btnAccount2 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount3 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount4 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount5 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    [_btnAccount1 setBackgroundColor:[UIColor colorAccountBackground]];
    
    [_btnAccount2 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount3 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount4 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount5 setBackgroundColor:[UIColor blackColor]];
    
    if(cwCard.currentAccountId != 0 || isFirst) {
        isFirst = NO;
        cwCard.currentAccountId = 0;
        [cwCard setDisplayAccount:cwCard.currentAccountId];
        [cwCard getAccountInfo:cwCard.currentAccountId];
    }
    
    [self SetBalanceText];
    [self SetTxkeys];
}

- (IBAction)btnAccount2:(id)sender {
    [_btnAccount2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [_btnAccount1 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount3 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount4 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount5 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    [_btnAccount2 setBackgroundColor:[UIColor colorAccountBackground]];
    [_btnAccount1 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount3 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount4 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount5 setBackgroundColor:[UIColor blackColor]];
    
    if(cwCard.currentAccountId != 1) {
        cwCard.currentAccountId = 1;
        [cwCard setDisplayAccount:cwCard.currentAccountId];
        [cwCard getAccountInfo:cwCard.currentAccountId];
    }
    
    [self SetBalanceText];
    [self SetTxkeys];
}

- (IBAction)btnAccount3:(id)sender {
    [_btnAccount3 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [_btnAccount2 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount1 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount4 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount5 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    [_btnAccount3 setBackgroundColor:[UIColor colorAccountBackground]];
    [_btnAccount1 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount2 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount4 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount5 setBackgroundColor:[UIColor blackColor]];
    
    if(cwCard.currentAccountId != 2) {
    cwCard.currentAccountId = 2;
    [cwCard setDisplayAccount:cwCard.currentAccountId];
    [cwCard getAccountInfo:cwCard.currentAccountId];
    }
    [self SetBalanceText];
    
    [self SetTxkeys];
}

- (IBAction)btnAccount4:(id)sender {
    [_btnAccount4 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [_btnAccount2 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount3 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount1 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount5 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    [_btnAccount4 setBackgroundColor:[UIColor colorAccountBackground]];
    [_btnAccount1 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount2 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount3 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount5 setBackgroundColor:[UIColor blackColor]];
    
    if(cwCard.currentAccountId != 3) {
    cwCard.currentAccountId = 3;
    [cwCard setDisplayAccount:cwCard.currentAccountId];
    [cwCard getAccountInfo:cwCard.currentAccountId];
    }
    [self SetBalanceText];
    
    [self SetTxkeys];
}

- (IBAction)btnAccount5:(id)sender {
    [_btnAccount5 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [_btnAccount2 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount3 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount4 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnAccount1 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    [_btnAccount5 setBackgroundColor:[UIColor colorAccountBackground]];
    [_btnAccount1 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount2 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount3 setBackgroundColor:[UIColor blackColor]];
    [_btnAccount4 setBackgroundColor:[UIColor blackColor]];
    
    if(cwCard.currentAccountId != 4) {
    cwCard.currentAccountId = 4;
    [cwCard setDisplayAccount:cwCard.currentAccountId];
    [cwCard getAccountInfo:cwCard.currentAccountId];
    }
    [self SetBalanceText];
    
    [self SetTxkeys];
}

Boolean setBtnActionFlag;
- (void)SetBalanceText
{
    NSLog(@"SetBalanceText");
    CwAccount *account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", cwCard.currentAccountId]];
    //_lblBalance.text = [NSString stringWithFormat: @"%lld BTC", (int64_t)account.balance];
    _lblBalance.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertBTCStringformUnit: (int64_t)account.balance], [[OCAppCommon getInstance] BitcoinUnit]];
    
    _lblFaitMoney.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertFiatMoneyString:(int64_t)account.balance currRate:cwManager.connectedCwCard.currRate], cwCard.currId];
    
    /*
    if(cwCard.currentAccountId == 0) {
        if(account.balance == 0) {
            //update account balance
            setBtnActionFlag = YES;
            [cwCard setAccount: cwCard.currentAccountId Balance: 1L];
        }
    }*/
}

- (void)SetTxkeys
{
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", cwCard.currentAccountId]];
    
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
    
    NSLog(@"trans = %ld",[account.transactions count]);
    [_tableTransaction reloadData];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier compare:@"TransactionDetailSegue"] == 0) {
        NSLog(@"rowSelect = %d",rowSelect);
        id page = segue.destinationViewController;
        id TxKey = sortedTxKeys[rowSelect];
        [page setValue:TxKey forKey:@"TxKey"];
    }
}

#pragma marks - Actions
- (IBAction)btnAddAccount:(id)sender {
    NSLog(@"btnAddAccount");
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
    NSLog(@"tx");
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
    if ([tx.historyAmount.satoshi intValue]>0){
        lblTxAmount.text = [NSString stringWithFormat: @"+%g", tx.historyAmount.BTC.doubleValue];
        lblTxAmount.textColor = [UIColor greenColor];
        
        if(tx.inputs.count > 0) {
            CwTxin* txin = (CwTxin *)[tx.inputs objectAtIndex:0];
            lblTxNotes.text = txin.addr;
        }
    }else{
        lblTxAmount.text = [NSString stringWithFormat: @"%g", tx.historyAmount.BTC.doubleValue];
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
    NSLog(@"didCwCardCommand");
    if(cwCard.hdwAcccountPointer > 0) [self setAccountButton];
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
    NSLog(@"card mode = %ld", cwCard.mode);
    if (cwCard.mode ==CwCardModePerso) {
        //goto Setting for Security Policy
        [self performSegueWithIdentifier:@"SecuritySegue" sender:self];
    }else{
        [cwCard syncFromCard];
    }
}

-(void) didGetCwHdwStatus
{
    NSLog(@" cwCard.hdwStatus = %d",cwCard.hdwStatus);
    if (cwCard.hdwStatus == CwHdwStatusInactive || cwCard.hdwStatus == CwHdwStatusWaitConfirm) {
        //goto New Wallet
        [self performSegueWithIdentifier:@"CreateHdwSegue" sender:self];
    }
}

-(void) didGetCwHdwAccountPointer
{
    //[self performDismiss];
    NSLog(@"didGetCwHdwAccointPointer = %ld", cwCard.hdwAcccountPointer);
    if (cwCard.hdwAcccountPointer == 0) {
        [self CreateAccount];
        cwCard.currentAccountId = 0;
    }
    else {
        [self showIndicatorView:@"synchronizing data"];
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
    NSLog(@"didGetAccountInfo = %ld, currentAccountId = %ld", accId, cwCard.currentAccountId);
    
    if(accId == cwCard.currentAccountId) {
        [cwCard getAccountAddresses:accId];
    }
}

-(void) didGetAccountAddresses: (NSInteger) accId
{
    //stop activity indicator of the cess
    //clear the UIActivityIndicatorView
    //create activity indicator on the cell
    
    if(accId == cwCard.currentAccountId) {
        [self showIndicatorView:@"synchronizing data"];
        
        if (account.transactions==nil) {
            //get balance and transaction when there is no transaction yet.
            
            dispatch_queue_t queue = dispatch_queue_create("com.dtco.CoolWallet", NULL);
            
            dispatch_async(queue, ^{
                [btcNet registerNotifyByAccount: accId];
                
                //update balance
                [btcNet getBalanceByAccount: accId]; //this will update the CwCard.account
                [self SetBalanceText];
                [cwCard setAccount: accId Balance: account.balance];
                
                [btcNet getTransactionByAccount: accId]; //this will update the CwCard.transaction
            });
        }
    }
}

-(void) didGetTransactionByAccount:(NSInteger)accId
{
    //code to be executed in the background
    dispatch_async(dispatch_get_main_queue(), ^{
        //code to be executed on the main thread when background task is finished
        //account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", accId]];
        //NSLog(@"account tx count = %lu", (unsigned long)account.transactions.count );
        //[cwCard setAccount: accId Balance: account.balance];
        
        if (accId == cwCard.currentAccountId) {
            [self SetTxkeys]; //this includes reloadData
        }
        
        //[_tableTransaction reloadData];
        [self performDismiss];
    });
}

-(void) didNewAccount: (NSInteger)aid
{
    [self performDismiss];
    //find CW via BLE
    cwManager = [CwManager sharedManager];
    
    cwCard = cwManager.connectedCwCard;
    [cwCard genAddress:aid KeyChainId:CwAddressKeyChainExternal];
    
    [self setAccountButton];
}

-(void) didSetAccountBalance
{
    
    if (setBtnActionFlag) {
        setBtnActionFlag = NO;
    }
}

-(void) didGetCwCurrRate
{
    NSLog(@"didGetCwCurrRate");
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSString *numberAsString = [numberFormatter stringFromNumber: cwManager.connectedCwCard.currRate];
    NSLog(@"currRate = %@ ",numberAsString);
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


- (void) showIndicatorView:(NSString *)Msg {
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
        //mHUD = nil;
    }
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    NSLog(@"didDisconnectCwCard");
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
