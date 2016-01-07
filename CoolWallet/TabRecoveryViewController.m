//
//  TabRecoveryViewController.m
//  CwTest
//
//  Created by Coolbitx on 2015/9/10.
//  Copyright (c) 2015年 CoolBitX Technology Ltd. All rights reserved.
//

#import "TabRecoveryViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "CwAccount.h"
#import "CwAddress.h"
#import "CwBtcNetwork.h"
#import "SWRevealViewController.h"

#define MAX_ACCOUNT 5

@interface TabRecoveryViewController ()  <CwManagerDelegate, CwCardDelegate>
{
    CwManager *cwManager;
    CwCard *cwCard;
    CwBtcNetWork *btcNet;
    
    float percent;
    int acc_external;
    int acc_internal;
    
    NSInteger accPtr[5][2]; //store key index of each accounts
    NSMutableArray *extKeySettingFinish;
    NSMutableArray *intKeySettingFinish;
}

@end

@implementation TabRecoveryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"TabRecoveryViewController viewDidLoad");
    
    self.navigationItem.hidesBackButton = YES;
    // Do any additional setup after loading the view.
    cwManager = [CwManager sharedManager];
    cwCard = cwManager.connectedCwCard;
    btcNet = [CwBtcNetWork sharedManager];
    
    percent = 0;
    acc_external = 0;
    acc_internal = 0;
    _progressView.progress = 0;
    extKeySettingFinish = [NSMutableArray new];
    intKeySettingFinish = [NSMutableArray new];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    cwManager.delegate = self;
    cwCard.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"TabRecoveryViewController viewDidAppear");
    
    [cwCard setSecurityPolicy:NO ButtonEnable:YES DisplayAddressEnable:NO WatchDogEnable:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)StartRecovery
{
    for(int i=0; i<MAX_ACCOUNT; i++) {
        accPtr[i][0]=-1;
        accPtr[i][1]=-1;
    }
    
    //check HDW Status
    [cwCard getCwHdwInfo];
}

-(void) recoveryAccount:(CwAccount *)account
{
    if (accPtr[account.accId][CwAddressKeyChainExternal] == -1 || account.extKeyPointer-accPtr[account.accId][CwAddressKeyChainExternal]<CwHdwRecoveryAddressWindow) {
        
        [cwCard genAddress:account.accId KeyChainId:CwAddressKeyChainExternal];
    } else {
        [self addLog: [NSString stringWithFormat:@"HDW accounts %ld external addresses recovered", (long)account.accId]];
    }
    
    if (accPtr[account.accId][CwAddressKeyChainInternal] == -1 || account.intKeyPointer-accPtr[account.accId][CwAddressKeyChainInternal]<CwHdwRecoveryAddressWindow) {
        [cwCard genAddress:account.accId KeyChainId:CwAddressKeyChainInternal];
    } else {
        [self addLog: [NSString stringWithFormat:@"HDW accounts %ld internal addresses recovered", (long)account.accId]];
    }
}

-(void) didSetSecurityPolicy
{    
    if (cwCard.securityPolicy_WatchDogEnable.boolValue) {
        [self StartRecovery];
    } else {
        if (acc_external == MAX_ACCOUNT && acc_internal == MAX_ACCOUNT) {
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
            UIViewController * vc = [sb instantiateViewControllerWithIdentifier:@"CwAccount"];
            [self.revealViewController pushFrontViewController:vc animated:YES];
        }
    }
}

-(void) didGetCwHdwStatus {
    if (cwCard.hdwStatus.integerValue != CwHdwStatusActive) {
        [self addLog: @"HDW is not created"];
    } else {
        [self addLog: @"HDW status is ready"];
    }
}

-(void) didGetCwHdwAccountPointer {
    if (cwCard.hdwStatus.integerValue != CwHdwStatusActive) {
        [self addLog: @"HDW is not created"];
    }
    [self addLog:[NSString stringWithFormat:@"HdwAcccountPointer: %@", cwCard.hdwAcccountPointer]];
    for (int i = 0; i < MAX_ACCOUNT; i++) {
        if (i < cwCard.hdwAcccountPointer.integerValue) {
            [cwCard getAccountInfo:i];
        } else {
            [cwCard newAccount:i Name:@""];
        }
    }
    
    if (cwCard.hdwAcccountPointer.integerValue == 5) {
        [self addLog: @"HDW accounts are ready"];
    }
}

-(void) didNewAccount: (NSInteger)aid {

    [self addLog: [NSString stringWithFormat:@"HDW accounts %ld is created", (long)aid]];
    
    if ([cwCard.hdwAcccountPointer integerValue] == 5) {
        [self addLog: @"HDW accounts are ready"];
    }
}

-(void) didGetAccountInfo:(NSInteger)accId {
    CwAccount *acc = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)accId]];
    [self performSelectorInBackground:@selector(recoveryAccount:) withObject:acc];
}

-(void) didGenAddress:(CwAddress *)addr {
    [self performSelectorOnMainThread:@selector(setProgressPercent) withObject:nil waitUntilDone:NO];
    
    CwAccount *acc = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)addr.accountId]];
    
    addr = [self checkTransactions:addr];
    
    //set address back to acc
    if (addr.keyChainId==CwAddressKeyChainExternal)
        acc.extKeys[addr.keyId] = addr;
    else
        acc.intKeys[addr.keyId] = addr;
    
    [cwCard.cwAccounts setObject:acc forKey:[NSString stringWithFormat: @"%ld", (long)acc.accId]];

    [self addLog: [NSString stringWithFormat:@"HDW accounts %ld keychain %ld addresses %ld created, trx:%lu", (long)addr.accountId, (long)addr.keyChainId, (long)addr.keyId, (unsigned long)addr.historyTrx.count]];
    
    //gen address if the empty address < CwHdwRecoveryAddressWindow
    if (addr.keyChainId==CwAddressKeyChainExternal) {
        if (accPtr[addr.accountId][addr.keyChainId] == -1 || acc.extKeyPointer-accPtr[addr.accountId][addr.keyChainId]<CwHdwRecoveryAddressWindow) {
            [cwCard genAddress:addr.accountId KeyChainId:addr.keyChainId];
        } else{
            acc_external++;
            [self performSelectorOnMainThread:@selector(setProgressPercent) withObject:nil waitUntilDone:NO];
            [self addLog: [NSString stringWithFormat:@"HDW accounts %ld external addresses recovered", (long)addr.accountId]];
        }
    } else {
        if (accPtr[addr.accountId][addr.keyChainId] == -1 || acc.intKeyPointer-accPtr[addr.accountId][addr.keyChainId]<CwHdwRecoveryAddressWindow)
            [cwCard genAddress:addr.accountId KeyChainId:addr.keyChainId];
        else{
            acc_internal++;
            [self performSelectorOnMainThread:@selector(setProgressPercent) withObject:nil waitUntilDone:NO];
            [self addLog: [NSString stringWithFormat:@"HDW accounts %ld internal addresses recovered", (long)addr.accountId]];
        }
    }
}

-(void) didSetAccountExtKeyPtr:(NSInteger)accId keyPtr:(NSInteger)keyPtr
{
    if(acc_external == MAX_ACCOUNT && acc_internal == MAX_ACCOUNT) {
        CwAccount *account = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)accId]];
        if (keyPtr == account.extKeyPointer) {
            [extKeySettingFinish addObject:account];
        } else if ([extKeySettingFinish containsObject:account]) {
            [extKeySettingFinish removeObject:account];
        }
        
        [self finishRecovery];
    }
}

-(void) didSetAccountIntKeyPtr:(NSInteger)accId keyPtr:(NSInteger)keyPtr
{
    if(acc_external == MAX_ACCOUNT && acc_internal == MAX_ACCOUNT) {
        CwAccount *account = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)accId]];
        if (keyPtr == account.intKeyPointer) {
            [intKeySettingFinish addObject:account];
        } else if ([intKeySettingFinish containsObject:account]) {
            [intKeySettingFinish removeObject:account];
        }
        
        [self finishRecovery];
    }
}

-(void)didGenAddressError
{
    //TODO: do something?
}

-(CwAddress *) checkTransactions:(CwAddress *)address
{
    NSDictionary *trxs = [btcNet queryHistoryTxs:@[address.address]];
    if (trxs == nil || trxs.count == 0) {
        if (accPtr[address.accountId][address.keyChainId] == -1) {
            accPtr[address.accountId][address.keyChainId] = address.keyId;
        }
    } else {
        address.historyTrx = [trxs objectForKey:address.address];
        if (address.historyTrx.count > 0) {
            accPtr[address.accountId][address.keyChainId] = -1;
        } else {
            if (accPtr[address.accountId][address.keyChainId] == -1) {
                accPtr[address.accountId][address.keyChainId] = address.keyId;
            }
        }
    }
    
    return address;
}

-(void) addLog: (NSString *)log {
    NSString *msg = [log stringByAppendingString:@"\n"];
    NSLog(@"%@",msg);
}

-(void) setProgressPercent
{
    if(percent <= 0.9) {
        percent += 0.012;
        float limitPerAccount = 0.9 / (MAX_ACCOUNT * 2.0);
        float maxPercentPerAccount = limitPerAccount * (acc_external + acc_internal + 2);
        float minPercentPerAccount = limitPerAccount * (acc_external + acc_internal);
        
        if (percent > maxPercentPerAccount) {
            percent = maxPercentPerAccount;
        } else if (percent < minPercentPerAccount) {
            percent = minPercentPerAccount;
        }
    }

    NSLog(@"Progress = %f",percent);
    _progressView.progress = percent;
    
    if(acc_external == MAX_ACCOUNT && acc_internal == MAX_ACCOUNT) {
        [cwCard cmdClear];
        
        for (CwAccount *account in [cwCard.cwAccounts allValues]) {
            [cwCard setAccount:account.accId ExtKeyPtr:account.extKeyPointer];
            [cwCard setAccount:account.accId IntKeyPtr:account.intKeyPointer];
        }
    }
}

-(void) finishRecovery
{
    for (CwAccount *account in [cwCard.cwAccounts allValues]) {
        if (account.externalKeychain.extendedPublicKey == nil || account.internalKeychain.extendedPublicKey == nil) {
            continue;
        }
        if (![extKeySettingFinish containsObject:account] || ![intKeySettingFinish containsObject:account]) {
            return;
        }
    }
    
    for (CwAccount *account in [cwCard.cwAccounts allValues]) {
        [btcNet refreshTxsFromAccountAddresses:account];
    }
    
    _progressView.progress = 1;
    
    [cwCard saveCwCardToFile];
    
    [cwCard setSecurityPolicy:NO ButtonEnable:YES DisplayAddressEnable:NO WatchDogEnable:NO];
}

#pragma marks - CwManagerDelegates

-(void) didDisconnectCwCard: (NSString *) cwCardName
{
    NSLog(@"CW %@ Disconnected", cwCardName);
    
    // Get the storyboard named secondStoryBoard from the main bundle:
    UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // Load the view controller with the identifier string myTabBar
    // Change UIViewController to the appropriate class
    UIViewController *listCV = (UIViewController *)[secondStoryBoard instantiateViewControllerWithIdentifier:@"CwMain"];
    
    // Then push the new view controller in the usual way:
    [self.parentViewController presentViewController:listCV animated:YES completion:nil];
}

@end
