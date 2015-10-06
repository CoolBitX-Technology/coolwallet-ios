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

@interface TabRecoveryViewController ()  <CwManagerDelegate, CwCardDelegate>

@property (weak, nonatomic) IBOutlet UITextView *txtRecoveryLog;
- (IBAction)btnRecovery:(id)sender;

@end

CwManager *cwManager;
CwCard *cwCard;
CwBtcNetWork *btcNet;

float percent = 0;
int acc_external = 0;
int acc_internal = 0;

NSInteger accPtr[5][2]; //store key index of each accounts

@implementation TabRecoveryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    // Do any additional setup after loading the view.
    cwManager = [CwManager sharedManager];
    cwCard = cwManager.connectedCwCard;
    btcNet = [CwBtcNetWork sharedManager];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _progressView.progress = 0;
    cwManager.delegate = self;
    cwCard.delegate = self;
    //self.txtRecoveryLog.text= @"";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"viewDidAppear");
    [self StartRecovery];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)StartRecovery
{
    for(int i=0; i<5; i++) {
        accPtr[i][0]=-1;
        accPtr[i][1]=-1;
    }
    
    //check HDW Status
    [cwCard getCwHdwInfo];
}

- (IBAction)btnRecovery:(id)sender {
    self.txtRecoveryLog.text= @"";
    [self addLog: @"Recovery begin"];
    
    
    for(int i=0; i<5; i++) {
        accPtr[i][0]=-1;
        accPtr[i][1]=-1;
    }

    //check HDW Status
    [cwCard getCwHdwInfo];
    
    //check Accounts
    //check Account Addresses
}

-(void) didGetCwHdwStatus {
    if (cwCard.hdwStatus!=CwHdwStatusActive) {
        [self addLog: @"HDW is not created"];
    } else {
        [self addLog: @"HDW status is ready"];
    }
}

-(void) didGetCwHdwAccountPointer {
    if (cwCard.hdwStatus!=CwHdwStatusActive) {
        [self addLog: @"HDW is not created"];
    }

    //if pointer is less then 5, creat all the rest of accounts
    for (NSInteger i=cwCard.hdwAcccountPointer; i<5; i++) {
        [cwCard newAccount:i Name:@""];
    }
    
    if (cwCard.hdwAcccountPointer==5) {
        [self addLog: @"HDW accounts are ready"];
        for (int i=0; i<cwCard.hdwAcccountPointer; i++)
            [cwCard getAccountInfo: i];
    }
}

-(void) didNewAccount: (NSInteger)aid {

    [self addLog: [NSString stringWithFormat:@"HDW accounts %ld is created", (long)aid]];
    
    if (cwCard.hdwAcccountPointer==5) {
        [self addLog: @"HDW accounts are ready"];
        for (int i=0; i<cwCard.hdwAcccountPointer; i++)
            [cwCard getAccountInfo: i];
    }
}

-(void) didGetAccountInfo:(NSInteger)accId {
    CwAccount *acc = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)accId]];
    
    //check existing ext keys
    for (int i=0; i<acc.extKeyPointer; i++) {
        //check transactions of each keys
        CwAddress *addr = acc.extKeys[i];
        NSMutableArray *addrTxs;
        
        [btcNet getHistoryTxsByAddr:addr.address txs: &addrTxs];
        
        addr.historyTrx = addrTxs;
        
        //set address back to acc
        if (addr.keyChainId==CwAddressKeyChainExternal)
            acc.extKeys[addr.keyId] = addr;
        else
            acc.intKeys[addr.keyId] = addr;
        
        [cwCard.cwAccounts setObject:acc forKey:[NSString stringWithFormat: @"%ld", acc.accId]];
        
        if (addrTxs.count>0) {
            //clear the counter
            accPtr[accId][CwAddressKeyChainExternal]=-1;
        }
        
        if (addrTxs.count==0) {
            if (accPtr[accId][CwAddressKeyChainExternal]==-1)
                accPtr[accId][CwAddressKeyChainExternal]=addr.keyId;
        }
    }
    
    //gen address if the empty address < CwHdwRecoveryAddressWindow
    if (accPtr[accId][CwAddressKeyChainExternal] == -1 || acc.extKeyPointer-accPtr[accId][CwAddressKeyChainExternal]<CwHdwRecoveryAddressWindow) {
        [cwCard genAddress:accId KeyChainId:CwAddressKeyChainExternal];
    } else {
        [self addLog: [NSString stringWithFormat:@"HDW accounts %ld external addresses recovered", (long)accId]];
    }
    
    //check int keys
    for (int i=0; i<acc.intKeyPointer; i++) {
        //check transactions of each keys
        CwAddress *addr = acc.intKeys[i];
        NSMutableArray *addrTxs;
        
        [btcNet getHistoryTxsByAddr:addr.address txs: &addrTxs];
        
        if (addrTxs.count>0) {
            //clear the counter
            accPtr[accId][CwAddressKeyChainInternal]=-1;
        }
        
        if (addrTxs.count==0) {
            if (accPtr[accId][CwAddressKeyChainInternal]==-1)
                accPtr[accId][CwAddressKeyChainInternal]=addr.keyId;
        }
    }
    
    //gen address if the empty address < 20
    if (accPtr[accId][CwAddressKeyChainInternal] == -1 || acc.intKeyPointer-accPtr[accId][CwAddressKeyChainInternal]<CwHdwRecoveryAddressWindow) {
        [cwCard genAddress:accId KeyChainId:CwAddressKeyChainInternal];
    } else {
        [self addLog: [NSString stringWithFormat:@"HDW accounts %ld internal addresses recovered", (long)accId]];
    }
}

-(void) didGenAddress:(CwAddress *)addr {
    [self setProgressPercent];
    CwAccount *acc = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)addr.accountId]];
    NSMutableArray *addrTxs;
    
    [btcNet getHistoryTxsByAddr:addr.address txs: &addrTxs];
    
    addr.historyTrx = addrTxs;
    
    //set address back to acc
    if (addr.keyChainId==CwAddressKeyChainExternal)
        acc.extKeys[addr.keyId] = addr;
    else
        acc.intKeys[addr.keyId] = addr;
    
    [cwCard.cwAccounts setObject:acc forKey:[NSString stringWithFormat: @"%ld", acc.accId]];

    [self addLog: [NSString stringWithFormat:@"HDW accounts %ld keychain %ld addresses %ld created, trx:%ld", (long)addr.accountId, addr.keyChainId, addr.keyId, addrTxs.count]];

    if (addrTxs.count>0) {
        //clear the counter
        accPtr[addr.accountId][addr.keyChainId]=-1;
    }
    
    if (addrTxs.count==0) {
        if (accPtr[addr.accountId][addr.keyChainId]==-1)
            accPtr[addr.accountId][addr.keyChainId]=addr.keyId;
    }
    
    //gen address if the empty address < CwHdwRecoveryAddressWindow
    if (addr.keyChainId==CwAddressKeyChainExternal) {
        if (accPtr[addr.accountId][addr.keyChainId] == -1 || acc.extKeyPointer-accPtr[addr.accountId][addr.keyChainId]<CwHdwRecoveryAddressWindow) {
            [cwCard genAddress:addr.accountId KeyChainId:addr.keyChainId];
            
        } else{
            acc_external++;
            [self setProgressPercent];
            [self addLog: [NSString stringWithFormat:@"HDW accounts %ld external addresses recovered", (long)addr.accountId]];
        }
    } else {
        if (accPtr[addr.accountId][addr.keyChainId] == -1 || acc.intKeyPointer-accPtr[addr.accountId][addr.keyChainId]<CwHdwRecoveryAddressWindow)
            [cwCard genAddress:addr.accountId KeyChainId:addr.keyChainId];
        else{
            acc_internal++;
            [self setProgressPercent];
            [self addLog: [NSString stringWithFormat:@"HDW accounts %ld internal addresses recovered", (long)addr.accountId]];
        }
    }
}

-(void) addLog: (NSString *)log {
    NSString *msg = [log stringByAppendingString:@"\n"];
    NSLog(@"%@",msg);
    //self.txtRecoveryLog.text = [self.txtRecoveryLog.text stringByAppendingString:msg];
}

-(void) setProgressPercent
{
    if(percent <0.9) {
        percent += 0.012;
    }

    NSLog(@"Progress = %f",percent);
    _progressView.progress = percent;
    
    if(acc_external == 5 && acc_internal == 5) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
        UIViewController * vc = [sb instantiateViewControllerWithIdentifier:@"CwAccount"];
        [self.revealViewController pushFrontViewController:vc animated:YES];
    }
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
