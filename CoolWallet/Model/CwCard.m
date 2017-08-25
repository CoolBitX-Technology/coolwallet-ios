//
//  CwCard.m
//  CwTest
//
//  Created by CP Hsiao on 2014/11/27.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>

#import <CoreBitcoin/CoreBitcoin.h>

#import "CwCard.h"
#import "CwCardApduError.h"
#import "CwHost.h"
#import "CwAddress.h"
#import "CwCardInfo.h"
#import "CwKeychain.h"

#import "CwBtcNetwork.h"

#import "CwCommandDefine.h"
#import "CwCardCommand.h"
#import "KeychainItemWrapper.h"

#import "CwTx.h"
#import "CwTxin.h"
#import "CwTxout.h"
#import "CwUnspentTxIndex.h"
#import "CwBase58.h"

#import "OCAppCommon.h"

#import "NSUserDefaults+RMSaveCustomObject.h"
#import "NSString+HexToData.h"

#import "mpbn_util.h"
#import "tx.h"

@interface RMMapper(CwCard)

@end

@implementation RMMapper(CwCard)

+ (NSArray *)systemExcludedProperties {
    return @[@"observationInfo",@"hash",@"description",@"debugDescription",@"superclass",
             @"exSessionInitCompleteBlock", @"exSessionInitErrorBlock",
             @"exSessionEstablishCompleteBlock", @"exSessionEstablishErrorBlock",
             @"exBlockBtcCompleteBlock", @"exBlockBtcErrorBlock",
             @"exTrxSignLoginCompleteBlock", @"exTrxSignLoginErrorBlock",
             @"exBlockCancelCompleteBlock", @"exBlockCancelErrorBlock",
             @"exBlockInfoCompleteBlock", @"exBlockInfoErrorBlock",
             @"exTrxSignLogoutCompleteBlock", @"exTrxSignLogoutErrorBlock"];
}

@end

@interface CwCard () <CBPeripheralDelegate>

@property (copy) void (^exSessionInitCompleteBlock)(NSData *seResp, NSData *seChlng);
@property (copy) void (^exSessionInitErrorBlock)(NSInteger errorCode);
@property (copy) void (^exSessionEstablishCompleteBlock)(void);
@property (copy) void (^exSessionEstablishErrorBlock)(NSInteger errorCode);
@property (copy) void (^exBlockBtcCompleteBlock)(NSData *okToken, NSData *unBlockToken);
@property (copy) void (^exBlockBtcErrorBlock)(NSInteger errorCode);
@property (copy) void (^exTrxSignLoginCompleteBlock)(NSData *loginHandle);
@property (copy) void (^exTrxSignLoginErrorBlock)(NSInteger errorCode);
@property (copy) void (^exBlockCancelCompleteBlock)(void);
@property (copy) void (^exBlockCancelErrorBlock)(NSInteger errorCode);
@property (copy) void (^exBlockInfoCompleteBlock)(NSNumber *blockAmount);
@property (copy) void (^exBlockInfoErrorBlock)(NSInteger errorCode);
@property (copy) void (^exTrxSignLogoutCompleteBlock)(NSData *receipt);
@property (copy) void (^exTrxSignLogoutErrorBlock)(NSInteger errorCode);

@end

@implementation CwCard

CwCardCommand *currentCmd;
NSMutableArray *cwCmds;
NSMutableArray *cwOutputs;

//bind internal properties
NSData *regHandle;
NSData *regChallenge;
NSData *pinChallenge;
NSData *loginChallenge;
NSData *vmkChallenge;

NSData *encKey;
NSData *macKey;

//hdw properties
NSData *activeCode;

//current transaction properties
NSInteger trxStatus;
typedef NS_ENUM (NSInteger, TrxStatus) {
    TrxStatusPrepare = 0x00,
    TrxStatusBegin = 0x01,
    TrxStatusWaitOtp = 0x02,
    TrxStatusGetOtp = 0x03,
    TrxStatusWaitBtn = 0x04,
    TrxStatusGetBtn = 0x05,
    TrxStatusSigned = 0x06,
    TrxStatusFinish = 0x07,
};

int64_t currTrxAmount;
NSString *currTrxRecvAddress;
CwTx *currUnsignedTx;
CwBtc *currFee;
NSMutableArray *currSigns;

NSInteger cmdWaitDataFlag; //0: not waiting, 1: wait notify, 2: wait data

//syncflags
Boolean syncCwInfoFlag; //firmware version, uid, hostId
Boolean syncSecurityPolicyFlag;
Boolean syncCardIdFlag;     //cardId
Boolean syncCardNameFlag;   //cardName
Boolean syncCurrRateFlag;   //currRate
Boolean syncHdwNameFlag;    //hdwName
Boolean syncHdwAccPtrFlag;  //hdwAccountPointerFlag
Boolean syncHdwStatusFlag;  //hdwStatus

Boolean syncHostFlag[3];

Boolean syncAccInfoFlag[5];

//update firmware status
//status change:
//0->backtoloader->1->auth->2->write data
//                           ->write mac->3(end)
//state definition
//0: init: need blotp
//1: loader state: need authmgrl
//2: loader wait data, write data line by line
//3: loader end.
//4: going to reset SE
NSInteger fwUpdateState=0;
NSData *fwData;
NSInteger fwDataIdx=0;
NSString *fwAuthMtrl;
NSString *fwMac;
NSArray *fwHex;

NSTimer *bleTimer;
NSInteger bleTimerCounter;

NSArray *addresses;

#pragma mark - CwCard Methods
-(id) init {
    if (self = [super init]) {
        //init currentCmd;
        //currentCmd = [[CwCardCommand alloc]init];
        currentCmd = nil;
        cwCmds = [[NSMutableArray alloc] init];
        cwOutputs = [[NSMutableArray alloc] init];
        
        self.cardId = nil;
        self.mode = nil;
        self.fwVersion = nil;
        self.uid = nil;
        self.devCredential = nil;
        self.hostId = nil;
        self.hostConfirmStatus = nil;
        self.hostOtp = nil;
        self.hdwStatus = nil;
        self.hdwName = nil;
        self.hdwAcccountPointer = [NSNumber numberWithInteger:0];
        self.cwHosts = [[NSMutableDictionary alloc] init];
        self.cwAccounts = [[NSMutableDictionary alloc] init];
        
        trxStatus = TrxStatusPrepare;
        
        currSigns = [[NSMutableArray alloc] init];
        
        syncCwInfoFlag = NO;
        syncSecurityPolicyFlag = NO;
        syncCurrRateFlag = NO;
        syncCardIdFlag = NO;
        syncCardNameFlag = NO;
        syncHdwNameFlag = NO;
        syncHdwAccPtrFlag = NO;
        
        for (int i=0; i<3; i++) {
            syncHostFlag[i] = NO;
        }
        
        for (int i=0; i<5; i++) {
            syncAccInfoFlag[i] = NO;
        }
        
        addresses = [[NSArray alloc] init];
        
        regHandle = nil;
        regChallenge = nil;
        pinChallenge = nil;
        loginChallenge = nil;
        vmkChallenge = nil;
        
        self.cardFiatDisplay = [NSNumber numberWithBool:YES];
    }
    return self;
}

- (NSArray *) rm_excludedProperties
{
    return @[
                @"delegate",
                @"bleName", @"rssi", @"connected", @"peripheral", @"lastUpdate",
                @"currentAccountId", @"paymentAddress", @"amount", @"label",
                @"exSessionInitCompleteBlock", @"exSessionInitErrorBlock",
             ];
}

- (CwResetInfo *) cardResetInfo
{
    if (!_cardResetInfo && self.cardId) {
        _cardResetInfo = [[CwResetInfo alloc] initWithCardId:self.cardId];
    }
    
    return _cardResetInfo;
}

-(void) prepareService
{
    //Prepare network service
    NSLog(@"Connected to peripheral, discovering service A000");
    
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:@"A000"]]];
}


-(NSString *) cmdIdToString: (NSInteger) cmdId
{
    NSString *str;
    
    switch (cmdId) {
        case CwCmdIdGetModeState:       str=@"[GetModeState]"; break;
        case CwCmdIdGetFwVersion:       str=@"[GetFwVersion]"; break;
        case CwCmdIdGetUid:             str=@"[GetUid]"; break;
        case CwCmdIdGetError:           str=@"[GetError]"; break;
            
        case CwCmdIdPinChlng:           str=@"[PinChlng]"; break;
        case CwCmdIdPinAuth:            str=@"[PinAuth]"; break;
        case CwCmdIdPinChange:          str=@"[PinChange]"; break;
        case CwCmdIdPinLogout:          str=@"[PinLogout]"; break;
            
        case CwCmdIdBindRegInit:        str=@"[BindRegInit]"; break;
        case CwCmdIdBindRegChlng:       str=@"[BindRegChlng]"; break;
        case CwCmdIdBindRegFinish:      str=@"[BindRegFinish]"; break;
        case CwCmdIdBindRegInfo:        str=@"[BindRegInfo]"; break;
        case CwCmdIdBindRegApprove:     str=@"[BindRegApprove]"; break;
        case CwCmdIdBindRegRemove:      str=@"[BindRegRemove]"; break;
        case CwCmdIdBindLoginChlng:     str=@"[BindLoginChlng]"; break;
        case CwCmdIdBindLogin:          str=@"[BindLogin]"; break;
        case CwCmdIdBindLogout:         str=@"[BindLogout]"; break;
        case CwCmdIdBindFindHostId:     str=@"[BindFindHostId]"; break;
        case CwCmdIdBindBackNoHost:     str=@"[BindBackNoHost]"; break;
            
        case CwCmdIdPersoSetData:       str=@"[PersoSetData]"; break;
        case CwCmdIdPersoConfirm:       str=@"[PersoConfirm]"; break;
        case CwCmdIdPersoBackPerso:     str=@"[PersoBackPerso]"; break;
            
        case CwCmdIdSetCurrRate:        str=@"[SetCurrRate]"; break;
        case CwCmdIdGetCurrRate:        str=@"[GetCurrRate]"; break;
        case CwCmdIdGetCardName:        str=@"[GetCardName]"; break;
        case CwCmdIdSetCardName:        str=@"[SetCardName]"; break;
        case CwCmdIdGetPerso:           str=@"[GetPerso]"; break;
        case CwCmdIdSetPerso:           str=@"[SetPerso]"; break;
        case CwCmdIdGetCardId:          str=@"[GetCardId]"; break;
            
        case CwCmdIdHdwInitWallet:      str=@"[HdwInitWallet]"; break;
        case CwCmdIdHdwInitWalletGen:   str=@"[HdwInitWalletGen]"; break;
        case CwCmdIdHdwQueryWalletInfo: str=@"[HdwQueryWalletInfo]"; break;
        case CwCmdIdHdwSetWalletInfo:   str=@"[HdwSetWalletInfo]"; break;
        case CwCmdIdHdwCreateAccount:   str=@"[HdwCreateAccount]"; break;
        case CwCmdIdHdwQueryAccountInfo:str=@"[HdwQueryAccountInfo]"; break;
        case CwCmdIdHdwSetAccountInfo:  str=@"[HdwSetAccountInfo]"; break;
        case CwCmdIdHdwGetNextAddress:  str=@"[HdwGetNextAddress]"; break;
        case CwCmdIdHdwPrepTrxSign:     str=@"[HdwPrepTrxSign]"; break;
        case CwCmdIdHdwInitWalletGenConfirm: str=@"[HdwInitWalletGenConfirm]"; break;
        case CwCmdIdHdwQueryAccountKeyInfo:  str=@"[HdwQueryAccountKeyInfo]"; break;
            
        case CwCmdIdTrxStatus:          str=@"[TrxStatus]"; break;
        case CwCmdIdTrxBegin:           str=@"[TrxBegin]"; break;
        case CwCmdIdTrxVerifyOtp:       str=@"[TrxVerifyOtp]"; break;
        case CwCmdIdTrxSign:            str=@"[TrxSign]"; break;
        case CwCmdIdTrxFinish:          str=@"[TrxFinish]"; break;
        case CwCmdIdTrxGetAddr:         str=@"[TrxGetAddr]"; break;
            
        case CwCmdIdExRegStatus:        str=@"[ExRegStatus]"; break;
        case CwCmdIdExGetOtp:           str=@"[ExGetOtp]"; break;
        case CwCmdIdExSessionInit:      str=@"[ExSessionInit]"; break;
        case CwCmdIdExSessionEstab:     str=@"[ExSessionEstab]"; break;
        case CwCmdIdExSessionLogout:    str=@"[ExSessionLogout]"; break;
        case CwCmdIdExBlockInfo:        str=@"[ExBlockInfo]"; break;
        case CwCmdIdExBlockBtc:         str=@"[ExBlockBtc]"; break;
        case CwCmdIdExBlockCancel:      str=@"[ExBlockCancel]"; break;
        case CwCmdIdExTrxSignLogin:     str=@"[ExTrxSignLogin]"; break;
        case CwCmdIdExTrxSignPrepare:   str=@"[ExTrxSignPrepare]"; break;
        case CwCmdIdExTrxSignLogout:    str=@"[ExTrxSignLogout]"; break;
            
        case CwCmdIdBackToLoader:       str=@"[BackToLoader]"; break;
            
        case CwCmdIdMcuResetSe:         str=@"[McuResetSe]"; break;
        case CwCmdIdMcuQueryBatGague:   str=@"[McuQueryBatGague]"; break;
        case CwCmdIdMcuSetAccount:      str=@"[McuSetAccount]"; break;
        case CwCmdIdMcuGenOtp:          str=@"[McuGenOtp]"; break;
        case CwCmdIdMcuVerifyOtp:       str=@"[McuVerifyOtp]"; break;
        case CwCmdIdMcuDisplayUsd:      str=@"[McuDisplayUsd]"; break;
            
        default:                        str=@"[UnknownCmdId]"; break;
            
    }
    return str;
}

-(NSData *) signatureToLowS: (NSData *) signature
{
    //check if there is a high S
    // S must between 0x1 and 0x7FFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 5D576E73 57A4501D DFE92F46 681B20A0 (inclusive).
    // If S is too high, simply replace it by S' = 0xFFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFE BAAEDCE6 AF48A03B BFD25E8C D0364141 - S.
    
    MPBN_WORD half[32] = {0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x5D, 0x57, 0x6E, 0x73, 0x57, 0xA4, 0x50, 0x1D, 0xDF, 0xE9, 0x2F, 0x46, 0x68, 0x1B, 0x20, 0xA0};
    MPBN_WORD order[32] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xBA, 0xAE, 0xDC, 0xE6, 0xAF, 0x48, 0xA0, 0x3B, 0xBF, 0xD2, 0x5E, 0x8C, 0xD0, 0x36, 0x41, 0x41};
    
    MPBN_WORD sig[32];
    
    Byte modifySig[64];
    [signature getBytes:modifySig length:64];
    
    Byte *sigPtr = modifySig+32; //pointer to S
    
    for (int i=0; i<32; i++) {
        MPBN_WORD *ptr = (MPBN_WORD *)sigPtr+i;
        sig[i]= *ptr;
    }
    
    //compare S with Half
    if (mpbn_comp(sig, half, 32)>0) {
        mpbn_sub(sig, order, sig, 32);
    }
    
    memcpy(modifySig+32, (Byte *)sig, 32);
    
    return [NSData dataWithBytes:modifySig length:64];
}

//Card API

//MCU commands
-(void) resetSe
{
    [self cwCmdMcuResetSe];
}

-(void) setDisplayAccount: (NSInteger) accId
{
    [self cwCmdMcuSetAccount:accId];
}

-(void) genResetOtp
{
    [self cwCmdMcuGenOtp];
}

-(void) verifyResetOtp: (NSString *)otp
{
    [self cwCmdMcuVerifyOtp: otp];
}

-(void) displayCurrency: (BOOL) option
{
    [self cwCmdMcuDisplayUsd:option];
}

//Load Commands
-(void) loadCwCardFromFile
{
    //remove for test
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey:self.cardId];
    
    if (self.cardId == nil || self.hostOtp == nil) {
        return;
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    CwCardInfo *cardInfo = [defaults rm_customObjectForKey:self.cardId];
    if (cardInfo == nil) {
        return;
    }
    
    if ([cardInfo.hostOtp isEqualToString:self.hostOtp]) {
        if (cardInfo.cardFiatDisplay == nil) {
            cardInfo.cardFiatDisplay = [NSNumber numberWithBool:YES];
        }
        NSDictionary *dict = [RMMapper dictionaryForObject:cardInfo];
        [RMMapper populateObject:self fromDictionary:dict];
        self.cwHosts = [NSMutableDictionary dictionaryWithDictionary:self.cwHosts];
        self.cwAccounts = [NSMutableDictionary dictionaryWithDictionary:self.cwAccounts];
    } else {
        [defaults removeObjectForKey:self.cardId];
        [defaults removeObjectForKey:[NSString stringWithFormat:@"exchange_%@", self.cardId]];
        [defaults removeObjectForKey:[NSString stringWithFormat:@"recovery_%@", self.cardId]];
    }
}

//Save Commands
-(void) saveCwCardToFile
{
    NSLog(@"SaveCwToFile:%@ accountptr:%@ accoints:%lu", self.cardId, self.hdwAcccountPointer, (unsigned long)self.cwAccounts.count);
    
    if (self.cardResetInfo) {
        [self.cardResetInfo saveResetInfo];
    }
    
    if (self.cardId == nil || self.hdwAcccountPointer == nil || self.mode.integerValue != CwCardModeNormal) {
        return;
    }
    
    CwCardInfo *cardInfo = [[CwCardInfo alloc] initFromCwCard:self];
    [[NSUserDefaults standardUserDefaults] rm_setCustomObject:cardInfo forKey:self.cardId];
}

//Sync Card Info after Login
-(void) syncFromCard
{
    //basic info
    if (self.fwVersion==nil)
        [self cwCmdGetFwVersion];
    if (self.uid==nil)
        [self cwCmdGetUid];
    
    //get hostInfos
    [self getHosts];
    
    //get security info
    [self getSecurityPolicy];
    
    //get card info
    [self getCwCardId];
    [self getCwCardName];
    
    //hdw info
    [self getCwHdwInfo];
    
    //accounts info
    //[self cwCmdHdwQueryAccountInfo:CwHdwAccountInfoExtKeyPtr AccountId:0];
}

-(void) syncToCard
{
    
}

//CW commands
-(void) getModeState
{
    [self cwCmdGetModeState];
}

//Get CwInfo
-(void) getCwInfo //get CW infos include firmware version/uid/hostId
{
    /*
     if (syncCwInfoFlag == NO ) {
     } else {
     //call delegate
     if ([self.delegate respondsToSelector:@selector(didGetCwInfo)]) {
     [self.delegate didGetCwInfo];
     }
     if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
     [self.delegate didCwCardCommand];
     }
     }
     */
    
    [self cwCmdGetFwVersion];
    [self cwCmdGetUid];
    [self cwCmdGetCardId];
    [self cwCmdBindFindHostId: [self.devCredential stringByReplacingOccurrencesOfString:@"-" withString:@""]];
}

-(void) getCwCardId
{
    if (self.cardId == nil) {
        [self cwCmdGetCardId];
    } else {
        //call delegate
        if ([self.delegate respondsToSelector:@selector(didGetCwCardId)]) {
            [self.delegate didGetCwCardId];
        }
        if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
            [self.delegate didCwCardCommand];
        }
    }
}

//Authentication Commands
-(void) pinChlng
{
    [self cwCmdPinChlng];
}
-(void) pinAuth: (NSString *) pin
{
    [self cwCmdPinAuth: pin];
}
-(void) pinChange: (NSString *) oldPin NewPing: (NSString*) newPin
{
    [self cwCmdPinChange:oldPin NewPin:newPin];
}
-(void) pinLogout
{
    [self cwCmdPinLogout];
}

//Host Commands
-(void) registerHost: (NSString *)credential Description: (NSString*)description
{
    if ([self.mode integerValue] == CwCardModeNoHost)
        [self cwCmdBindRegInit: YES Credential: credential Description: description];
    else
        [self cwCmdBindRegInit: NO Credential: credential Description: description];
}

-(void) confirmHost: (NSString *)otp; //callback: didConfirmHost
{
    self.hostOtp = otp;
    [self cwCmdBindRegChlng];
    //call finish after get challenge;
    //[self cwCmdBindRegFinish:otp];
}

-(void) eraseCw: (BOOL) preserveHost Pin: (NSString *)pin NewPin: (NSString *) newPin //callback: didEraseCw
{
    if ([self.mode integerValue] == CwCardModeDisconn) {
        [self cwCmdBindBackNoHost:pin NewPin:newPin];
    } else if ([self.mode integerValue] == CwCardModeNormal) {
        [self cwCmdPersoBackPerso: newPin];
        
        if (!preserveHost)
            [self cwCmdBindBackNoHost:pin NewPin:newPin];
    } else { //other modes, might not work
        [self cwCmdBindBackNoHost:pin NewPin:newPin];
    }
    
    //remove stored file
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.cardId];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"exchange_%@", self.cardId]];
    
    self.cardId = nil;
    self.cwAccounts = nil;
    self.cardName = nil;
    self.currId = nil;
    self.currRate = 0;
    self.hdwStatus = [NSNumber numberWithInt:0];
    self.hdwName = nil;
    self.hdwAcccountPointer = [NSNumber numberWithInt:0];
}

-(void) loginHost //callback: didLoginHost
{
    syncHdwStatusFlag = NO;
    [self cwCmdBindLoginChlng];
    //call cwCmdBindLogin after get challenge;
}

-(void) logoutHost
{
    [self cwCmdBindLogout];
}

-(void) getHosts
{
    if (!(syncHostFlag[0]&&syncHostFlag[1]&&syncHostFlag[2])) {
        for (int i=0; i<3; i++)
            if (!syncHostFlag[i]) {
                [self cwCmdBindRegInfo:i];
            }
    } else {
        //call delegate
        if ([self.delegate respondsToSelector:@selector(didGetHosts)]) {
            [self.delegate didGetHosts];
        }
        if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
            [self.delegate didCwCardCommand];
        }
    }
}

-(void) approveHost: (NSInteger) hostId
{
    [self cwCmdBindRegApprove:hostId];
}

-(void) removeHost: (NSInteger) hostId
{
    [self cwCmdBindRegRemove:hostId];
}

-(void) defaultPersoSecurityPolicy
{
    [self persoSecurityPolicy:NO ButtonEnable:YES DisplayAddressEnable:NO WatchDogEnable:NO];
}

-(void) persoSecurityPolicy: (BOOL)otpEnable ButtonEnable: (BOOL)btnEnable DisplayAddressEnable: (BOOL) addEnable WatchDogEnable: (BOOL)wdEnable
{
    self.securityPolicy_OtpEnable = [NSNumber numberWithBool:otpEnable];
    self.securityPolicy_BtnEnable = [NSNumber numberWithBool:btnEnable];
    self.securityPolicy_DisplayAddressEnable = [NSNumber numberWithBool:addEnable];
    self.securityPolicy_WatchDogEnable = [NSNumber numberWithBool:wdEnable];
    
    [self CwCmdPersoSetData];
}

-(void) getSecurityPolicy
{
    if (syncSecurityPolicyFlag == NO) {
        [self cwCmdGetPerso];
    } else {
        //call delegate
        if ([self.delegate respondsToSelector:@selector(didGetSecurityPolicy)]) {
            [self.delegate didGetSecurityPolicy];
        }
        if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
            [self.delegate didCwCardCommand];
        }
    }
}

-(void) setSecurityPolicy: (BOOL)otpEnable ButtonEnable: (BOOL)btnEnable DisplayAddressEnable: (BOOL) addEnable WatchDogEnable: (BOOL)wdEnable
{
    self.securityPolicy_OtpEnable = [NSNumber numberWithBool:otpEnable];
    self.securityPolicy_BtnEnable = [NSNumber numberWithBool:btnEnable];
    self.securityPolicy_DisplayAddressEnable = [NSNumber numberWithBool:addEnable];
    self.securityPolicy_WatchDogEnable = [NSNumber numberWithBool:wdEnable];
    
    [self cwCmdSetPerso];
}

-(void) getCwCardName
{
    if (syncCardNameFlag == NO) {
        [self cwCmdGetCardName];
    } else {
        //call delegate
        if ([self.delegate respondsToSelector:@selector(didGetCwCardName)]) {
            [self.delegate didGetCwCardName];
        }
        if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
            [self.delegate didCwCardCommand];
        }
    }
}

-(void) setCwCardName:(NSString *)cardName
{
    self.cardName = cardName;
    [self cwCmdSetCardName:self.cardName];
}

-(void) getCwCurrRate
{
    if (syncCurrRateFlag == NO) {
        [self cwCmdGetCurrRate];
    } else {
        //call delegate
        if ([self.delegate respondsToSelector:@selector(didGetCwCurrRate)]) {
            [self.delegate didGetCwCurrRate];
        }
        if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
            [self.delegate didCwCardCommand];
        }
    }
}
-(void) setCwCurrRate:(NSDecimalNumber *)currRate
{
    self.currRate = currRate;
    [self cwCmdSetCurrRate: self.currRate];
}

-(void) getCwHdwInfo
{
    if (syncHdwStatusFlag == NO) {
        [self cwCmdHdwQueryWalletInfo:CwHdwInfoAll];
    } else {
        //call delegate
        if ([self.delegate respondsToSelector:@selector(didGetCwHdwStatus)]) {
            [self.delegate didGetCwHdwStatus];
        }
        
        if ([self.hdwStatus integerValue] == CwHdwStatusActive) {
            if (syncHdwNameFlag) {
                //call delegate
                if ([self.delegate respondsToSelector:@selector(didGetCwHdwName)]) {
                    [self.delegate didGetCwHdwName];
                }
            } else {
                [self cwCmdHdwQueryWalletInfo:CwHdwInfoName];
            }
            
            if (syncHdwAccPtrFlag) {
                //call delegate
                if ([self.delegate respondsToSelector:@selector(didGetCwHdwAccountPointer)]) {
                    [self.delegate didGetCwHdwAccountPointer];
                }
            } else {
                [self cwCmdHdwQueryWalletInfo:CwHdwInfoAccountPointer];
            }
        }
    }
}

-(void) setCwHdwName: (NSString *) hdwName;
{
    self.hdwName = hdwName;
    
    [self cwCmdHdwSetWalletInfo:CwHdwInfoName Info:[hdwName dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void) initHdw: (NSString *)hdwName BySeed: (NSString *)seed      //didInitHdwBySeed
{
    [self cwCmdHdwInitWallet:hdwName Seed:seed];
}

-(void) initHdw: (NSString *)hdwName ByCard: (NSInteger)seedLen    //didInitHdwByCard
{
    [self cwCmdHdwInitWalletGen:hdwName SeedLen: seedLen];
}

-(void) initHdwConfirm: (NSString *)sumOfSeeds                     //didInitHdwConfirm
{
    [self cwCmdHdwInitWalletGenConfirm:activeCode Sum: sumOfSeeds];
}

-(void) newAccount: (NSInteger) accountId Name: (NSString *)accountName
{
    [self cwCmdHdwCreateAccount:accountId AccountName:accountName];
    [self cwCmdHdwQueryAccountKeyInfo:CwHdwAccountKeyInfoKeyChainPubKey KeyChainId:CwAddressKeyChainExternal AccountId:accountId KeyId:0];
    [self cwCmdHdwQueryAccountKeyInfo:CwHdwAccountKeyInfoKeyChainPubKey KeyChainId:CwAddressKeyChainInternal AccountId:accountId KeyId:0];
    [self setAccount: accountId Balance:0];
}

-(void) getAccounts; //didGetAccounts
{
    //get hostInfos
    for (int i=0; i<self.hdwAcccountPointer.integerValue; i++) {
        [self getAccountInfo:i];
    }
}

-(void) getAccountInfo: (NSInteger) accountId;
{
    //get account from dictionary
    CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)accountId]];
    
    if (account==nil) {
        account = [[CwAccount alloc] init];
        account.accId = accountId;
        account.accName = @"";
        account.balance = 0;
        account.blockAmount = 0;
        account.extKeyPointer = 0;
        account.intKeyPointer = 0;
        
        //add the host to the dictionary with hostId as Key.
        [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)accountId]];
    }
    
    if (syncAccInfoFlag[accountId] == NO) {
        [self cwCmdHdwQueryAccountInfo:CwHdwAccountInfoAll AccountId:accountId];
    }
    
    if (account.externalKeychain == nil) {
        [self cwCmdHdwQueryAccountKeyInfo:CwHdwAccountKeyInfoKeyChainPubKey
                               KeyChainId:CwAddressKeyChainExternal
                                AccountId:accountId
                                    KeyId:1];
    }
    
    if (account.internalKeychain == nil) {
        [self cwCmdHdwQueryAccountKeyInfo:CwHdwAccountKeyInfoKeyChainPubKey
                               KeyChainId:CwAddressKeyChainInternal
                                AccountId:accountId
                                    KeyId:1];
    }
    
    account.infoSynced = syncAccInfoFlag[account.accId] && account.externalKeychain != nil && account.internalKeychain != nil;
    //check sync status
    if (account.infoSynced) {
        //call delegate
        if ([self.delegate respondsToSelector:@selector(didGetAccountInfo:)]) {
            [self.delegate didGetAccountInfo:account.accId];
        }
    }
}

-(void) getAccountAddresses: (NSInteger) accountId;
{
    //get account from dictionary
    CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)accountId]];
    
    if (account==nil) {
        return;
    }
    
    if ([account isAllAddressSynced]) {
        //call delegate
        if ([self.delegate respondsToSelector:@selector(didGetAccountAddresses:)]) {
            [self.delegate didGetAccountAddresses: account.accId];
        }
        if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
            [self.delegate didCwCardCommand];
        }
        
        return;
    }
    
    //get external addresses
    for (int i=0; i<account.extKeyPointer; i++) {
        [self getAddressInfo:accountId KeyChainId: CwAddressKeyChainExternal KeyId: i];
    }
    
    //get internal addresses
    for (int i=0; i<account.intKeyPointer; i++) {
        [self getAddressInfo:accountId KeyChainId: CwAddressKeyChainInternal KeyId: i];
    }
}

-(void) setAccount: (NSInteger) accountId Name:(NSString *)accountName
{
    [self cwCmdHdwSetAccountInfo:CwHdwAccountInfoName AccountId:accountId AccountInfo:[accountName dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void) setAccount: (NSInteger) accountId Balance:(int64_t) balance
{
    [self cwCmdHdwSetAccountInfo:CwHdwAccountInfoBalance AccountId:accountId AccountInfo:[NSData dataWithBytes:&balance length:8]];
}

-(void) setAccount: (NSInteger) accountId ExtKeyPtr:(NSInteger)extKeyPtr
{
    [self cwCmdHdwSetAccountInfo:CwHdwAccountInfoExtKeyPtr AccountId:accountId AccountInfo:[NSData dataWithBytes:&extKeyPtr length:4]];
}

-(void) setAccount: (NSInteger) accountId IntKeyPtr:(NSInteger)intKeyPtr
{
    [self cwCmdHdwSetAccountInfo:CwHdwAccountInfoIntKeyPtr AccountId:accountId AccountInfo:[NSData dataWithBytes:&intKeyPtr length:4]];
}

-(void) findEmptyAddressFromAccount:(NSInteger)accountID keyChainId:(NSInteger)keyChainId
{
    CwAddress *emptyAddress;
    NSMutableArray *addresses;
    
    CwAccount *account = [self.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", accountID]];
    if (keyChainId == CwAddressKeyChainExternal) {
        addresses = account.extKeys;
    } else {
        addresses = account.intKeys;
    }
    
    for (CwAddress *address in addresses) {
        if (address.historyTrx.count == 0) {
            emptyAddress = address;
            break;
        }
    }
    
    if (emptyAddress == nil) {
        [self doGenAddressWithAccountId:account.accId KeyChainId:keyChainId];
    } else {
        if (emptyAddress.publicKey == nil) {
            [self getAddressPublickey:emptyAddress.accountId KeyChainId:emptyAddress.keyChainId KeyId:emptyAddress.keyId];
        }
        
        if ([self.delegate respondsToSelector:@selector(didGenAddress:)]) {
            [self.delegate didGenAddress:emptyAddress];
        }
    }
}

-(BOOL) enableGenAddressWithAccountId:(NSInteger)accId
{
    CwAccount *acc= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)accId]];
    
    int emptyAddrCount = 0;
    for (int i=0; i<acc.extKeyPointer; i++) {
        //check transactions of each keys
        CwAddress *addr = acc.extKeys[i];
        
        if (addr.historyTrx.count==0) {
            emptyAddrCount++;
        }
    }
    
    return emptyAddrCount < CwHdwRecoveryAddressWindow;
}

-(void) genAddress:  (NSInteger)accId KeyChainId: (NSInteger) keyChainId
{
    CwAccount *acc= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)accId]];
    NSInteger accPtr[5][2];
    for(int i=0; i<5; i++) {
        accPtr[i][0]=-1;
        accPtr[i][1]=-1;
    }
    
    NSDictionary *settings = @{@(CwAddressKeyChainExternal): @{
                @"pointer": @(acc.extKeyPointer),
                @"addrs": acc.extKeys == nil ? @[] : acc.extKeys
              },
      @(CwAddressKeyChainInternal): @{
                @"pointer": @(acc.intKeyPointer),
                @"addrs": acc.intKeys == nil ? @[] : acc.intKeys
              }};
    
    NSDictionary *accountSetting = [settings objectForKey:@(keyChainId)];
    NSNumber *pointer = [accountSetting objectForKey:@"pointer"];
    NSArray *addrs = [accountSetting objectForKey:@"addrs"];
    
    for (int i=0; i<pointer.integerValue; i++) {
        //check transactions of each keys
        CwAddress *addr = addrs[i];
        
        if (addr.historyTrx.count>0) {
            //clear the counter
            accPtr[accId][keyChainId]=-1;
        }
        
        if (addr.historyTrx.count==0) {
            if (accPtr[accId][keyChainId]==-1)
                accPtr[accId][keyChainId]=addr.keyId;
        }
    }
    
    if (accPtr[accId][keyChainId]==-1 || pointer.integerValue-accPtr[accId][keyChainId]<CwHdwRecoveryAddressWindow) {
        [self doGenAddressWithAccountId:accId KeyChainId:keyChainId];
    } else {
        //no transactions yet
        CwAddress *addr = addrs.lastObject;
        if (addr.publicKey == nil) {
            [self getAddressPublickey:addr.accountId KeyChainId:addr.keyChainId KeyId:addr.keyId];
        }
        if ([self.delegate respondsToSelector:@selector(didGenAddress:)]) {
            [self.delegate didGenAddress:addr];
        }
        if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
            [self.delegate didCwCardCommand];
        }
        return;
    }
}

-(void) doGenAddressWithAccountId:(NSInteger)accId KeyChainId:(NSInteger)keyChainId
{
    BTCKey *btcKey;
    CwAccount *account = [self.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)accId]];
    
    if (keyChainId == CwKeyChainExternal && account.externalKeychain.keyChainId != nil) {
        if (account.extKeys == nil || account.extKeys.count == 0) {
            btcKey = [account.externalKeychain genNextAddress];
        } else {
            CwAddress *lastAddress = [account.extKeys lastObject];
            if (lastAddress.keyId != account.externalKeychain.currentKeyIndex.integerValue) {
                btcKey = [account.externalKeychain getAddressAtIndex:(int)lastAddress.keyId+1];
            } else {
                btcKey = [account.externalKeychain genNextAddress];
            }
        }
    } else if (keyChainId == CwKeyChainInternal && account.internalKeychain.keyChainId != nil) {
        if (account.intKeys == nil || account.intKeys.count == 0) {
            btcKey = [account.internalKeychain genNextAddress];
        } else {
            CwAddress *lastAddress = [account.intKeys lastObject];
            if (lastAddress.keyId != account.internalKeychain.currentKeyIndex.integerValue) {
                btcKey = [account.internalKeychain getAddressAtIndex:(int)lastAddress.keyId+1];
            } else {
                btcKey = [account.internalKeychain genNextAddress];
            }
        }
    }
    
    if (btcKey == nil) {
        [self cwCmdHdwGetNextAddress: keyChainId AccountId: accId];
    } else {
        CwAddress *addr;
        if (keyChainId == CwKeyChainExternal) {
            [self updateAddressInfoFromBTCKey:btcKey atIndex:account.extKeyPointer keyChainId:keyChainId withAccount:account];
            addr = [account.extKeys lastObject];
        } else {
            [self updateAddressInfoFromBTCKey:btcKey atIndex:account.intKeyPointer keyChainId:keyChainId withAccount:account];
            addr = [account.intKeys lastObject];
        }
        
        if ([self.delegate respondsToSelector:@selector(didGenAddress:)]) {
            [self.delegate didGenAddress:addr];
        }
    }
}

-(void) getAddressInfo:(NSInteger)accountId KeyChainId:(NSInteger)keyChainId KeyId:(NSInteger)keyId; //didGenNextAddress
{
    //get account from dictionary
    CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)accountId]];
    
    NSDictionary *settings = @{@(CwAddressKeyChainExternal): @{
                                       @"keychain": account.externalKeychain == nil ? [NSNull null] : account.externalKeychain,
                                       @"addrs": account.extKeys
                                       },
                               @(CwAddressKeyChainInternal): @{
                                       @"keychain": account.internalKeychain == nil ? [NSNull null] : account.internalKeychain,
                                       @"addrs": account.intKeys
                                       }};
    
    NSDictionary *accountSetting = [settings objectForKey:@(keyChainId)];
    CwKeychain *keychain = [accountSetting objectForKey:@"keychain"];
    NSArray *addrs = [accountSetting objectForKey:@"addrs"];
    CwAddress *address = (CwAddress *)addrs[keyId];
    
    BOOL keychainExists = ![keychain isKindOfClass:[NSNull class]] && keychain.extendedPublicKey != nil;
    //get address
    if (address.address==nil || [address.address isEqualToString:@""]) {
        
        if (keychainExists) {
            BTCKey *btcKey = [keychain getAddressAtIndex:(int)keyId];
            if (btcKey) {
                [self updateAddressInfoFromBTCKey:btcKey atIndex:keyId keyChainId:keyChainId withAccount:account];
                
                if ([self.delegate respondsToSelector:@selector(didGetAddressInfo)]) {
                    [self.delegate didGetAddressInfo];
                }
                
                if ([account isAllAddressSynced]) {
                    if ([self.delegate respondsToSelector:@selector(didGetAccountAddresses:)]) {
                        [self.delegate didGetAccountAddresses: account.accId];
                    }
                }
            } else {
                [self cwCmdHdwQueryAccountKeyInfo:CwHdwAccountKeyInfoAddress
                                       KeyChainId:keyChainId
                                        AccountId:accountId
                                            KeyId:keyId];
            }
        } else {
            [self cwCmdHdwQueryAccountKeyInfo:CwHdwAccountKeyInfoAddress
                                   KeyChainId:keyChainId
                                    AccountId:accountId
                                        KeyId:keyId];
        }
    }
}

-(void) updateAddressInfoFromBTCKey:(BTCKey *)btcKey atIndex:(NSInteger)index keyChainId:(NSInteger)keyChainId withAccount:(CwAccount *)account
{
    if (!btcKey) {
        return;
    }
    
    BOOL isNewAddress = YES;
    CwAddress *addr = [[CwAddress alloc] init];
    if (keyChainId == CwAddressKeyChainExternal && index < account.extKeys.count) {
        isNewAddress = NO;
        addr = account.extKeys[index];
    } else if (keyChainId == CwAddressKeyChainInternal && index < account.intKeys.count) {
        isNewAddress = NO;
        addr = account.intKeys[index];
    }
    
    addr.address = btcKey.address.string;
    addr.accountId = account.accId;
    addr.keyChainId = keyChainId;
    addr.keyId = index;
    
    if (keyChainId == CwAddressKeyChainExternal) {
        account.extKeys[index] = addr;
        if (isNewAddress) {
            account.extKeyPointer += 1;
            [self setAccount:account.accId ExtKeyPtr:account.extKeyPointer];
        }
    } else {
        account.intKeys[index] = addr;
        if (isNewAddress) {
            account.intKeyPointer += 1;
            [self setAccount:account.accId IntKeyPtr:account.intKeyPointer];
        }
    }
    
    if (addr.publicKey == nil) {
        [self getAddressPublickey:account.accId KeyChainId:keyChainId KeyId:index];
    }
    
    [self.cwAccounts setObject:account forKey:[NSString stringWithFormat:@"%ld", (long)account.accId]];
}

-(void) getAddressPublickey: (NSInteger)accountId KeyChainId: (NSInteger) keyChainId KeyId: (NSInteger) keyId
{
    //get account from dictionary
    CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)accountId]];
    
    NSDictionary *settings = @{@(CwAddressKeyChainExternal): @{
                                       @"keychain": account.externalKeychain == nil ? [NSNull null] : account.externalKeychain,
                                       @"addrs": account.extKeys
                                       },
                               @(CwAddressKeyChainInternal): @{
                                       @"keychain": account.internalKeychain == nil ? [NSNull null] : account.internalKeychain,
                                       @"addrs": account.intKeys
                                       }};
    
    NSDictionary *accountSetting = [settings objectForKey:@(keyChainId)];
    CwKeychain *keychain = [accountSetting objectForKey:@"keychain"];
    NSMutableArray *addrs = [NSMutableArray arrayWithArray:[accountSetting objectForKey:@"addrs"]];
    if (keyId > addrs.count) {
        return;
    }
    
    CwAddress *address = (CwAddress *)addrs[keyId];
    if (address.publicKey != nil) {
        return;
    }
    
    BOOL keychainExists = ![keychain isKindOfClass:[NSNull class]] && keychain.extendedPublicKey != nil;
    if (keychainExists) {
        address.publicKey = [keychain getPublicKeyAtIndex:(int)keyId];
        addrs[keyId] = address;
        
        [self.cwAccounts setObject:account forKey: [NSString stringWithFormat: @"%ld", (long)accountId]];
        
        if ([self.delegate respondsToSelector:@selector(didGetAddressPublicKey:)]) {
            [self.delegate didGetAddressPublicKey:[addrs objectAtIndex:keyId]];
        }
    } else {
        [self cwCmdHdwQueryAccountKeyInfo:CwHdwAccountKeyInfoPubKey
                               KeyChainId:keyChainId
                                AccountId:accountId
                                    KeyId:keyId];
    }
}

//didPrepareTransaction
-(CwTx *) getUnsignedTransaction:(int64_t)amount Address:(NSString *)recvAddress Change:(NSString *)changeAddress AccountId:(NSInteger)accountId
{
    //end transaction if exists
    [self cwCmdTrxFinish];
    
    trxStatus = TrxStatusPrepare;
    
    //check unspends in the account
    CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", accountId]];
    
    //check amount vs (balance - fee - blockAmount)
    if (amount > account.balance - FEERATE - account.blockAmount + account.tempUnblockAmount) {
        if ([self.delegate respondsToSelector:@selector(didPrepareTransactionError:)]) {
            [self.delegate didPrepareTransactionError:[NSString stringWithFormat:@"Amount is lower than balance\nTransaction fee: %@ BTC", [[OCAppCommon getInstance] convertBTCStringformUnit: FEERATE]]];
        }
        return nil;
    }
    
    //check unspent tx
    if (account.unspentTxs==nil || account.unspentTxs.count==0) {
        if ([self.delegate respondsToSelector:@selector(didPrepareTransactionError:)]) {
            [self.delegate didPrepareTransactionError:@"No available unspent transaction"];
        }
        return nil;
    }
    
    for (CwUnspentTxIndex *utx in [account unspentTxs])
    {
        NSMutableString *b = [NSMutableString stringWithFormat:@"%@\n",[utx tid]];
        [b appendFormat:@"%@",[[utx amount]BTC]];
        NSLog(@"%@", b);
        
        if (utx.kcId == CwAddressKeyChainExternal) {
            CwAddress *addr = [account.extKeys objectAtIndex:utx.kId];
            NSLog(@"public key: %@", addr.publicKey);
        } else if (utx.kcId == CwAddressKeyChainInternal) {
            CwAddress *addr = [account.intKeys objectAtIndex:utx.kId];
            NSLog(@"public key: %@", addr.publicKey);
        }
    }
    
    //Generate UnsignedTx
    CwTx *unsignedTx;
    CwBtc *fee;
    GenTxErr err = [account genUnsignedTxToAddrByAutoCoinSelection:recvAddress change: changeAddress amount:[CwBtc BTCWithSatoshi:[NSNumber numberWithLongLong:amount]] unsignedTx:&unsignedTx fee:&fee];
    
    //check unsigned tx
    if (err == GENTX_LESS || (unsignedTx==nil || unsignedTx.inputs.count == 0)) {
        if ([self.delegate respondsToSelector:@selector(didPrepareTransactionError:)]) {
            [self.delegate didPrepareTransactionError:@"At least 1 confirmation needed before sending out."];
        }
        return nil;
    }
    
    //print IN and OUT of the tx
    for(CwTxin *txin in [unsignedTx inputs])
    {
        CwTx *tx = [account.transactions objectForKey:txin.tid];
        NSLog(@"in :  %@ n:%ld, %@ BTC, confirm: %@", [txin addr], txin.n, [[txin amount]BTC], tx.confirmations);
    }
    for (CwTxout* txout in [unsignedTx outputs])
    {
        NSLog(@"out:  %@ %@", [txout addr], [[txout amount]BTC]);
    }
    
    //Generate Hash of the Tx IN
    NSArray *hashes = [account genHashesOfTxCopy:unsignedTx];
    for(NSData* hash in hashes)
    {
        NSMutableString* b = [NSMutableString stringWithFormat:@"%@",hash];
        NSLog(@"hash: %@\n", b);
    }
    
    //save transaction data
    currTrxAmount = amount;
    currTrxRecvAddress = recvAddress;
    currUnsignedTx = unsignedTx;
    currFee = fee;
    
    return unsignedTx;
}

-(void) prepareTransaction:(int64_t)amount Address: (NSString *)recvAddress Change: (NSString *)changeAddress
{
    CwTx *unsignedTx = [self getUnsignedTransaction:amount Address:recvAddress Change:changeAddress AccountId:self.currentAccountId];
    
    [self prepareTransactionWithUnsignedTx:unsignedTx];
}

-(void) prepareTransactionWithUnsignedTx:(CwTx *)unsignedTx
{
    if (unsignedTx == nil) {
        return;
    }
    
    //Sign hashes of the TX (max ins: 256)
    for (int i=0; i<unsignedTx.inputs.count; i++) {
        CwTxin *txin = unsignedTx.inputs[i];
        [self cwCmdHdwPrepTrxSign: i
                       KeyChainId: txin.kcId
                        AccountId: txin.accId
                            KeyId: txin.kId
                           Amount: txin.amount.satoshi.intValue
                SignatureMateiral: txin.hashForSign];
    }
}

-(void) verifyTransactionOtp: (NSString *)otp; //didVerifyOtp, didVerifyOtpError
{
    if (trxStatus==TrxStatusGetOtp || trxStatus==TrxStatusWaitOtp) {
        //verify OTP
        [self cwCmdTrxVerifyOtp:otp];
    }
}

-(void) signTransaction //didSignTransaction
{
    for (int i=0; i<currUnsignedTx.inputs.count; i++) {
        [self cwCmdTrxSign:i];
    }
}

-(void) cancelTrancation
{
    //end transaction
    [self cwCmdTrxFinish];
    
    //call delegate
    if ([self.delegate respondsToSelector:@selector(didCancelTransaction)]) {
        [self.delegate didCancelTransaction];
    }
}

-(void) updateFirmwareWithOtp: (NSString *)blotp HexData: (NSData *)hexData //didUpdateFirmwareProgress, didUpdateFirmwareDone
{
    NSString* hexString = [[NSString alloc] initWithData:hexData
                                                encoding:NSUTF8StringEncoding];
    fwHex = [hexString componentsSeparatedByString: @"\r\n"];
    
    //get authMaterial
    NSArray* tmpArray = [[fwHex objectAtIndex: 0] componentsSeparatedByString: @" "];
    if ([[tmpArray objectAtIndex: 0] containsString:@";[AUTHMTRL]"]) {
        fwAuthMtrl = [tmpArray objectAtIndex: 1];
        
        NSLog(@"[AUTHMTRL] found");
        //
    } else {
        //can't find Auth Material
        
        if ([self.delegate respondsToSelector:@selector(didUpdateFirmwareDone:)]) {
            [self.delegate didUpdateFirmwareDone: CwFwUpdateStatusAuthFail];
        }
        NSLog(@"[AUTHMTRL] missing");
        return;
    }
    
    //get Mac
    tmpArray = [[fwHex objectAtIndex: 1] componentsSeparatedByString: @" "];
    if ([[tmpArray objectAtIndex: 0] containsString:@";[HEXMAC]"]) {
        fwMac = [tmpArray objectAtIndex: 1];
        NSLog(@"[HEXMAC] found");
        //
    } else {
        //can't find Mac
        if ([self.delegate respondsToSelector:@selector(didUpdateFirmwareDone:)]) {
            [self.delegate didUpdateFirmwareDone: CwFwUpdateStatusCheckFail];
        }
        NSLog(@"[HEXMAC] missing");
        return;
    }
    
    //auth by blotp
    fwUpdateState = 0;
    fwData = hexData;
    fwDataIdx = 2;
    [self cwCmdBackToLoader: blotp];
}

-(void) firmwareUpdate
{
    //get hexData
    /*
     CwFwUpdateStatusSuccess = 0x00,
     CwFwUpdateStatusAuthFail = 0x01,
     CwFwUpdateStatusUpdateFail = 0x02,
     CwFwUpdateStatusCheckFail = 0x03,
     */
    float progress;
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@":"];
    
    switch (fwUpdateState) {
        case 1:
            //send authMtrl
            [self loaderCmdLoadingBegin:fwAuthMtrl];
            break;
            
        case 2:
            progress = (float)((float)(fwDataIdx+1)/(float)fwHex.count);
            NSLog (@"%ld %@ %f", (fwDataIdx+1), [fwHex objectAtIndex: fwDataIdx], progress);
            if ([self.delegate respondsToSelector:@selector(didUpdateFirmwareProgress:)]) {
                [self.delegate didUpdateFirmwareProgress: progress];
            }
            
            if (fwDataIdx == fwHex.count-1)
                fwUpdateState = 3;
            
            //update firmwares
            [self LoaderCmdWriteRecord:[[fwHex objectAtIndex: fwDataIdx] stringByTrimmingCharactersInSet:set]];
            break;
        case 3:
            //send mac to verify
            [self loaderCmdVerifyMac:fwMac];
            
            break;
        case 4:
            //reset SE
            if ([self.delegate respondsToSelector:@selector(didUpdateFirmwareDone:)]) {
                [self.delegate didUpdateFirmwareDone: CwFwUpdateStatusSuccess];
            }
            
            [self resetSe];
            break;
    }
}

-(void) backToLoader: (NSString *)blotp
{
    [self cwCmdBackToLoader: blotp];
}

-(void) backTo7816FromLoader
{
    [self loaderCmdBackTo7816Loader];
}

//Exchange Site Functions
-(void) exGetRegStatus
{
    [self cwCmdExRegStatus];
}

-(void) exGetOtp
{
    [self cwCmdExGetOtpWithOption:CwHdwExOTPKeyInfoLogin];
}

-(void) exGetBlockOtp
{
    [self cwCmdExGetOtpWithOption:CwHdwExOTPKeyInfoBlock];
}

-(void) exSessionInit: (NSData *)svrChlng withComplete:(void (^)(NSData *seResp, NSData *seChlng))complete withError:(void (^)(NSInteger errorCode))error
{
    self.exSessionInitCompleteBlock = complete;
    self.exSessionInitErrorBlock = error;
    [self cwCmdExSessionInit:svrChlng];
}

-(void) exSessionEstab: (NSData *)svrResp withComplete:(void (^)(void))complete withError:(void (^)(NSInteger errorCode))error
{
    self.exSessionEstablishCompleteBlock = complete;
    self.exSessionEstablishErrorBlock = error;
    [self cwCmdExSessionEstab:svrResp];
}

-(void) exSessionLogout
{
    [self cwCmdExSessionLogout];
}

-(void) exBlockInfo: (NSData *)okTkn withComplete:(void (^)(NSNumber *blockAmount))complete withError:(void (^)(NSInteger errorCode))error
{
    self.exBlockInfoCompleteBlock = complete;
    self.exBlockInfoErrorBlock = error;
    [self cwCmdExBlockInfo:okTkn];
}

-(void) exBlockBtc: (NSInteger)trxId AccId: (NSInteger)accId Amount: (int64_t)amount Mac1: (NSData *)mac1 Nonce: (NSData*)nonce
{
    [self cwCmdExBlockBtc:trxId AccId:accId Amount:amount Mac1:mac1 Nonce:nonce];
}

-(void) exBlockBtc:(NSString *)input withComplete:(void(^)(NSData *okToken, NSData *unBlockToken))complete error:(void(^)(NSInteger errorCode))error
{
    self.exBlockBtcCompleteBlock = complete;
    self.exBlockBtcErrorBlock = error;
    [self cwCmdExBlockBtc:[NSString hexstringToData:input]];
}

-(void) exBlockCancel: (NSData *)trxId OkTkn: (NSData *)okTkn EncUblkTkn: (NSData *)encUblkTkn Mac1: (NSData *)mac1 Nonce: (NSData*)nonce
{
    [self cwCmdExBlockCancel:trxId OkTkn:okTkn EncUblkTkn:encUblkTkn Mac1:mac1 Nonce:nonce];
}

-(void) exBlockCancel: (NSData *)trxId OkTkn: (NSData *)okTkn EncUblkTkn: (NSData *)encUblkTkn Mac1: (NSData *)mac1 Nonce: (NSData*)nonce withComplete:(void (^)(void))complete withError:(void (^)(NSInteger errorCode))error
{
    self.exBlockCancelCompleteBlock = complete;
    self.exBlockCancelErrorBlock = error;
    [self cwCmdExBlockCancel:trxId OkTkn:okTkn EncUblkTkn:encUblkTkn Mac1:mac1 Nonce:nonce];
}

-(void) exTrxSignLogin: (NSInteger)trxId OkTkn:(NSData *)okTkn EncUblkTkn:(NSData *)encUblkTkn AccId: (NSInteger)accId DealAmount: (int64_t)dealAmount Mac: (NSData *)mac
{
    [self cwCmdExTrxSignLogin:trxId OkTkn:okTkn EncUblkTkn:encUblkTkn AccId:accId DealAmount:dealAmount Mac:mac];
}

-(void) exTrxSignLogin:(NSString *)input withComplete:(void(^)(NSData *loginHandle))complete error:(void(^)(NSInteger errorCode))error
{
    self.exTrxSignLoginCompleteBlock = complete;
    self.exTrxSignLoginErrorBlock = error;
    [self cwCmdExTrxSignLogin:input];
}

-(void) exTrxSignPrepare: (NSInteger)inId TrxHandle:(NSData *)trxHandle AccId: (NSInteger)accId KcId: (NSInteger)kcId KId: (NSInteger)kId Out1Addr: (NSData*) out1Addr Out2Addr:(NSData*) out2Addr SigMtrl: (NSData *)sigMtrl Mac: (NSData *)mac
{
    [self cwCmdExTrxSignPrepare:inId TrxHandle:trxHandle AccId:accId KcId:kcId KId:kId Out1Addr:out1Addr Out2Addr:out2Addr SigMtrl:sigMtrl Mac:mac];
}

-(void) exTrxSignPrepareWithInputId:(NSInteger)inId withInputData:(NSData *)inputData
{
    [self cwCmdExTrxSignPrepare:inId inputData:inputData];
}

-(void) exTrxSignLogoutWithTrxHandle:(NSData *)trxHandle Nonce: (NSData *)nonce withComplete:(void(^)(NSData *receipt))complete error:(void(^)(NSInteger errorCode))error
{
    self.exTrxSignLogoutCompleteBlock = complete;
    self.exTrxSignLogoutErrorBlock = error;
    [self cwCmdExTrxSignLogoutWithTrxHandle:trxHandle Nonce:nonce];
}


#pragma mark - BCDC Functions
#pragma mark BCDC functions - Basic
- (NSInteger) cwCmdGetModeState
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityTop;
    cmd.cmdCla = CwCmdIdGetModeStateCLA;
    cmd.cmdId = CwCmdIdGetModeState;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdGetFwVersion
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdGetFwVersionCLA;
    cmd.cmdId = CwCmdIdGetFwVersion;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdGetUid
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdGetUidCLA;
    cmd.cmdId = CwCmdIdGetUid;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdGetError
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdGetErrorCLA;
    cmd.cmdId = CwCmdIdGetError;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

#pragma mark BCDC functions - Authention

//Authentication Commands
- (NSInteger) cwCmdPinChlng
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //none
    
    //output:
    //pinChlng 16B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdPinChlngCLA;
    cmd.cmdId = CwCmdIdPinChlng;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}


- (NSInteger) cwCmdPinAuth: (NSString *)pin
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput;
    Byte devKey[32] = {0x00};
    Byte pinResp[16];
    unsigned long numBytesEncrypted;
    
    //input:
    //pinResp 16B, resp is calcualted by AES(chlng, pinHash)
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdPinAuthCLA;
    cmd.cmdId = CwCmdIdPinAuth;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    CC_SHA256([[pin dataUsingEncoding:NSUTF8StringEncoding] bytes], (CC_LONG)pin.length, devKey);
    
    //regResponse = enc(challenge, devKey);
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                                          devKey, kCCKeySizeAES256,
                                          nil /* initialization vector (optional) */,
                                          [pinChallenge bytes], pinChallenge.length, /* input */
                                          pinResp, sizeof(pinResp), /* output */
                                          &numBytesEncrypted);
    if (cryptStatus != kCCSuccess)
    {
        NSLog(@"cwCmdPinAuth Calculate Response Error (%d)", cryptStatus);
    }
    
    cmdInput = [NSMutableData dataWithBytes: pinResp length: sizeof(pinResp)];
    cmd.cmdInput = cmdInput; //pinHash
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdPinChange: (NSString *)oldPin NewPin: (NSString *)newPin
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput;
    Byte devKey[32] = {0x00};
    Byte newPinHash[32];
    Byte wrNewPinHash[32];
    Byte mac[32];
    unsigned long numBytesEncrypted;
    
    //input:
    //wrPinHash 32B     AES(newPinHash, oldPinHash)
    //MAC 32B           mac of wrPinHash
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdPinAuthCLA;
    cmd.cmdId = CwCmdIdPinAuth;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    CC_SHA256([[oldPin dataUsingEncoding:NSUTF8StringEncoding] bytes], (CC_LONG)oldPin.length, devKey);
    CC_SHA256([[newPin dataUsingEncoding:NSUTF8StringEncoding] bytes], (CC_LONG)newPin.length, newPinHash);
    
    
    //regResponse = enc(challenge, devKey);
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                                          devKey, kCCKeySizeAES256,
                                          nil /* initialization vector (optional) */,
                                          newPinHash, sizeof(newPinHash), /* input */
                                          wrNewPinHash, sizeof(wrNewPinHash), /* output */
                                          &numBytesEncrypted);
    if (cryptStatus != kCCSuccess)
    {
        NSLog(@"cwCmdPinChange Calculate Response Error (%d)", cryptStatus);
    }
    
    //TODO: calc mac of wrPinHash
    
    cmdInput = [NSMutableData dataWithBytes: wrNewPinHash length: sizeof(wrNewPinHash)];
    [cmdInput appendBytes: mac length: sizeof(mac)];
    
    cmd.cmdInput = cmdInput; //pinHash
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdPinLogout
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdPinLogoutCLA;
    cmd.cmdId = CwCmdIdPinLogout;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

#pragma mark BCDC functions - Host Binding
- (NSInteger) cwCmdBindRegInit: (BOOL)firstHost Credential:(NSString *)hostCredential Description: (NSString *)hostDescription
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //P1: firstHost: 1B //if mode=nohost YES, mode=disconn NO
    //hostCredential: 32B
    //hostDescription: 128B --> 64B
    //hash: 32B
    
    hostCredential=[hostCredential stringByReplacingOccurrencesOfString:@"-" withString:@""];
    Byte out[128] = {0}; //192
    NSData *outCredential = [hostCredential dataUsingEncoding:NSUTF8StringEncoding];
    NSData *outDescription = [hostDescription dataUsingEncoding:NSUTF8StringEncoding];
    
    memset(out, 0x00, 128); //192
    memcpy(out, [outCredential bytes], 32);
    memcpy(out+32, [outDescription bytes], outDescription.length);
    
    CC_SHA256(out, 96, out+96);
    //CC_SHA256(out, 160, out+160);
    
    //output:
    //bindRegHandle: 4B
    //bindRegOtp: 8B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdBindRegInitCLA;
    cmd.cmdId = CwCmdIdBindRegInit;
    cmd.cmdP1 = firstHost;
    cmd.cmdP2 = 0;
    cmd.cmdInput =[NSData dataWithBytes:out length:sizeof(out)];
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdBindRegChlng
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    if (regHandle==nil)
        return CwCardRetNeedInit;
    
    //input:
    //bindRegHandle: 4B
    
    //output:
    //regChlng 16B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdBindRegChlngCLA;
    cmd.cmdId = CwCmdIdBindRegChlng;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = regHandle;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdBindRegFinish: (NSString *)retOtp
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    NSMutableData *keyMaterial;
    NSMutableData *regOutput;
    
    Byte devKey[32] = {0x00};
    Byte regResponse[16];
    Byte pinResponse[16];
    unsigned long numBytesEncrypted;
    
    //input
    //bindRegHandle: 4B
    //regResponse: 16B
    //pinResponse: 16B (don't care)
    
    //calc devKey = hash(credential + retOtp)
    NSData *credential = [[self.devCredential stringByReplacingOccurrencesOfString:@"-" withString:@""] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *otp = [retOtp dataUsingEncoding:NSUTF8StringEncoding];
    
    keyMaterial = [NSMutableData dataWithBytes:[credential bytes] length: credential.length];
    [keyMaterial appendBytes:[otp bytes] length: otp.length];
    
    CC_SHA256([keyMaterial bytes], (CC_LONG)keyMaterial.length, devKey);
    
    //regResponse = enc(challenge, devKey);
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                                          devKey, kCCKeySizeAES256,
                                          nil /* initialization vector (optional) */,
                                          [regChallenge bytes], regChallenge.length, /* input */
                                          regResponse, sizeof(regResponse), /* output */
                                          &numBytesEncrypted);
    if (cryptStatus != kCCSuccess)
    {
        NSLog(@"cwCmdBindRegFinish Calculate Response Error (%d)", cryptStatus);
    }
    
    //output:
    //hostId: 1B
    //confirm: 1B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdBindRegFinishCLA;
    cmd.cmdId = CwCmdIdBindRegFinish;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    regOutput = [NSMutableData dataWithBytes: [regHandle bytes] length: regHandle.length];
    [regOutput appendBytes: regResponse length: sizeof(regResponse)];
    [regOutput appendBytes: pinResponse length: sizeof(pinResponse)];
    
    
    cmd.cmdInput = regOutput; //bindRegHandle + regResponse + pinResponse
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdBindRegInfo: (NSInteger)hostId
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //P1: hostId: 1B
    
    //output:
    //bindState: 1B (00 empty, 01 registered, 02 confirmed)
    //hostDescription: 128B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdBindRegInfoCLA;
    cmd.cmdId = CwCmdIdBindRegInfo;
    cmd.cmdP1 = hostId;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdBindRegApprove: (NSInteger)hostId
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //P1: hostId: 1B
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdBindRegApproveCLA;
    cmd.cmdId = CwCmdIdBindRegApprove;
    cmd.cmdP1 = hostId;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdBindRegRemove: (NSInteger)hostId
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //P1: hostId: 1B
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdBindRegRemoveCLA;
    cmd.cmdId = CwCmdIdBindRegRemove;
    cmd.cmdP1 = hostId;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdBindLoginChlng
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //P1: hostId: 1B
    
    //output:
    //loginChlng: 16B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdBindLoginChlngCLA;
    cmd.cmdId = CwCmdIdBindLoginChlng;
    cmd.cmdP1 = [self.hostId integerValue];
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdBindLogin
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    
    //input
    //P1: hostId 1B
    //loginResponse: 32B
    
    NSMutableData *keyMaterial;
    
    Byte devKey[32] = {0x00};
    Byte tmpKey[32] = {0x00};
    Byte loginResponse[16];
    unsigned long numBytesEncrypted;
    
    //calc devKey = hash(credential + retOtp)
    NSData *credential = [[self.devCredential stringByReplacingOccurrencesOfString:@"-" withString:@""] dataUsingEncoding:NSUTF8StringEncoding];
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:self.cardId accessGroup:nil];
    
    //get OTP form key chain
    self.hostOtp =[keychain objectForKey:(id)CFBridgingRelease(kSecAttrService)];
    
    NSData *otp = [self.hostOtp dataUsingEncoding:NSUTF8StringEncoding];
    
    keyMaterial = [NSMutableData dataWithBytes:[credential bytes] length: credential.length];
    [keyMaterial appendBytes:[otp bytes] length: otp.length];
    
    CC_SHA256([keyMaterial bytes], (CC_LONG)keyMaterial.length, devKey);
    
    //regResponse = enc(challenge, devKey);
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                                          devKey, kCCKeySizeAES256,
                                          nil /* initialization vector (optional) */,
                                          [loginChallenge bytes], loginChallenge.length, /* input */
                                          loginResponse, sizeof(loginResponse), /* output */
                                          &numBytesEncrypted);
    if (cryptStatus != kCCSuccess)
    {
        NSLog(@"cwCmdBindLogin Calculate Response Error (%d)", cryptStatus);
    }
    
    //Calculate Session Keys
    //BIND_SENCK = sha256(loginChallenge || devKey || "ENC")
    //BIND_SMACK = sha256(loginChallenge || devKey || "MAC")
    
    NSMutableData *senckMaterial;
    NSMutableData *smackMaterial;
    
    senckMaterial = [NSMutableData dataWithBytes:[loginChallenge bytes] length: loginChallenge.length];
    [senckMaterial appendBytes:devKey length: sizeof(devKey)];
    [senckMaterial appendBytes:[[@"ENC" dataUsingEncoding:NSUTF8StringEncoding] bytes]  length: 3];
    CC_SHA256([senckMaterial bytes], (CC_LONG)senckMaterial.length, tmpKey);
    encKey = [NSData dataWithBytes:tmpKey length:sizeof(tmpKey)];
    
    smackMaterial = [NSMutableData dataWithBytes:[loginChallenge bytes] length: loginChallenge.length];
    [smackMaterial appendBytes:devKey length: sizeof(devKey)];
    [smackMaterial appendBytes: [[@"MAC" dataUsingEncoding:NSUTF8StringEncoding] bytes] length: 3];
    CC_SHA256([smackMaterial bytes], (CC_LONG)smackMaterial.length, tmpKey);
    macKey = [NSData dataWithBytes:tmpKey length:sizeof(tmpKey)];
    
    memset(tmpKey, 0x00, sizeof(tmpKey));
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdBindLoginCLA;
    cmd.cmdId = CwCmdIdBindLogin;
    cmd.cmdP1 = [self.hostId integerValue];
    cmd.cmdP2 = 0;
    cmd.cmdInput = [NSData dataWithBytes:loginResponse length:16];;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdBindLogout
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityExclusive;
    cmd.cmdCla = CwCmdIdBindLogoutCLA;
    cmd.cmdId = CwCmdIdBindLogout;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdBindFindHostId: (NSString *)hostCredential
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //hostCredential 32B
    
    //output
    //hostId 1B
    //confirm 1B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdBindFindHostIdCLA;
    cmd.cmdId = CwCmdIdBindFindHostId;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = [hostCredential dataUsingEncoding:NSUTF8StringEncoding];
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdBindBackNoHost: (NSString *)pin NewPin: (NSString *)newPin
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput;
    Byte devKey[32] = {0x00};
    Byte pinResp[16];
    Byte newPinHash[32];
    Byte mac[32];
    unsigned long numBytesEncrypted;
    
    //input
    //pinResponse: 16B, used in disconn mode. no need (0x00) for perso mode
    //pinHash: 32B, used in perso mode, encrypted by BIND_CHAN, no need (0x00) for disconn mode
    ;
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityExclusive;
    cmd.cmdCla = CwCmdIdBindBackNoHostCLA;
    cmd.cmdId = CwCmdIdBindBackNoHost;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    //calculate pinHash (as key)
    CC_SHA256([[pin dataUsingEncoding:NSUTF8StringEncoding] bytes], (CC_LONG)pin.length, devKey);
    
    //calculate pinResponse
    //regResponse = enc(challenge, devKey);
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                                          devKey, kCCKeySizeAES256,
                                          nil /* initialization vector (optional) */,
                                          [pinChallenge bytes], pinChallenge.length, /* input */
                                          pinResp, sizeof(pinResp), /* output */
                                          &numBytesEncrypted);
    if (cryptStatus != kCCSuccess)
    {
        NSLog(@"cwCmdBindBackNoHost Calculate Response Error (%d)", cryptStatus);
    }
    
    //calculate newPinHash
    CC_SHA256([[newPin dataUsingEncoding:NSUTF8StringEncoding] bytes], (CC_LONG)newPin.length, newPinHash);
    
    //encrypt pinHash
    cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                          devKey, kCCKeySizeAES256,
                          nil /* initialization vector (optional) */,
                          newPinHash, sizeof(newPinHash), /* input */
                          newPinHash, sizeof(newPinHash), /* output */
                          &numBytesEncrypted);
    
    if (cryptStatus != kCCSuccess)
    {
        NSLog(@"cwCmdBindBackNoHost Calculate pinHash Error (%d)", cryptStatus);
    }
    
    cmdInput = [NSMutableData dataWithBytes: pinResp length: sizeof(pinResp)];
    [cmdInput appendBytes: newPinHash length: sizeof(newPinHash)];
    cmd.cmdInput = cmdInput; //pinResponse + pinHash
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

#pragma mark BCDC functions - Perso
- (NSInteger) CwCmdPersoSetData
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput;
    
    Byte sp[4] = {0x00, 0x00, 0x00, 0x00};
    Byte mac[32];
    
    //input
    //secuirtyPolicy 4B
    //mac 32B
    
    //input:
    //securePolicy 4B
    if (self.securityPolicy_OtpEnable.boolValue)
        sp[0]=sp[0]|CwSecurityPolicyMaskOtp;
    if (self.securityPolicy_BtnEnable.boolValue)
        sp[0]=sp[0]|CwSecurityPolicyMaskBtn;
    if (self.securityPolicy_DisplayAddressEnable.boolValue)
        sp[0]=sp[0]|CwSecurityPolicyMaskAddress;
    if (self.securityPolicy_WatchDogEnable.boolValue)
        sp[0]=sp[0]|CwSecurityPolicyMaskWatchDog;
    
    //Calc MAC by macKey
    //CC_SHA256(sp, sizeof(sp), mac);
    CCHmac (kCCHmacAlgSHA256, [macKey bytes], macKey.length, sp, sizeof(sp), mac);
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdPersoSetDataCLA;
    cmd.cmdId = CwCmdIdPersoSetData;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    cmdInput = [NSMutableData dataWithBytes:sp length: sizeof(sp)];
    [cmdInput appendBytes:mac length: sizeof(mac)];
    
    cmd.cmdInput = cmdInput; //secuirty + MAC
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdPersoConfirm
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //none
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdPersoConfirmCLA;
    cmd.cmdId = CwCmdIdPersoConfirm;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdPersoBackPerso: (NSString *)newPin
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput;
    Byte pinHash[CC_SHA256_DIGEST_LENGTH];
    
    //input:
    //encrypted newPinnHash 32B (no use)
    
    CC_SHA256([[newPin dataUsingEncoding:NSUTF8StringEncoding] bytes], (CC_LONG)newPin.length, pinHash);
    
    //Encrypt seed by encKey
    unsigned long numBytesEncrypted;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                                          [encKey bytes], kCCKeySizeAES256,
                                          nil /* initialization vector (optional) */,
                                          pinHash, sizeof(pinHash), /* input */
                                          pinHash, sizeof(pinHash), /* output */
                                          &numBytesEncrypted);
    
    if (cryptStatus != kCCSuccess)
    {
        NSLog(@"cwCmdPersoBackPerso Calculate Response Error (%d)", cryptStatus);
    }
    
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdPersoBackPersoCLA;
    cmd.cmdId = CwCmdIdPersoBackPerso;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    cmdInput = [NSMutableData dataWithBytes: pinHash length: sizeof(pinHash)];
    cmd.cmdInput = cmdInput; //pinHash
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

#pragma mark BCDC functions - Setting
- (NSInteger) cwCmdSetCurrRate: (NSDecimalNumber *)currRate;
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    Byte curr[5] = {0x00, 0x00, 0x00, 0x00, 0x00};
    
    //input:
    //currRate 5B
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdSetCurrRateCLA;
    cmd.cmdId = CwCmdIdSetCurrRate;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    //currRate *100 and Big-Endien
    long rate = ([currRate longValue]);
    for (int i=0; i<4; i++)
        curr[4-i]=(rate>>8*i)&0x000000FF;
    
    //host_int = be64toh( big_endian );
    
    cmd.cmdInput = [[NSData alloc] initWithBytes:curr length:sizeof(curr)];
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdGetCurrRate
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //none
    
    //output:
    //currRate 5B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdGetCurrRateCLA;
    cmd.cmdId = CwCmdIdGetCurrRate;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdGetCardName
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //none
    
    //output:
    //cardName 32B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdGetCardNameCLA;
    cmd.cmdId = CwCmdIdGetCardName;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdSetCardName: (NSString *)cardName
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    Byte nameOutput[32];
    
    //input:
    //cardName 32B
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdSetCardNameCLA;
    cmd.cmdId = CwCmdIdSetCardName;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    NSData *cName = [cardName dataUsingEncoding:NSUTF8StringEncoding];
    
    memset(nameOutput, 0x00, sizeof(nameOutput));
    memcpy(nameOutput, [cName bytes], cName.length);
    
    cmd.cmdInput = [NSData dataWithBytes:nameOutput length:sizeof(nameOutput)];//cardName
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdGetPerso
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //none
    
    //output:
    //securePolicy: 4B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdGetPersoCLA;
    cmd.cmdId = CwCmdIdGetPerso;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdSetPerso
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    Byte sp[4] = {0x00, 0x00, 0x00, 0x00};
    
    //input:
    //securePolicy 4B
    if (self.securityPolicy_OtpEnable.boolValue)
        sp[0]=sp[0]|CwSecurityPolicyMaskOtp;
    if (self.securityPolicy_BtnEnable.boolValue)
        sp[0]=sp[0]|CwSecurityPolicyMaskBtn;
    if (self.securityPolicy_DisplayAddressEnable.boolValue)
        sp[0]=sp[0]|CwSecurityPolicyMaskAddress;
    if (self.securityPolicy_WatchDogEnable.boolValue)
        sp[0]=sp[0]|CwSecurityPolicyMaskWatchDog;
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdSetPersoCLA;
    cmd.cmdId = CwCmdIdSetPerso;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = [[NSData alloc] initWithBytes:sp length:sizeof(sp)];
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}


- (NSInteger) cwCmdGetCardId
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //none
    
    //output:
    //cardName 32B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdGetCardIdCLA;
    cmd.cmdId = CwCmdIdGetCardId;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

#pragma mark BCDC functions - HDW
- (NSInteger) cwCmdHdwInitWallet: (NSString *)hdwName Seed: (NSString *)hdwSeed
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput;
    
    Byte name[32] = {0x00};
    Byte seed[64];
    Byte encSeed[64];
    Byte mac[CC_SHA256_DIGEST_LENGTH];
    
    //input:
    //hdwName 32B
    //hdwSeed 64B //encrypted
    //mac 32B
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdHdwInitWalletCLA;
    cmd.cmdId = CwCmdIdHdwInitWallet;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    //name
    NSData *hName = [hdwName dataUsingEncoding:NSUTF8StringEncoding];
    
    memset(name, 0x00, sizeof(name));
    memcpy(name, [hName bytes], hName.length);
    
    //seed
    NSMutableData *seedToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([hdwSeed length] / 2); i++) {
        byte_chars[0] = [hdwSeed characterAtIndex:i*2];
        byte_chars[1] = [hdwSeed characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [seedToSend appendBytes:&whole_byte length:1];
    }
    
    memset(seed, 0x00, sizeof(seed));
    memcpy(seed, [seedToSend bytes], seedToSend.length);
    
    //Encrypt seed by encKey
    unsigned long numBytesEncrypted;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                                          [encKey bytes], kCCKeySizeAES256,
                                          nil /* initialization vector (optional) */,
                                          seed, sizeof(seed), /* input */
                                          encSeed, sizeof(encSeed), /* output */
                                          &numBytesEncrypted);
    
    if (cryptStatus != kCCSuccess)
    {
        NSLog(@"cwCmdHdwInitWallet Calculate Response Error (%d)", cryptStatus);
    }
    
    //Calc MAC by macKey
    CCHmac (kCCHmacAlgSHA256, [macKey bytes], macKey.length, encSeed, sizeof(encSeed), mac);
    
    
    cmdInput = [NSMutableData dataWithBytes: name length: sizeof(name)];
    [cmdInput appendBytes: encSeed length: sizeof(encSeed)];
    [cmdInput appendBytes: mac length: sizeof(mac)];
    
    cmd.cmdInput = cmdInput; //hdwName + hdwSeed + mac
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdHdwInitWalletGen: (NSString *)hdwName SeedLen: (NSInteger) seedLen
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput;
    
    Byte name[32] = {0x00};
    Byte slen[1] = {seedLen/2}; //BCD length
    Byte passPhrase[3] = {0x02, 0x30, 0x31};
    
    //input:
    //hdwName 32B
    //seedLen 1B (=24/36/48)
    //passPhraseLen: 1B (=0)
    
    //output:
    //seedString: 12/18/24B, BCD format
    //activeCode: 4B
    //mac: (seedString || activeCode)
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdHdwInitWalletGenCLA;
    cmd.cmdId = CwCmdIdHdwInitWalletGen;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    //name
    NSData *hName = [hdwName dataUsingEncoding:NSUTF8StringEncoding];
    
    memset(name, 0x00, sizeof(name));
    memcpy(name, [hName bytes], hName.length);
    
    cmdInput = [NSMutableData dataWithBytes: name length: sizeof(name)];
    [cmdInput appendBytes: slen length: sizeof(slen)];
    passPhrase[0]=0x00;
    [cmdInput appendBytes: passPhrase length: 1];
    //[hdwData appendBytes: passPhraseLen length: sizeof(passPhraseLen)];
    
    cmd.cmdInput = cmdInput; //hdwName+seedLen+passPrhraseLen
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdHdwInitWalletGenConfirm: (NSData *) activeCode Sum: (NSString *)sumOfSeeds
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    NSMutableData *cmdInput;
    
    //input
    //activeCode 4B
    //sumOfSeeds 6B
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdHdwInitWalletGenConfirmCLA;
    cmd.cmdId = CwCmdIdHdwInitWalletGenConfirm;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    //substring of sumOfSeeds, we need 6 digits only
    if (sumOfSeeds.length>6)
        sumOfSeeds = [sumOfSeeds substringFromIndex:sumOfSeeds.length-6];
    
    cmdInput = [NSMutableData dataWithBytes: [activeCode bytes] length: 4];
    [cmdInput appendData: [sumOfSeeds dataUsingEncoding:NSUTF8StringEncoding]];
    
    cmd.cmdInput = cmdInput;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdHdwQueryWalletInfo: (NSInteger) infoId
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //P1: infoId 1B (=00 status, 01 name, 02 accountPointer)
    
    //output:
    //infoId 1B (=00/01/02)
    //hwdInfo:
    //  hwdStatus 1B
    //  hwdName 32B
    //  hwdAccountPointer 4B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdHdwQueryWalletInfoCLA;
    cmd.cmdId = CwCmdIdHdwQueryWalletInfo;
    cmd.cmdP1 = infoId;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdHdwSetWalletInfo: (NSInteger) infoId Info: (NSData *)hdwInfo
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    Byte info[32] = {0x00};
    NSInteger infoLen;
    
    //input:
    //P1: infoId 1B (01 name, 02 accountPointer)
    //hdwInfo:
    //  hwdName 32B
    //  hwdAccountPointer 4B
    
    //output:
    //none
    
    if (infoId == 1) {
        memcpy(info, [hdwInfo bytes], hdwInfo.length);
        infoLen = 32;
    } else if (infoId==2) {
        memcpy(info, [hdwInfo bytes], hdwInfo.length);
        infoLen = 4;
    }
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdHdwSetWalletInfoCLA;
    cmd.cmdId = CwCmdIdHdwSetWalletInfo;
    cmd.cmdP1 = infoId;
    cmd.cmdP2 = 0;
    cmd.cmdInput = [NSData dataWithBytes:info length:infoLen];; //hdwInfo (name or accountPointer)
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdHdwCreateAccount: (NSInteger)accountId AccountName: (NSString *)accountName
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput;
    
    Byte name[32] = {0x00};
    
    //input:
    //accountId: 4B (little Endian)
    //accountName: 32B
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdHdwCreateAccountCLA;
    cmd.cmdId = CwCmdIdHdwCreateAccount;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    //name
    NSData *hName = [accountName dataUsingEncoding:NSUTF8StringEncoding];
    
    memset(name, 0x00, sizeof(name));
    memcpy(name, [hName bytes], hName.length);
    
    cmdInput = [NSMutableData dataWithBytes: &accountId length: 4];
    [cmdInput appendBytes: name length: sizeof(name)];
    
    cmd.cmdInput = cmdInput; //accountId + accountName
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdHdwQueryAccountInfo: (NSInteger)infoId AccountId: (NSInteger)accountId
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //P1: infoId: 1B (00 name, 01 balance, 02 ext key pointer, 03 int key pointer)
    //accountId 4B
    
    //output:
    //accountInfo
    //  accountName 32B
    //  balance 8B
    //  extKeyPointer   4B
    //  intKeyPointer   4B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdHdwQueryAccountInfoCLA;
    cmd.cmdId = CwCmdIdHdwQueryAccountInfo;
    cmd.cmdP1 = infoId;
    cmd.cmdP2 = 0;
    
    //NSInteger to NSData
    NSData *accId = [NSData dataWithBytes:&accountId length:4];
    
    cmd.cmdInput = accId; //accountId
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdHdwSetAccountInfo: (NSInteger)infoId AccountId: (NSInteger)accountId AccountInfo: (NSData *)accountInfo
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput;
    
    
    Byte accInfo[32] = {0x00};
    NSInteger accInfoLen = 0;
    Byte mac[CC_SHA256_DIGEST_LENGTH];
    
    NSInteger priority = CwCardCommandPriorityNone;
    if (infoId == CwHdwAccountInfoExtKeyPtr || infoId == CwHdwAccountInfoIntKeyPtr) {
        priority = CwCardCommandPriorityTop;
    }
    
    //input:
    //P1: infoId: 1B
    //accountId: 4B
    //accountInfo
    //  accountName 32B
    //  balance 8B
    //  extKeyPointer   4B
    //  intKeyPointer   4B
    //mac 32B (of accountInfo)
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = priority;
    cmd.cmdCla = CwCmdIdHdwSetAccountInfoCLA;
    cmd.cmdId = CwCmdIdHdwSetAccountInfo;
    cmd.cmdP1 = infoId;
    cmd.cmdP2 = 0;
    
    memset(accInfo, 0x00, sizeof(accInfo));
    memcpy(accInfo, [accountInfo bytes], accountInfo.length);
    
    switch(cmd.cmdP1) {
        case CwHdwAccountInfoName:
            accInfoLen = 32;
            break;
        case CwHdwAccountInfoBalance:
            accInfoLen = 8;
            //convert the accInfo to big-endian
            for (int i=0; i<accInfoLen; i++)
                accInfo[i]=((Byte *)[accountInfo bytes])[accInfoLen-i-1];
            break;
        case CwHdwAccountInfoExtKeyPtr:
            accInfoLen = 4;
            break;
        case CwHdwAccountInfoIntKeyPtr:
            accInfoLen = 4;
            break;
    }
    
    //Calc MAC by macKey
    CCHmac (kCCHmacAlgSHA256, [macKey bytes], macKey.length, accInfo, accInfoLen, mac);
    
    //NSInteger to NSData
    cmdInput = [NSMutableData dataWithBytes:&accountId length:4];
    [cmdInput appendBytes:accInfo length: accInfoLen];
    [cmdInput appendBytes: mac length: sizeof(mac)];
    
    /*
     Byte tmp[accData.length];
     memcpy(tmp, [accData bytes], accData.length);
     
     for (int i=0; i<accData.length; i++)
     NSLog(@"%02d %02X", i, tmp[i]);
     */
    
    cmd.cmdInput = cmdInput; //accountId + accountInfo + mac
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdHdwGetNextAddress: (NSInteger) keyChainId AccountId: (NSInteger)accountId
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //P1: keyChainId 1B
    //accountId 4B
    
    //output
    //keyId 4B
    //address 25B
    //mac 32B (of keyId||address)
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdHdwGetNextAddressCLA;
    cmd.cmdId = CwCmdIdHdwGetNextAddress;
    cmd.cmdP1 = keyChainId;
    cmd.cmdP2 = 0;
    cmd.cmdInput = [NSData dataWithBytes:&accountId length:4]; //accountId
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdHdwPrepTrxSign: (NSInteger)inputId KeyChainId: (NSInteger) keyChainId AccountId: (NSInteger)accountId KeyId: (NSInteger)keyId Amount:(int64_t)amount SignatureMateiral:(NSData *)signatureMaterial

{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput = [[NSMutableData alloc] init];
    Byte mac[CC_SHA256_DIGEST_LENGTH];
    int64_t amount_bn; //big endian of amount
    
    //input
    //P1: inputId 1B
    //P2: keyChainId 1B
    //accountId 4B
    //keyId 4B
    //amount 8B
    //signatureMaterial 32B
    //mac 32B (of accountId + keyId + amount + signatureMaterial
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdHdwPrepTrxSignCLA;
    cmd.cmdId = CwCmdIdHdwPrepTrxSign;
    cmd.cmdP1 = inputId;
    cmd.cmdP2 = keyChainId;
    
    cmdInput = [NSMutableData dataWithBytes: &accountId length: 4];
    [cmdInput appendBytes: &keyId length: 4];
    amount_bn = CFSwapInt64((int64_t)amount);
    [cmdInput appendBytes: &amount_bn length:8];
    [cmdInput appendData:signatureMaterial];
    
    //Calc MAC by macKey (accId||kid|balance||sigMtrl)
    CCHmac (kCCHmacAlgSHA256, [macKey bytes], macKey.length, [cmdInput bytes], 48, mac);
    
    [cmdInput appendBytes: mac length: sizeof(mac)];
    
    cmd.cmdInput = cmdInput; //accountId + keyId + amount + signatureMaterial + mac
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdHdwQueryAccountKeyInfo: (NSInteger)keyInfoId KeyChainId: (NSInteger) keyChainId AccountId: (NSInteger)accountId KeyId: (NSInteger)keyId
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput;
    
    //input
    //P1: keyInfoId 1B (00 address25B, 01 publickey 64B, 02 key chain public key and chain code 64B + 32B )
    //P2: keyChainId 1B
    //accountId 4B
    //keyId 4B
    
    //output
    //keyInfo
    //  address 25B
    //  publicKey 64B
    //  key chain public key 64B
    //  Key chain chain code 32B
    //mac 32B (of KeyInfo)
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdHdwQueryAccountKeyInfoCLA;
    cmd.cmdId = CwCmdIdHdwQueryAccountKeyInfo;
    cmd.cmdP1 = keyInfoId;
    cmd.cmdP2 = keyChainId;
    
    cmdInput = [NSMutableData dataWithBytes: &accountId length: 4];
    [cmdInput appendBytes: &keyId length: 4];
    
    cmd.cmdInput = cmdInput; //accountId + keyId
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

#pragma mark BCDC functions - Transaction
- (NSInteger) cwCmdTrxStatus
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //status 1B (00 idle, 01 preparing, 02 begined, 03 opt veriried, 04 in process
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdTrxStatusCLA;
    cmd.cmdId = CwCmdIdTrxStatus;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdTrxGetAddr
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //address
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdTrxGetAddrCLA;
    cmd.cmdId = CwCmdIdTrxGetAddr;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdTrxBegin: (int64_t) amount Address: (NSString *)recvAddr
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput;
    int64_t amount_bn; //big endian of amount
    
    //input
    //amount 8B
    //encrypted receiverAddress 48B (25B and padding 0s)
    
    //output
    //otp 8B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdTrxBeginCLA;
    cmd.cmdId = CwCmdIdTrxBegin;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    NSData *data = [recvAddr dataUsingEncoding:NSUTF8StringEncoding];
    
    Byte addr[48];
    memset(addr, 0x00, 48);
    memcpy(addr, data.bytes, data.length);
    
    //Encrypt addr by encKey
    unsigned long numBytesEncrypted;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                                          [encKey bytes], kCCKeySizeAES256,
                                          nil /* initialization vector (optional) */,
                                          addr, sizeof(addr), /* input */
                                          addr, sizeof(addr), /* output */
                                          &numBytesEncrypted);
    
    if (cryptStatus != kCCSuccess)
    {
        NSLog(@"cwCmdTrxBegin Calculate Response Error (%d)", cryptStatus);
    }
    
    amount_bn = CFSwapInt64((int64_t)amount);
    cmdInput = [NSMutableData dataWithBytes: &amount_bn length:8];
    [cmdInput appendBytes: addr length: sizeof(addr)];
    
    cmd.cmdInput = cmdInput; //amount
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdTrxVerifyOtp: (NSString *)otp
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    if (trxStatus==TrxStatusWaitOtp) {
        trxStatus=TrxStatusGetOtp;
    }
    
    NSLog(@"trxStatus = %ld", (long)trxStatus);
    
    //input
    //otp 6B
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdTrxVerifyOtpCLA;
    cmd.cmdId = CwCmdIdTrxVerifyOtp;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    cmd.cmdInput = [otp dataUsingEncoding:NSUTF8StringEncoding]; //otp
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdTrxSign: (NSInteger)inputId
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //P1: inputId 1B
    
    //ouput
    //signature 64B
    //mac 32B (of signature)
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdTrxSignCLA;
    cmd.cmdId = CwCmdIdTrxSign;
    cmd.cmdP1 = inputId;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdTrxFinish
{
    
    trxStatus = TrxStatusFinish;
    
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdTrxFinishCLA;
    cmd.cmdId = CwCmdIdTrxFinish;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}


#pragma marks MCU commands
- (NSInteger) cwCmdMcuResetSe
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityExclusive;
    cmd.cmdCla = CwCmdIdMcuResetSeCLA;
    cmd.cmdId = CwCmdIdMcuResetSe;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdMcuSetAccount: (NSInteger)accId
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityTop;
    cmd.cmdCla = CwCmdIdMcuSetAccountCLA;
    cmd.cmdId = CwCmdIdMcuSetAccount;
    cmd.cmdP1 = accId;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdMcuGenOtp
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityTop;
    cmd.cmdCla = CwCmdIdMcuGenOtpCLA;
    cmd.cmdId = CwCmdIdMcuGenOtp;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdMcuVerifyOtp: (NSString *)otp
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityTop;
    cmd.cmdCla = CwCmdIdMcuVerifyOtpCLA;
    cmd.cmdId = CwCmdIdMcuVerifyOtp;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = [otp dataUsingEncoding:NSUTF8StringEncoding]; //otp
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdMcuDisplayUsd: (NSInteger) option
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityTop;
    cmd.cmdCla = CwCmdIdMcuDisplayUsdCLA;
    cmd.cmdId = CwCmdIdMcuDisplayUsd;
    cmd.cmdP1 = option;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

#pragma marks FirmwareUpdate Commands
- (NSInteger) cwCmdBackToLoader: (NSString *)otp
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdClaKeepNone;
    cmd.cmdId = CwCmdIdBackToLoader;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = [self dataFromHexString: otp];
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

#pragma marks SPI Loader Commands
//Loader Commands
/*
 LoaderCmdIdEcho         = 0xBE,
 LoaderCmdIdGetSn        = 0xC0,
 LoaderCmdIdGetVersion   = 0xC1,
 LoaderCmdIdGetStatus    = 0xC2,
 */

- (NSInteger) loaderCmdBackTo7816Loader
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdClaKeepNone;
    cmd.cmdId = LoaderCmdIdBackToSLE97Loader;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) loaderCmdIdEcho: (NSString *)testString
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //testString
    
    //output
    //testString
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdClaKeepPower;
    cmd.cmdId = LoaderCmdIdEcho;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput =  [testString dataUsingEncoding:NSUTF8StringEncoding];
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}


- (NSInteger) loaderCmdIdGetSn
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //SN: 8bytes
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdClaKeepPower;
    cmd.cmdId = LoaderCmdIdGetSn;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput =  nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) loaderCmdIdGetVersion
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //Version: 16bytes
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdClaKeepPower;
    cmd.cmdId = LoaderCmdIdGetVersion;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput =  nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) loaderCmdIdGetStatus
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //status: 4bytes user mode/wait/loading/check/complete
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdClaKeepPower;
    cmd.cmdId = LoaderCmdIdGetStatus;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput =  nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) loaderCmdBackToSLE97Loader: (NSString *)authMaterial
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //authMaterial 64bytes
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdClaKeepNone;
    cmd.cmdId = LoaderCmdIdBackToSLE97Loader;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = [self dataFromHexString: authMaterial];
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

/*
 LoaderCmdIdLoadingBegin = 0xD0,
 LoaderCmdIdWriteRecord  = 0xD1,
 LoaderCmdIdVerifyMac    = 0xD2
 */

- (NSInteger) loaderCmdLoadingBegin: (NSString *)authMaterial
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //authMaterial 64bytes
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdClaKeepPower;
    cmd.cmdId = LoaderCmdIdLoadingBegin;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = [self dataFromHexString: authMaterial];
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) LoaderCmdWriteRecord: (NSString *)hexRecord
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //hexRecord n bytes
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdClaKeepPower;
    cmd.cmdId = LoaderCmdIdWriteRecord;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = [self dataFromHexString: hexRecord];
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) loaderCmdVerifyMac: (NSString *)mac
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //mac 32bytes
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdClaKeepPower;
    cmd.cmdId = LoaderCmdIdVerifyMac;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = [self dataFromHexString: mac];
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

#pragma marks Exchange Site Commands
/*
 //Exchange Site Commands
 CwCmdIdExRegStatus      = 0xF0,
 CwCmdIdExGetOtp         = 0xF4,
 CwCmdIdExSessionInit    = 0xF5,
 CwCmdIdExSessionEstab   = 0xF6,
 CwCmdIdExSessionLogout  = 0xF7,
 */

- (NSInteger) cwCmdExRegStatus
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //regStat 1B 00 not reg, 01 init, 02 registered
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdExRegStatusCLA;
    cmd.cmdId = CwCmdIdExRegStatus;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdExGetOtpWithOption:(NSInteger)infoId
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //OTP 6B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdExGetOtpCLA;
    cmd.cmdId = CwCmdIdExGetOtp;
    cmd.cmdP1 = infoId;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}


- (NSInteger) cwCmdExSessionInit: (NSData *)svrChlng
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //svrChlng 16B
    
    //output:
    //seResp 16B
    //seChlng 16B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdExSessionInitCLA;
    cmd.cmdId = CwCmdIdExSessionInit;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = svrChlng;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdExSessionEstab: (NSData *)svrResp
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //svrResp 16B
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdExSessionEstabCLA;
    cmd.cmdId = CwCmdIdExSessionEstab;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = svrResp;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdExSessionLogout
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //none
    
    //output
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityTop;
    cmd.cmdCla = CwCmdIdExSessionLogoutCLA;
    cmd.cmdId = CwCmdIdExSessionLogout;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

/*
 CwCmdIdExBlockInfo      = 0xF8,
 CwCmdIdExBlockBtc       = 0xF9,
 CwCmdIdExBlockCancel    = 0xFA,
 */

- (NSInteger) cwCmdExBlockInfo: (NSData *)okTkn
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //okTkn 4B
    
    //output:
    //state 1B
    //accId 4B little-endian
    //amount 8B big-endian
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdExBlockInfoCLA;
    cmd.cmdId = CwCmdIdExBlockInfo;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = okTkn;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdExBlockBtc: (NSInteger)trxId AccId: (NSInteger)accId Amount: (int64_t)amount Mac1: (NSData *)mac1 Nonce: (NSData*)nonce
{
    NSMutableData *cmdInput = [[NSMutableData alloc] init];
    int64_t amount_bn; //big endian of amount
    
    //input:
    //trxId 4B
    //accId 4B little-endian
    //amount: 8B big-endian
    //mac1: 32B mac of (trxId||accId||amount), key is XCHS_SK
    //nonce: 16B nonce for block signature
    
    cmdInput = [NSMutableData dataWithBytes: &trxId length: 4];
    [cmdInput appendBytes: &accId length: 4];
    amount_bn = CFSwapInt64((int64_t)amount);
    [cmdInput appendBytes: &amount_bn length: 8];
    [cmdInput appendData: mac1];
    [cmdInput appendData: nonce];
    
    return [self cwCmdExBlockBtc:cmdInput];
}

-(NSInteger) cwCmdExBlockBtc:(NSData *)input
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //output:
    //blkSig: 32B block signature, mac of (cardId||uid||trxId||accId||amount||nonce||nonceSe), key is XCHS_SMK
    //okTkn: 4B
    //encUblkTkn: 16B encrypted unblock token, ublkTkn is (prefix 8B || amount 8B), key is ???
    //MAC2: 32B mac of (blkSig||okTkn||ublkTkn), key is XCHS_SK
    //nonceSe: 16B nonce generated by SE
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdExBlockBtcCLA;
    cmd.cmdId = CwCmdIdExBlockBtc;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    cmd.cmdInput = input;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdExBlockCancel: (NSData *)trxId OkTkn: (NSData *)okTkn EncUblkTkn: (NSData *)encUblkTkn Mac1: (NSData *)mac1 Nonce: (NSData*)nonce
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput = [[NSMutableData alloc] init];
    
    //input:
    //trxId 4B
    //okTkn 4B
    //encUblkTkn 16B encrypted ublkTkn, ublkTkn is (prefix 8B || amount 8B), key is???
    //mac1: 32B mac of (trxId||okTkn||ublkTkn), key is XCHS_SK
    //nonce: 16B nonce for unblock signature
    
    //output:
    //ublkSig: 32B block signature, mac of (cardId||uid||trxId||accId||amount||nonce||nonceSe), key is XCHS_SMK
    //MAC2: 32B mac of (ublkSig), key is XCHS_SK
    //nonceSe: 16B nonce generated by SE
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdExBlockCancelCLA;
    cmd.cmdId = CwCmdIdExBlockCancel;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    cmdInput = [NSMutableData dataWithData:trxId];
    [cmdInput appendData: okTkn];
    [cmdInput appendData: encUblkTkn];
    [cmdInput appendData: mac1];
    [cmdInput appendData: nonce];
    
    cmd.cmdInput = cmdInput;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

/*
 CwCmdIdExTrxSignLogin   = 0xFB,
 CwCmdIdExTrxSignPrepare = 0xFC,
 CwCmdIdExTrxSignLogout  = 0xFD,
 */

- (NSInteger) cwCmdExTrxSignLogin: (NSInteger)trxId OkTkn:(NSData *)okTkn EncUblkTkn:(NSData *)encUblkTkn AccId: (NSInteger)accId DealAmount: (int64_t)dealAmount Mac: (NSData *)mac
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput = [[NSMutableData alloc] init];
    int64_t amount_bn; //big endian of amount
    
    //input:
    //trxId 4B
    //okTkn 4B
    //encUblkTkn 16B
    //accId 4B little-endian
    //dealAmount: 8B big-endian
    //mac: 32B mac of (trxId||okTkn||ublkTkn||accId||dealAmount), key is XCHS_SK
    
    //output:
    //trHandle 4B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdExTrxSignLoginCLA;
    cmd.cmdId = CwCmdIdExTrxSignLogin;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    cmdInput = [NSMutableData dataWithBytes: &trxId length: 4];
    [cmdInput appendData: okTkn];
    [cmdInput appendData: encUblkTkn];
    [cmdInput appendBytes: &accId length: 4];
    amount_bn = CFSwapInt64((int64_t)dealAmount);
    [cmdInput appendBytes: &amount_bn length: 8];
    [cmdInput appendData: mac];
    
    cmd.cmdInput = cmdInput;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdExTrxSignLogin:(NSString *)input
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //trxId 4B
    //okTkn 4B
    //encUblkTkn 16B
    //accId 4B little-endian
    //dealAmount: 8B big-endian
    //mac: 32B mac of (trxId||okTkn||ublkTkn||accId||dealAmount), key is XCHS_SK
    
    //output:
    //trHandle 4B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdExTrxSignLoginCLA;
    cmd.cmdId = CwCmdIdExTrxSignLogin;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    cmd.cmdInput = [NSString hexstringToData:input];
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}


- (NSInteger) cwCmdExTrxSignPrepare: (NSInteger)inId TrxHandle:(NSData *)trxHandle AccId: (NSInteger)accId KcId: (NSInteger)kcId KId: (NSInteger)kId Out1Addr: (NSData*) out1Addr Out2Addr:(NSData*) out2Addr SigMtrl: (NSData *)sigMtrl Mac: (NSData *)mac
{
    NSMutableData *cmdInput = [[NSMutableData alloc] init];
    
    //input:
    //P1: inId
    //trxHandle: 4B
    //accId 4B little-endian
    //kcId 4B little-endian
    //kId 4B little-endian
    //out1Addr 25B
    //out2Addr 25B
    //sigMtrl 32B
    //mac: 32B mac of (accId||kcId||kid||out1Addr||out2Addr||sigMtrl), key is XCHS_SK
    
    //output:
    //none
    
    cmdInput = [NSMutableData  dataWithBytes:[trxHandle bytes] length:4];
    [cmdInput appendBytes: &accId length: 4];
    [cmdInput appendBytes: &kcId length: 4];
    [cmdInput appendBytes: &kId length: 4];
    [cmdInput appendData: out1Addr];
    [cmdInput appendData: out2Addr];
    [cmdInput appendData: sigMtrl];
    [cmdInput appendData: mac];
    
    return [self cwCmdExTrxSignPrepare:inId inputData:cmdInput];
}

- (NSInteger) cwCmdExTrxSignPrepare:(NSInteger)inId inputData:(NSData *)cmdInput
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    cmd.cmdPriority = CwCardCommandPriorityNone;
    
    cmd.cmdCla = CwCmdIdExTrxSignPrepareCLA;
    cmd.cmdId = CwCmdIdExTrxSignPrepare;
    cmd.cmdP1 = inId;
    cmd.cmdP2 = 0;
    cmd.cmdInput = cmdInput;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdExTrxSignLogoutWithTrxHandle:(NSData *)trxHandle Nonce: (NSData *)nonce
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput = [[NSMutableData alloc] init];
    
    //input:
    //trxHandle: 4B
    //nonce: 16B
    
    //output:
    //sigRcpt 32B mac of (cardId||uid||trxId||accId||dealAmount||numInputs||out1Addr||out2Addr||nonce||nonceSe), key is XCHS_SMK
    //mac: 32B mac of (sigRcpt), key is XCHS_SK
    //nonceSe: 16B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdExTrxSignLogoutCLA;
    cmd.cmdId = CwCmdIdExTrxSignLogout;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    
    cmdInput = [NSMutableData  dataWithBytes:[trxHandle bytes] length:4];
    [cmdInput appendData: nonce];
    
    cmd.cmdInput = cmdInput;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

-(void) cmdClear
{
    [cwCmds removeAllObjects];
}

#pragma mark - Internal Methods

-(void) cmdAdd: (CwCardCommand *)cmd
{
    for (int i=0; i<cwCmds.count; i++) {
        if (cmd.cmdCla == ((CwCardCommand*)cwCmds[i]).cmdCla &&
            cmd.cmdId == ((CwCardCommand*)cwCmds[i]).cmdId &&
            cmd.cmdP1 == ((CwCardCommand*)cwCmds[i]).cmdP1 &&
            cmd.cmdP2 == ((CwCardCommand*)cwCmds[i]).cmdP2 &&
            cmd.cmdPriority == ((CwCardCommand*)cwCmds[i]).cmdPriority)
        {
            if (cmd.cmdInput !=nil)
                if ([cmd.cmdInput isEqualToData:((CwCardCommand*)cwCmds[i]).cmdInput])
                    //found a match command
                    return;
        }
    }
    [cwCmds addObject:cmd];
}

-(void) cmdRemoveWithCmdId:(NSInteger)cmdId
{
    NSArray *result = [cwCmds filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.cmdId == %ld", cmdId]];
    if (result.count > 0) {
        [cwCmds removeObjectsInArray:result];
    }
}

-(void) cmdProcessor
{
    if (currentCmd.busy) {
        //wait for delegate
        //NSLog(@"Cmd Busy");
        
        return;
    }
    
    if (cwCmds.count>0) {
        //Get 1st item from array
        //NSLog(@"Process Cmd:%@", currentCmd);
        
        //check exclusive commands
        for (int i=0; i<cwCmds.count; i++) {
            if (((CwCardCommand *)cwCmds[i]).cmdPriority == CwCardCommandPriorityExclusive) {
                currentCmd = cwCmds[i];
                currentCmd.busy = YES;
                [cwCmds removeAllObjects];
                break;
            }
        }
        
        //check top commands
        if (! currentCmd.busy) {
            for (int i=0; i<cwCmds.count; i++) {
                if (((CwCardCommand *)cwCmds[i]).cmdPriority == CwCardCommandPriorityTop) {
                    currentCmd = cwCmds[i];
                    currentCmd.busy = YES;
                    [cwCmds removeObjectAtIndex:i];
                    break;
                }
            }
        }
        
        //no exclusive/top commands
        if (! currentCmd.busy) {
            currentCmd = cwCmds[0];
            currentCmd.busy = YES;
            [cwCmds removeObjectAtIndex:0];
        }
        
        [self BLE_SendCmd:currentCmd];
        
    } else {
        //no more command in the arrray. call delegate
        if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
            [self.delegate didCwCardCommand];
        }
    }
}

-(void) updateCwCardByCommand: (CwCardCommand *)cmd
{
    const unsigned char *data = [cmd.cmdOutput bytes];
    CwHost *host;
    NSString *exOtp;
    
    if (cmd==nil)
        return;
    
    if (cmd.cmdResult!=0x9000) {
        NSString *errString;
        BOOL callDelegate=NO;
        
        switch (cmd.cmdResult) {
            case ERR_CMD_NOT_SUPPORT: errString = @"Mode error, Command Not Support";
                break;
            case ERR_BIND_LOGIN: errString = @"Login Error";
                callDelegate = YES;
                break;
            case ERR_MCU_CMD_NOT_ALLOW: errString = @"Command Not Allow";
                callDelegate = YES;
                break;
            case ERR_MCU_CMD_TIME_OUT: errString = @"Command Timeout";
                callDelegate = YES;
                break;
            case ERR_HDW_STATUS: errString = @"HDW Status Error";
                break;
            case ERR_AUTHFAIL: errString = @"Authentication Error";
                callDelegate = YES;
                break;
            case ERR_FW_UPDATE_OTP: errString = @"Firmware Auth Error";
                callDelegate = YES;
                break;
            case ERR_HDW_SUM: errString = @"Sum Error";
                callDelegate = YES;
                break;
            case ERR_BCDC_TRX_STATE: errString = @"Transaction State Error";
                break;
            case ERR_TRX_VERIFY_OTP: errString = @"OTP Error";
                break;
            case ERR_BIND_REGRESP: errString = @"Pair with device Fail";
                callDelegate = YES;
                break;
            default: errString = [NSString stringWithFormat:@"Command Error %04lX", (long)cmd.cmdResult];
                callDelegate = YES;
                break;
        }
        
        if (callDelegate && [self.delegate respondsToSelector:@selector(didCwCardCommandError:ErrString:)]) {
            [self.delegate didCwCardCommandError:cmd.cmdId ErrString:errString];
        }
    }
    
    switch (cmd.cmdId) {
        case CwCmdIdGetModeState:
            //output:
            //mode: 1B
            //state: 1B
            NSLog(@"CwCmdIdGetModeState: %ld", cmd.cmdResult);
            if (cmd.cmdResult==0x9000) {
                self.mode = [NSNumber numberWithInteger:data[0]];
                self.state = [NSNumber numberWithInteger:data[1]];
                NSLog(@"mode: %@, state: %@", self.mode, self.state);
                if ([self.delegate respondsToSelector:@selector(didGetModeState)]) {
                    [self.delegate didGetModeState];
                }
            } else {
                NSLog(@"CwCmdIdGetModeState Error %04lX", (long)cmd.cmdResult);
                if (self.delegate && [self.delegate respondsToSelector:@selector(didCwCardCommandError:ErrString:)]) {
                    [self.delegate didCwCardCommandError:cmd.cmdId ErrString:nil];
                }
            }
            break;
        case CwCmdIdGetFwVersion:
            //output:
            //version 16B
            if (cmd.cmdResult==0x9000) {
                self.fwVersion = [[NSString alloc] initWithString: [self NSDataToHex: cmd.cmdOutput]];
            } else {
                NSLog(@"CwCmdIdGetFwVersion Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdGetUid:
            //output:
            //uid 8B
            if (cmd.cmdResult==0x9000) {
                self.uid = [[NSString alloc] initWithString: [self NSDataToHex: cmd.cmdOutput]];
                //if ([self.delegate respondsToSelector:@selector(didGetCwInfo)]) {
                //    [self.delegate didGetCwInfo];
                //}
            } else {
                NSLog(@"CwCmdIdGetUid Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdPinChlng:
            //output:
            //pinChlng 16B
            if (cmd.cmdResult==0x9000) {
                pinChallenge = [NSData dataWithBytes:data length:16];
                if ([self.delegate respondsToSelector:@selector(didPinChlng)]) {
                    [self.delegate didPinChlng];
                }
                
            } else {
                NSLog(@"CwCmdIdPinChlng Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdPinAuth:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didPinAuth)]) {
                    [self.delegate didPinAuth];
                }
            } else {
                NSLog(@"CwCmdIdPinAuth Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdPinChange:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didPinChange)]) {
                    [self.delegate didPinChange];
                }
            } else {
                NSLog(@"CwCmdIdPinChange Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdPinLogout:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didPinLogout)]) {
                    [self.delegate didPinLogout];
                }
            } else {
                NSLog(@"CwCmdIdPinLogout Error %04lX", (long)cmd.cmdResult);
            }
            break;
            
            //Binding Commands
        case CwCmdIdBindRegInit:
            //output:
            //bindRegHandle: 4B
            //bindRegOtp: 6B
            if (cmd.cmdResult==0x9000) {
                regHandle = [NSData dataWithBytes:data length:4];
                
                if ([self.delegate respondsToSelector:@selector(didRegisterHost:)]) {
                    [self.delegate didRegisterHost:[[NSString alloc] initWithBytes:data+4 length:6 encoding:NSUTF8StringEncoding]];
                }
            } else {
                if ([self.delegate respondsToSelector:@selector(didRegisterHostError:)]) {
                    [self.delegate didRegisterHostError:cmd.cmdResult];
                }
                NSLog(@"CwCmdIdBindRegInit Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdBindRegChlng:
            //output:
            //regChlng 16B
            if (cmd.cmdResult==0x9000) {
                regChallenge = [NSData dataWithBytes:data length:16];
                [self cwCmdBindRegFinish: self.hostOtp];
            } else {
                NSLog(@"CwCmdIdBindRegChlng Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdBindRegFinish:
            //output:
            //hostId: 1B
            //confirm: 1B
            if (cmd.cmdResult==0x9000) {
                self.hostId = [NSNumber numberWithInteger:data[0]];
                self.hostConfirmStatus = [NSNumber numberWithInteger:data[1]];
                
                KeychainItemWrapper *keychain =
                [[KeychainItemWrapper alloc] initWithIdentifier:self.cardId accessGroup:nil];
                
                //store OTP in key chain
                [keychain setObject:self.hostOtp forKey:(id)CFBridgingRelease(kSecAttrService)];
                
                if ([self.delegate respondsToSelector:@selector(didConfirmHost)]) {
                    [self.delegate didConfirmHost];
                }
                
            } else {
                self.hostId = [NSNumber numberWithInteger:-1];
                self.hostConfirmStatus = [NSNumber numberWithInteger:-1];
                
                if ([self.delegate respondsToSelector:@selector(didConfirmHostError:)]) {
                    [self.delegate didConfirmHostError:cmd.cmdResult];
                }
                NSLog(@"CwCmdIdBindRegFinish Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdBindRegInfo:
            //output:
            //bindBindState: 1B (00 empty, 01 registered, 02 confirmed)
            //hostDescription: 128B
            if (cmd.cmdResult==0x9000) {
                syncHostFlag[cmd.cmdP1]=YES;
                host = [[CwHost alloc] init];
                host.hostBindStatus = data[0];
                host.hostDescription = [[NSString alloc] initWithBytes:data+1 length:strlen((char *)(data+1)) encoding:NSUTF8StringEncoding];
                
                //add the host to the dictionary with hostId as Key.
                [self.cwHosts setObject: host forKey: [NSString stringWithFormat: @"%ld", (long)cmd.cmdP1]];
                
                if (cmd.cmdP1==2) { //get the last of the host
                    if ([self.delegate respondsToSelector:@selector(didGetHosts)]) {
                        [self.delegate didGetHosts];
                    }
                }
            } else {
                NSLog(@"CwCmdIdBindRegInfo Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
        case CwCmdIdBindRegApprove:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                //change status of the host
                //add the host to the dictionary with hostId as Key.
                host = [self.cwHosts objectForKey: [NSString stringWithFormat: @"%ld", (long)cmd.cmdP1]];
                host.hostBindStatus = CwHostBindStatusConfirmed;
                [self.cwHosts setObject: host forKey: [NSString stringWithFormat: @"%ld", (long)cmd.cmdP1]];
                
                if ([self.delegate respondsToSelector:@selector(didApproveHost:)]) {
                    [self.delegate didApproveHost: cmd.cmdP1];
                }
            } else {
                NSLog(@"CwCmdIdBindRegApprove Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdBindRegRemove:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                //change status of the host
                //add the host to the dictionary with hostId as Key.
                host = [self.cwHosts objectForKey: [NSString stringWithFormat: @"%ld", (long)cmd.cmdP1]];
                host.hostBindStatus = CwHostBindStatusEmpty;
                host.hostDescription = @"";
                [self.cwHosts setObject: host forKey: [NSString stringWithFormat: @"%ld", (long)cmd.cmdP1]];
                
                if ([self.delegate respondsToSelector:@selector(didRemoveHost:)]) {
                    [self.delegate didRemoveHost: cmd.cmdP1];
                }
            } else {
                NSLog(@"CwCmdIdBindRegRemove Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdBindLoginChlng:
            //output:
            //loginChlng: 16B
            if (cmd.cmdResult==0x9000) {
                loginChallenge = [NSData dataWithBytes:data length:16];
                [self cwCmdBindLogin];
            } else {
                NSLog(@"CwCmdIdBindLoginChlng Error %04lX", (long)cmd.cmdResult);
                loginChallenge = nil;
            }
            break;
        case CwCmdIdBindLogin:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                [self loadCwCardFromFile];
                if ([self.delegate respondsToSelector:@selector(didLoginHost)]) {
                    [self.delegate didLoginHost];
                }
            } else {
                NSLog(@"CwCmdIdBindLogin Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdBindLogout:
            //output:
            //none
            if ([self.delegate respondsToSelector:@selector(didLogoutHost)]) {
                [self.delegate didLogoutHost];
            }
            
            if (cmd.cmdResult==0x9000) {
                [self saveCwCardToFile];
                [self init];
            } else {
                NSLog(@"CwCmdIdBindLogout Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdBindFindHostId:
            //output
            //hostId 1B
            //confirm 1B
            
            if (cmd.cmdResult==0x9000) {
                if (data[0]>=0 && data[0]<=2) {
                    self.hostId = [NSNumber numberWithInteger:data[0]];
                    self.hostConfirmStatus = [NSNumber numberWithInteger:data[1]];
                } else {
                    self.hostId = [NSNumber numberWithInteger:-1];
                    self.hostConfirmStatus = [NSNumber numberWithInteger:-1];
                }
                
                //syncCwInfoFlag = YES;
            } else {
                NSLog(@"CwCmdIdBindFindHostId Error %04lX", (long)cmd.cmdResult);
            }
            
            if ([self.delegate respondsToSelector:@selector(didGetCwInfo)]) {
                [self.delegate didGetCwInfo];
            }
            break;
        case CwCmdIdBindBackNoHost:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didEraseCw)]) {
                    [self.delegate didEraseCw];
                }
            } else {
                NSLog(@"CwCmdIdBindBackNoHost Error %04lX", (long)cmd.cmdResult);
                if ([self.delegate respondsToSelector:@selector(didEraseCwError:)]) {
                    [self.delegate didEraseCwError:cmd.cmdResult];
                }
            }
            
            break;
            
            //Perso Commands
        case CwCmdIdPersoSetData:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                syncSecurityPolicyFlag = YES;
                [self cwCmdPersoConfirm];
            } else {
                NSLog(@"CwCmdIdPersoSetData Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
        case CwCmdIdPersoConfirm:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                syncSecurityPolicyFlag = YES;
                if ([self.delegate respondsToSelector:@selector(didPersoSecurityPolicy)]) {
                    [self.delegate didPersoSecurityPolicy];
                }
            } else {
                NSLog(@"CwCmdIdPersoConfirm Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdPersoBackPerso:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didEraseWallet)]) {
                    [self.delegate didEraseWallet];
                }
            } else {
                NSLog(@"CwCmdIdPersoBackPerso Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
            
            //CW Setting Commands
        case CwCmdIdSetCurrRate:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                syncCurrRateFlag = YES;
                if ([self.delegate respondsToSelector:@selector(didSetCwCurrRate)]) {
                    [self.delegate didSetCwCurrRate];
                }
            } else{
                NSLog(@"CwCmdIdSetCurrRate Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdGetCurrRate:
            //output:
            //currRate 5B
            if (cmd.cmdResult==0x9000) {
                syncCurrRateFlag = YES;
                Byte curr[4];
                long rate;
                //Big-endian to little-endian
                for (int i=0; i<4; i++)
                    curr[3-i]=data[i+1];
                
                memcpy(&rate, curr, sizeof(curr));
                
                self.currRate = [[NSDecimalNumber alloc] initWithUnsignedLong:rate];
                
                if ([self.delegate respondsToSelector:@selector(didGetCwCurrRate)]) {
                    [self.delegate didGetCwCurrRate];
                }
                
            } else{
                NSLog(@"CwCmdIdSetCurrRate Error %04lX", (long)cmd.cmdResult);
            }
            break;
            
        case CwCmdIdGetCardId:
            //output:
            //cardId: 8B
            if (cmd.cmdResult==0x9000) {
                syncCardIdFlag = YES;
                self.cardId = [[NSString alloc] initWithBytes:data length:8 encoding:NSUTF8StringEncoding];
                if ([self.delegate respondsToSelector:@selector(didGetCwCardId)]) {
                    [self.delegate didGetCwCardId];
                }
            } else {
                NSLog(@"CwCmdIdGetCardId Error %04lX", (long)cmd.cmdResult);
            }
            break;
            
        case CwCmdIdGetCardName:
            //output:
            //cardName 32B
            if (cmd.cmdResult==0x9000) {
                syncCardNameFlag = YES;
                self.cardName = [[NSString alloc] initWithBytes:data length:strlen((char *)(data)) encoding:NSUTF8StringEncoding];
                
                if ([self.delegate respondsToSelector:@selector(didGetCwCardName)]) {
                    [self.delegate didGetCwCardName];
                }
            } else{
                NSLog(@"CwCmdIdGetCardName Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdSetCardName:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                syncCardNameFlag = YES;
                
                if ([self.delegate respondsToSelector:@selector(didSetCwCardName)]) {
                    [self.delegate didSetCwCardName];
                }
            } else{
                NSLog(@"CwCmdIdSetCardName Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdGetPerso:
            //output:
            //securePolicy: 4B
            if (cmd.cmdResult==0x9000) {
                syncSecurityPolicyFlag = YES;
                
                if (data[0] & CwSecurityPolicyMaskOtp)
                    self.securityPolicy_OtpEnable=[NSNumber numberWithBool:YES];
                else
                    self.securityPolicy_OtpEnable=[NSNumber numberWithBool:NO];
                
                if (data[0] & CwSecurityPolicyMaskBtn)
                    self.securityPolicy_BtnEnable=[NSNumber numberWithBool:YES];
                else
                    self.securityPolicy_BtnEnable=[NSNumber numberWithBool:NO];
                
                if (data[0] & CwSecurityPolicyMaskWatchDog)
                    self.securityPolicy_WatchDogEnable=[NSNumber numberWithBool:YES];
                else
                    self.securityPolicy_WatchDogEnable=[NSNumber numberWithBool:NO];
                
                if (data[0] & CwSecurityPolicyMaskAddress)
                    self.securityPolicy_DisplayAddressEnable=[NSNumber numberWithBool:YES];
                else
                    self.securityPolicy_DisplayAddressEnable=[NSNumber numberWithBool:NO];
                
                if ([self.delegate respondsToSelector:@selector(didGetSecurityPolicy)]) {
                    [self.delegate didGetSecurityPolicy];
                }
            } else {
                NSLog(@"CwCmdIdGetPerso Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdSetPerso:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                syncSecurityPolicyFlag = YES;
                
                if ([self.delegate respondsToSelector:@selector(didSetSecurityPolicy)]) {
                    [self.delegate didSetSecurityPolicy];
                }
            } else {
                NSLog(@"CwCmdIdSetPerso Error %04lX", (long)cmd.cmdResult);
                [self cwCmdGetPerso];
            }
            
            break;
            
            
            //HD Wallet Commands
        case CwCmdIdHdwInitWallet:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                syncHdwStatusFlag = YES;
                self.hdwStatus = [NSNumber numberWithInteger:CwHdwStatusActive];
                
                if ([self.delegate respondsToSelector:@selector(didInitHdwBySeed)]) {
                    [self.delegate didInitHdwBySeed];
                }
            } else{
                NSLog(@"CwCmdIdHdwInitWallet Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
        case CwCmdIdHdwInitWalletGen:
            //output:
            //seedString: 12/18/24B, BCD format
            //activeCode: 4B
            //mac: (seedString || activeCode)
            if (cmd.cmdResult==0x9000) {
                syncHdwStatusFlag = YES;
                self.hdwStatus = [NSNumber numberWithInteger:CwHdwStatusWaitConfirm];
                
                const unsigned char *tmp = [cmd.cmdInput bytes];
                
                int seedLen = (int)(tmp[32]);
                
                activeCode = [[NSData alloc] initWithBytes:(data+seedLen) length:4];
                
                //TODO: verify MAC
                
                if ([self.delegate respondsToSelector:@selector(didInitHdwByCard)]) {
                    [self.delegate didInitHdwByCard];
                }
            } else{
                NSLog(@"CwCmdIdHdwInitWalletGen Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
        case CwCmdIdHdwInitWalletGenConfirm:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                syncHdwStatusFlag = YES;
                self.hdwStatus = [NSNumber numberWithInteger:CwHdwStatusActive];
                
                if ([self.delegate respondsToSelector:@selector(didInitHdwConfirm)]) {
                    [self.delegate didInitHdwConfirm];
                }
            } else{
                NSLog(@"CwCmdIdHdwInitWalletGenConfirm Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
        case CwCmdIdHdwQueryWalletInfo:
            //output:
            //infoId 1B (=00/01/02)
            //hwdInfo:
            //  hwdStatus 1B
            //  hwdName 32B
            //  hwdAccountPointer 4B
            
            if (cmd.cmdResult==0x9000) {
                
                switch (cmd.cmdP1) {
                    case CwHdwInfoAll:
                        self.hdwStatus = [NSNumber numberWithInteger:data[0]];
                        self.hdwName = [[NSString alloc] initWithBytes:data+1 length:32 encoding:NSUTF8StringEncoding];
                        
                        syncHdwStatusFlag = YES;
                        syncHdwNameFlag = YES;
                        
                        if ([self.delegate respondsToSelector:@selector(didGetCwHdwStatus)]) {
                            [self.delegate didGetCwHdwStatus];
                        }
                        
                        if (self.hdwStatus.integerValue != CwHdwStatusActive) {
                            return;
                        }
                        
                        if ([self.delegate respondsToSelector:@selector(didGetCwHdwName)]) {
                            [self.delegate didGetCwHdwName];
                        }
                        
                        NSUInteger accountPointer;
                        [[NSData dataWithBytes:data+33 length:4] getBytes:&accountPointer length:4];
                        self.hdwAcccountPointer = [NSNumber numberWithInteger:(int32_t)accountPointer];
                        
                        syncHdwAccPtrFlag = YES;
                        for (int i=0; i<[self.hdwAcccountPointer integerValue]; i++) {
                            //get account from dictionary
                            CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)i]];
                            
                            if (account==nil) {
                                account = [[CwAccount alloc] init];
                                account.accId = i;
                                
                                //add the host to the dictionary with accountId as Key.
                                [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)i]];
                            }
                        }
                        
                        if ([self.delegate respondsToSelector:@selector(didGetCwHdwAccountPointer)]) {
                            [self.delegate didGetCwHdwAccountPointer];
                        }
                        
                        break;
                    case CwHdwInfoStatus:
                        self.hdwStatus = [NSNumber numberWithInteger:data[0]];
                        syncHdwStatusFlag = YES;
                        
                        if ([self.delegate respondsToSelector:@selector(didGetCwHdwStatus)]) {
                            [self.delegate didGetCwHdwStatus];
                        }
                        
                        if ([self.hdwStatus integerValue] == CwHdwStatusActive) {
                            //get name
                            if (syncHdwNameFlag == NO) {
                                [self cwCmdHdwQueryWalletInfo:CwHdwInfoName];
                            } else {
                                //call delegate
                                if ([self.delegate respondsToSelector:@selector(didGetCwHdwName)]) {
                                    [self.delegate didGetCwHdwName];
                                }
                                if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
                                    [self.delegate didCwCardCommand];
                                }
                            }
                            
                            //get acc pointer
                            if (syncHdwAccPtrFlag == NO) {
                                [self cwCmdHdwQueryWalletInfo:CwHdwInfoAccountPointer];
                            } else {
                                //call delegate
                                if ([self.delegate respondsToSelector:@selector(didGetCwHdwAccountPointer)]) {
                                    [self.delegate didGetCwHdwAccountPointer];
                                }
                                if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
                                    [self.delegate didCwCardCommand];
                                }
                            }
                        }
                        break;
                    case CwHdwInfoName:
                        self.hdwName = [[NSString alloc] initWithBytes:data length:strlen((char *)(data)) encoding:NSUTF8StringEncoding];
                        syncHdwNameFlag = YES;
                        if ([self.delegate respondsToSelector:@selector(didGetCwHdwName)]) {
                            [self.delegate didGetCwHdwName];
                        }
                        break;
                    case CwHdwInfoAccountPointer:
                        self.hdwAcccountPointer = [NSNumber numberWithInteger:*(int32_t *)data];
                        syncHdwAccPtrFlag = YES;
                        
                        for (int i=0; i<[self.hdwAcccountPointer integerValue]; i++) {
                            //get account from dictionary
                            CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)i]];
                            
                            if (account==nil) {
                                account = [[CwAccount alloc] init];
                                account.accId = i;
                                
                                //add the host to the dictionary with accountId as Key.
                                [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)i]];
                            }
                        }
                        
                        if ([self.delegate respondsToSelector:@selector(didGetCwHdwAccountPointer)]) {
                            [self.delegate didGetCwHdwAccountPointer];
                        }
                        break;
                }
            } else{
                NSLog(@"CwCmdIdHdwQueryWalletInfo Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
        case CwCmdIdHdwSetWalletInfo:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                switch (cmd.cmdP1) {
                    case CwHdwInfoName:
                        syncHdwNameFlag = YES;
                        if ([self.delegate respondsToSelector:@selector(didSetCwHdwName)]) {
                            [self.delegate didSetCwHdwName];
                        }
                        break;
                    case CwHdwInfoAccountPointer:
                        syncHdwAccPtrFlag = YES;
                        if ([self.delegate respondsToSelector:@selector(didSetCwHdwAccointPointer)]) {
                            [self.delegate didSetCwHdwAccointPointer];
                        }
                        break;
                }
            } else{
                NSLog(@"CwCmdIdHdwSetWalletInfo Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
        case CwCmdIdHdwCreateAccount:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                //create Account object
                CwAccount *account = [[CwAccount alloc] init];
                
                account.accId =  *(int32_t *)[cmd.cmdInput bytes];
                NSData *accInfo = [[NSData alloc] initWithBytes:[cmd.cmdInput bytes]+4 length:cmd.cmdInput.length-4];
                account.accName = [[NSString alloc] initWithBytes:[accInfo bytes] length:accInfo.length encoding:NSUTF8StringEncoding];
                
                [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)account.accId]];
                
                self.currentAccountId = account.accId;
                
                self.hdwAcccountPointer = [NSNumber numberWithInteger:account.accId+1];
                
                syncHdwAccPtrFlag = YES;
                syncAccInfoFlag[account.accId] = YES;
                
                if ([self.delegate respondsToSelector:@selector(didNewAccount:)]) {
                    [self.delegate didNewAccount:account.accId];
                }
                
            } else{
                NSLog(@"CwCmdIdHdwCreateAccount Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
        case CwCmdIdHdwQueryAccountInfo:
            //output:
            //accountInfo
            //  accountName 32B
            //  balance 8B
            //  extKeyPointer   4B
            //  intKeyPointer   4B
            
            if (cmd.cmdResult==0x9000) {
                //account Id
                //little-endian 4 bytes to NSInteger
                NSInteger accId = *(int32_t *)[cmd.cmdInput bytes];
                
                //get Account from directory
                CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", accId]];
                
                switch (cmd.cmdP1) {
                    case CwHdwAccountInfoAll:
                        // Account name (32 bytes)
                        // Balance (8 bytes, big-endian)
                        // External key pointer (4 bytes, little-endian)
                        // Internal key pointer (4 bytes, little-endian)
                        // Exchange site blocked balance (8 bytes, big-endian)
                        
                        account.accName = [[NSString alloc] initWithBytes:data length:32 encoding:NSUTF8StringEncoding];
                        account.balance = CFSwapInt64(*(int64_t *)[[NSData dataWithBytes:data+32 length:8] bytes]);
                        account.extKeyPointer = *(int32_t *)[[NSData dataWithBytes:data+40 length:4] bytes];
                        account.intKeyPointer = *(int32_t *)[[NSData dataWithBytes:data+44 length:4] bytes];
                        account.blockAmount = CFSwapInt64(*(int64_t *)[[NSData dataWithBytes:data+48 length:8] bytes]);
                        
                        for (NSInteger i=account.extKeys.count; i<account.extKeyPointer; i++) {
                            CwAddress *add = [[CwAddress alloc]init];
                            add.accountId = account.accId;
                            add.address = nil;
                            add.keyChainId = CwAddressKeyChainExternal; //external
                            add.keyId = i;
                            
                            [account.extKeys addObject:add];
                        }
                        
                        for (NSInteger i=account.intKeys.count; i<account.intKeyPointer; i++) {
                            CwAddress *add = [[CwAddress alloc]init];
                            add.accountId = account.accId;
                            add.address = nil;
                            add.keyChainId = CwAddressKeyChainInternal; //internal
                            add.keyId = i;
                            
                            [account.intKeys addObject:add];
                        }
                        
                        syncAccInfoFlag[account.accId] = YES;
                        
                        break;
                    case CwHdwAccountInfoName:
                        //bytes to NSString
                        account.accName = [[NSString alloc] initWithBytes:data length:strlen((char *)(data)) encoding:NSUTF8StringEncoding];
                        break;
                    case CwHdwAccountInfoBalance:
                        //big-endian 8 bytes to NSInteger
                        account.balance = CFSwapInt64(*(int64_t *)data);
                        break;
                    case CwHdwAccountInfoBlockAmount:
                        //big-endian 8 bytes to NSInteger
                        account.blockAmount = CFSwapInt64(*(int64_t *)data);
                        break;
                    case CwHdwAccountInfoExtKeyPtr:
                        //little-endian 4 bytes to NSInteger
                        account.extKeyPointer = *(int32_t *)data;
                        for (NSInteger i=account.extKeys.count; i<account.extKeyPointer; i++) {
                            CwAddress *add = [[CwAddress alloc]init];
                            add.accountId = account.accId;
                            add.address = nil;
                            add.keyChainId = CwAddressKeyChainExternal; //external
                            add.keyId = i;
                            
                            [account.extKeys addObject:add];
                        }
                        break;
                    case CwHdwAccountInfoIntKeyPtr:
                        //little-endian 4 bytes to NSInteger
                        account.intKeyPointer = *(int32_t *)data;
                        for (NSInteger i=account.intKeys.count; i<account.intKeyPointer; i++) {
                            CwAddress *add = [[CwAddress alloc]init];
                            add.accountId = account.accId;
                            add.address = nil;
                            add.keyChainId = CwAddressKeyChainInternal; //internal
                            add.keyId = i;
                            
                            [account.intKeys addObject:add];
                        }
                        break;
                }
                
                [self.cwAccounts setObject:account forKey:[NSString stringWithFormat: @"%ld", accId]];
                
                //if both pointers are synced, get the addresses/publickey
                /*if (syncAccExtPtrFlag[account.accId] && syncAccIntPtrFlag[account.accId]) {
                 [self getAccountAddresses: account.accId];
                 }*/
                //self.currentAccountId = account.accId;
                
                account.infoSynced = syncAccInfoFlag[account.accId] && account.externalKeychain != nil && account.internalKeychain != nil;
                //check sync status
                if (account.infoSynced) {
                    //call delegate
                    if ([self.delegate respondsToSelector:@selector(didGetAccountInfo:)]) {
                        [self.delegate didGetAccountInfo:account.accId];
                    }
                }
            } else{
                NSLog(@"CwCmdIdHdwQueryAccountInfo Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdHdwSetAccountInfo:
            //output:
            //none
            
            if (cmd.cmdResult==0x9000) {
                
                //account Id
                //little-endian 4 bytes to NSInteger
                NSInteger accId = *(int32_t *)[cmd.cmdInput bytes];
                
                NSData *accInfo = [[NSData alloc] initWithBytes:[cmd.cmdInput bytes]+4 length:cmd.cmdInput.length-4];
                NSInteger pointer = -1;
                if (cmd.cmdP1 == CwHdwAccountInfoExtKeyPtr || cmd.cmdP1 == CwHdwAccountInfoIntKeyPtr) {
                    pointer = *(int32_t *)[accInfo bytes];
                }
                
                //get Account from directory
                CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                
                switch (cmd.cmdP1) {
                    case CwHdwAccountInfoName:
                        //bytes to NSString
                        account.accName = [[NSString alloc] initWithBytes:[accInfo bytes] length:strlen((char *)[accInfo bytes]) encoding:NSUTF8StringEncoding];
                        [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                        
                        if ([self.delegate respondsToSelector:@selector(didSetAccountName)]) {
                            [self.delegate didSetAccountName];
                            
                        }
                        break;
                    case CwHdwAccountInfoBalance:
                        //8B Big-endian to NSInteger
                        account.balance = CFSwapInt64(*(int64_t *)[accInfo bytes]);
                        [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                        
                        if ([self.delegate respondsToSelector:@selector(didSetAccountBalance:)]) {
                            [self.delegate didSetAccountBalance:accId];
                            
                        }
                        break;
                    case CwHdwAccountInfoExtKeyPtr:
                        //4B Little-endian to NSInteger
                        if (pointer >= account.extKeyPointer) {
                            account.extKeyPointer = pointer;
                            [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                        }
                        
                        if ([self.delegate respondsToSelector:@selector(didSetAccountExtKeyPtr:keyPtr:)]) {
                            [self.delegate didSetAccountExtKeyPtr:accId keyPtr:pointer];
                        }
                        break;
                    case CwHdwAccountInfoIntKeyPtr:
                        //4B Little-endian to NSInteger
                        if (pointer >= account.intKeyPointer) {
                            account.intKeyPointer = pointer;
                            [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                        }
                        
                        if ([self.delegate respondsToSelector:@selector(didSetAccountIntKeyPtr:keyPtr:)]) {
                            [self.delegate didSetAccountIntKeyPtr:accId keyPtr:pointer];
                            
                        }
                        break;
                }
                
            } else{
                NSLog(@"CwCmdIdHdwSetAccountInfo Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
        case CwCmdIdHdwGetNextAddress:
            //input
            //P1: keyChainId 1B
            //accountId 4B
            
            //output
            //keyId 4B
            //address 25B
            //mac 32B (of keyId||address)
            if (cmd.cmdResult==0x9000) {
                
                //TODO: verify MAC
                
                CwAddress *addr = [[CwAddress alloc] init];
                addr.accountId = *(int32_t *)[cmd.cmdInput bytes];
                addr.keyChainId = cmd.cmdP1;
                //keyId 4B Liggle-endian to NSInteger
                addr.keyId = *(int32_t *)data;
                
                //adress 25B Binary to Base58 NSString
                //base58Encode(data+4, 25, addrBytes, 34);
                addr.address=[CwBase58 base58WithData:[[NSData alloc] initWithBytes:data+4 length:25]];
                
                /*
                 int64_t balance;
                 [btcNet getBalanceByAddr:addr.address balance: &balance];
                 NSLog(@"Get address %@ balance %lld from network", addr.address, balance);
                 addr.balance = balance;
                 
                 NSMutableArray *htx;
                 
                 [btcNet getHistoryTxsByAddr:addr.address txs: &htx];
                 addr.historyTrx = htx;
                 */
                
                //update account info
                //get Account from directory
                CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)addr.accountId]];
                if (addr.keyChainId == CwAddressKeyChainExternal) {
                    account.extKeyPointer = addr.keyId+1;
                    [account.extKeys addObject: addr];
                } else if (addr.keyChainId == CwAddressKeyChainInternal) {
                    account.intKeyPointer = addr.keyId+1;
                    [account.intKeys addObject: addr];
                }
                
                [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)addr.accountId]];
                
                //get publickey of the address
                [self getAddressPublickey:addr.accountId KeyChainId:addr.keyChainId KeyId:addr.keyId];
                
                if ([self.delegate respondsToSelector:@selector(didGenAddress:)]) {
                    [self.delegate didGenAddress:addr];
                }
                
                /*if ([self.delegate respondsToSelector:@selector(didGetAccountInfo:)]) {
                 [self.delegate didGetAccountInfo:account.accId];
                 }*/
            } else{
                NSLog(@"CwCmdIdHdwGetNextAddress Error %04lX", (long)cmd.cmdResult);
                if ([self.delegate respondsToSelector:@selector(didGenAddressError)]) {
                    [self.delegate didGenAddressError];
                }
            }
            
            break;
        
        case CwCmdIdExTrxSignPrepare:
        case CwCmdIdHdwPrepTrxSign:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                ((CwTxin *)(currUnsignedTx.inputs[cmd.cmdP1])).sendToCard = YES;
                
                NSInteger status = trxStatus;
                trxStatus = TrxStatusBegin;
                for (int i=0; i<currUnsignedTx.inputs.count; i++) {
                    if (((CwTxin *) (currUnsignedTx.inputs[i])).sendToCard == NO) {
                        //back to previous status
                        trxStatus = status;
                        break;
                    }
                }
                if (trxStatus == TrxStatusBegin) {
                    [self cwCmdTrxBegin: currTrxAmount Address:currTrxRecvAddress];
                }
            } else {
                NSLog(@"CwCmdIdHdwPrepTrxSign Error %04lX", (long)cmd.cmdResult);
                if ([self.delegate respondsToSelector:@selector(didSignTransactionError:)]) {
                    [self.delegate didSignTransactionError: @"Can't sign transaction by card."];
                }
            }
            
            break;
            
        case CwCmdIdHdwQueryAccountKeyInfo:
            //input
            //P1: keyInfoId 1B (00 address25B, 01 publickey 64B)
            //P2: keyChainId 1B
            //accountId 4B
            //keyId 4B
            
            //output
            //keyInfo
            //  address 25B
            //  publicKey 64B
            //mac 32B (of KeyInfo)
            
            if (cmd.cmdResult==0x9000) {
                //TODO: verify MAC
                
                //get Account from directory
                NSInteger accId = *(int32_t *)[cmd.cmdInput bytes];;
                NSInteger keyId = *(int32_t *)([cmd.cmdInput bytes]+4);
                CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                CwAddress *addr;
                CwKeychain *keychain = [CwKeychain new];
                
                if (cmd.cmdP2 == CwAddressKeyChainExternal) {
                    if (keyId < account.extKeys.count) {
                        addr = account.extKeys[keyId];
                    }
                    if (account.externalKeychain != nil) {
                        keychain = account.externalKeychain;
                    }
                } else if (cmd.cmdP2 == CwAddressKeyChainInternal) {
                    if (keyId < account.intKeys.count) {
                        addr = account.intKeys[keyId];
                    }
                    
                    if (account.internalKeychain != nil) {
                        keychain = account.internalKeychain;
                    }
                }
                
                if (addr == nil) {
                    addr = [[CwAddress alloc] init];
                }
                
                
                addr.accountId = accId;
                addr.keyId = keyId;
                addr.keyChainId = cmd.cmdP2;
                
                switch (cmd.cmdP1) {
                    case CwAddressInfoAddress:
                        //Address
                        //25B Binary to NSString
                        NSLog(@"%@", [cmd.cmdOutput description]);
                        
                        //adress 25B Binary to Base58 NSString
                        //base58Encode(data, 25, addrBytes, 34);
                        addr.address=[CwBase58 base58WithData:[[NSData alloc] initWithBytes:data length:25]];

                        break;
                        
                    case CwAddressInfoPublicKey:
                        //Address
                        //64B Binary
                        addr.publicKey = [NSData dataWithBytes:data length:64];
                        
                        break;
                    
                    case CwAddressInfoKeyChainPublicKey:
                        //Pulick Key of keychain
                        //96B Binary: publicKey(64B) + chainCode(32B)
                        
                        keychain = [[CwKeychain alloc] initWithPublicKey:[NSString dataToHexstring:[NSData dataWithBytes:data length:64]] ChainCode:[NSString dataToHexstring:[NSData dataWithBytes:data+64 length:32]] KeychainId:addr.keyChainId];
                        
                        break;
                }
                
                if (addr.keyChainId == CwAddressKeyChainExternal) {
                    if (cmd.cmdP1 != CwAddressInfoKeyChainPublicKey) {
                        account.extKeys[keyId] = addr;
                    }
                    account.externalKeychain = keychain;
                } else if (addr.keyChainId == CwAddressKeyChainInternal) {
                    if (cmd.cmdP1 != CwAddressInfoKeyChainPublicKey) {
                        account.intKeys[keyId] = addr;
                    }
                    account.internalKeychain = keychain;
                }
                
                [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)addr.accountId]];
                
                if (cmd.cmdP1 == CwAddressInfoAddress) {
                    if ([self.delegate respondsToSelector:@selector(didGetAddressInfo)]) {
                        [self.delegate didGetAddressInfo];
                    }
                    
                    if ([account isAllAddressSynced]) {
                        if ([self.delegate respondsToSelector:@selector(didGetAccountAddresses:)]) {
                            [self.delegate didGetAccountAddresses: account.accId];
                        }
                    }
                } else if (cmd.cmdP1 == CwAddressInfoKeyChainPublicKey) {
                    account.infoSynced = syncAccInfoFlag[account.accId] && account.externalKeychain != nil && account.internalKeychain != nil;
                    if (account.infoSynced) {
                        //call delegate
                        if ([self.delegate respondsToSelector:@selector(didGetAccountInfo:)]) {
                            [self.delegate didGetAccountInfo:account.accId];
                        }
                    }
                } else if (cmd.cmdP1 == CwAddressInfoPublicKey) {
                    if ([self.delegate respondsToSelector:@selector(didGetAddressPublicKey:)]) {
                        [self.delegate didGetAddressPublicKey:addr];
                    }
                }
                
            } else {
                NSLog(@"CwCmdIdHdwQueryAccountKeyInfo Error %04lX", (long)cmd.cmdResult);
                if (cmd.cmdP1 == CwAddressInfoKeyChainPublicKey && (cmd.cmdResult == ERR_HDW_ACCINFOID || cmd.cmdResult == ERR_CMD_NOT_SUPPORT)) {
                    NSInteger accId = *(int32_t *)[cmd.cmdInput bytes];;
                    CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                    if (account != nil) {
                        if (cmd.cmdP2 == CwAddressKeyChainExternal) {
                            account.externalKeychain = [CwKeychain new];
                        } else if (cmd.cmdP2 == CwAddressKeyChainInternal) {
                            account.internalKeychain = [CwKeychain new];
                        }
                        
                        [self.cwAccounts setObject:account forKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                        
                        account.infoSynced = syncAccInfoFlag[account.accId] && account.externalKeychain != nil && account.internalKeychain != nil;
                        if (account.infoSynced) {
                            //call delegate
                            if ([self.delegate respondsToSelector:@selector(didGetAccountInfo:)]) {
                                [self.delegate didGetAccountInfo:account.accId];
                            }
                        }
                    }
                }
            }
            
            break;
            
            //Transaction Commands
            
        case CwCmdIdTrxStatus:
            //output
            //status 1B (00 idle, 01 preparing, 02 begined, 03 opt veriried, 04 in process
            break;
        case CwCmdIdTrxGetAddr:
            
            if (cmd.cmdResult==0x9000) {
                NSString* newStr = [[NSString alloc] initWithData:cmd.cmdOutput encoding:NSUTF8StringEncoding];
                NSLog(@"CwCmdIdTrxGetAddr %@", newStr);
            } else {
                NSLog(@"CwCmdIdTrxGetAddr Error %04lX", (long)cmd.cmdResult);
            }
            break;
            
        case CwCmdIdTrxBegin:
            //output
            //otp 6B
            
            //NSString *otp=@"123456";
            
            if (cmd.cmdResult==0x9000) {
                //[self cwCmdTrxGetAddr];
                if ([self.delegate respondsToSelector:@selector(didPrepareTransaction:)]) {
                    [self.delegate didPrepareTransaction:[[NSString alloc] initWithBytes:data length:6 encoding:NSUTF8StringEncoding]];
                }
                
                if (self.securityPolicy_OtpEnable.boolValue == YES) {
                    trxStatus=TrxStatusWaitOtp;
                    currentCmd.busy=NO;
                    [self BLE_ReadStatus];
                } else if (self.securityPolicy_BtnEnable.boolValue == YES) {
                    trxStatus = TrxStatusWaitBtn;
                    currentCmd.busy=NO;
                    [self BLE_ReadStatus];
                } else {
                    trxStatus = TrxStatusGetBtn;
                    if ([self.delegate respondsToSelector:@selector(didGetButton)]) {
                        [self.delegate didGetButton];
                    }
                }
                NSLog(@"trxStatus = %ld", (long)trxStatus);
                
            } else{
                NSLog(@"CwCmdIdTrxBegin Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdTrxVerifyOtp:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                //sign transactions
                //for (int i=0; i<toBeSignedTrxs.count; i++) {
                //call delegate
                if ([self.delegate respondsToSelector:@selector(didVerifyOtp)]) {
                    [self.delegate didVerifyOtp];
                }
                
                //check security policy
                if (self.securityPolicy_BtnEnable.boolValue) {
                    trxStatus = TrxStatusWaitBtn;
                    currentCmd.busy=NO;
                    [self BLE_ReadStatus];
                } else {
                    trxStatus = TrxStatusGetBtn;
                    //call delegate
                    if ([self.delegate respondsToSelector:@selector(didGetButton)]) {
                        [self.delegate didGetButton];
                    }
                }
            } else {
                //call delegate
                if ([self.delegate respondsToSelector:@selector(didVerifyOtpError:)]) {
                    [self.delegate didVerifyOtpError:cmd.cmdResult];
                }
                NSLog(@"CwCmdIdTrxVerifyOtp Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
        case CwCmdIdTrxSign:
            //ouput
            //signature 64B
            //mac 32B (of signature)
            
            if (cmd.cmdResult==0x9000) {
                //TODO: verify MAC
                
                //Store Signature to the array
                NSData* signOfTx = [NSData dataWithBytes:data length:64];
                
                //check if there is a high S
                // S must between 0x1 and 0x7FFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 5D576E73 57A4501D DFE92F46 681B20A0 (inclusive).
                // If S is too high, simply replace it by S' = 0xFFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFE BAAEDCE6 AF48A03B BFD25E8C D0364141 - S.
                
                signOfTx = [self signatureToLowS: signOfTx];
                
                ((CwTxin *) (currUnsignedTx.inputs[cmd.cmdP1])).signature = signOfTx;
                
                NSInteger status = trxStatus;
                trxStatus = TrxStatusSigned;
                //check if there are signatures need to be signed
                for (int i=0; i<currUnsignedTx.inputs.count; i++) {
                    if (((CwTxin *) (currUnsignedTx.inputs[i])).signature==nil) {
                        //back to previous status
                        trxStatus = status;
                        break;
                    }
                }
                
                if (trxStatus == TrxStatusSigned) {
                    //All transactions are signed
                    CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)self.currentAccountId]];
                    
                    //prepare sign transaction
                    NSMutableArray *sigs = [[NSMutableArray alloc] init];
                    for (int i=0; i<currUnsignedTx.inputs.count; i++) {
                        CwTxin *txin = currUnsignedTx.inputs[i];
                        NSLog(@"signature: %@, pubKey: %@", txin.signature, txin.pubKey);
                        NSData *scriptSig = [NSData dataWithBytes:"" length:0];
                        [account genScriptSig:txin.signature pubKey:txin.pubKey scriptSig:&scriptSig];
                        NSLog(@"txin: %d, scriptPub: %@", i, scriptSig);
                        ((CwTxin *)(currUnsignedTx.inputs[i])).scriptPub = scriptSig;
                        [sigs addObject: scriptSig];
                    }
                    
                    [account genRawTxData:currUnsignedTx scriptSigs:sigs];
                    
                    //publish to Network
                    NSData *parseResult;
                    
                    CwBtcNetWork *btcNet = [CwBtcNetWork sharedManager];
                    [btcNet decode:currUnsignedTx result:&parseResult];
                    NSLog(@"%@",parseResult);
                    
                    PublishErr err =  [btcNet publish:currUnsignedTx result:&parseResult];
                    NSLog(@"%@",parseResult);
                    
                    NSString *txId = @"";
                    if (err == PUBLISH_NETWORK) {
                        //call error delegate
                        if ([self.delegate respondsToSelector:@selector(didSignTransactionError:)]) {
                            [self.delegate didSignTransactionError: @"PushX form Post not Work"];
                        }
                    } else {
                        if ([self.delegate respondsToSelector:@selector(didSignTransaction:)]) {
                            [self.delegate didSignTransaction:txId];
                        }
                        [btcNet getBalance:[NSNumber numberWithInteger:account.accId]];
                    }
/*
                    //{"status":"success","data":"5c6f2ab6a011a6c45fcec6f342d655cf26fd64ecba76c6ddc3e84dd8434bdfa2","code":200,"message":""}
                    
                    //check parseResult
                    NSError *_err = nil;
                    NSDictionary *JSON =[NSJSONSerialization JSONObjectWithData:parseResult options:0 error:&_err];
                    
                    if(!(!_err && [@"success" isEqualToString:JSON[@"status"]]))
                    {
                        //call error delegate
                        if ([self.delegate respondsToSelector:@selector(didSignTransactionError:)]) {
                            [self.delegate didSignTransactionError: JSON[@"message"]];
                        }
                    }
                    else
                    {
                        NSString *txId = [JSON objectForKey:@"data"];
                        //call success delegate
                        if ([self.delegate respondsToSelector:@selector(didSignTransaction:)]) {
                            [self.delegate didSignTransaction:txId];
                        }
                        
                        [btcNet getBalance:[NSNumber numberWithInteger:account.accId]];
                        [btcNet updateHistoryTxs:txId];
                    }
 */
                    
//                    if([JSON objectForKey:@"error"] != nil)
//                    {
//                        //call error delegate
//                        if ([self.delegate respondsToSelector:@selector(didSignTransactionError:)]) {
//                            [self.delegate didSignTransactionError: [JSON objectForKey:@"error"]];
//                        }
//                    }
//                    else
//                    {
//                        //call success delegate
//                        if ([self.delegate respondsToSelector:@selector(didSignTransaction)]) {
//                            [self.delegate didSignTransaction];
//                        }
//                    }
                    
                    [self cwCmdTrxFinish];
                }

            } else {
                NSLog(@"CwCmdIdTrxSign Error %04lX", (long)cmd.cmdResult);
                if ([self.delegate respondsToSelector:@selector(didSignTransactionError:)]) {
                    [self.delegate didSignTransactionError:[NSString stringWithFormat:@"Card sign error(%04lX)", (long)cmd.cmdResult]];
                }
            }
            
            break;
            
        case CwCmdIdTrxFinish:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didFinishTransaction)]) {
                    [self.delegate didFinishTransaction];
                }
                NSLog(@"trxStatus = %ld", (long)trxStatus);
            } else {
                NSLog(@"CwCmdIdTrxFinish Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
            
            //Exchange Site Commands
            
        case CwCmdIdExRegStatus:
            //output
            //regStat 1B 00 not reg, 01 init, 02 registered
            if (cmd.cmdResult==0x9000) {
                if (data!=nil) {
                    NSLog(@"regStatus = %ld", (long)data[0]);
                    if ([self.delegate respondsToSelector:@selector(didExGetRegStatus:)]) {
                        [self.delegate didExGetRegStatus:(NSInteger)data[0]];
                    }
                }
            } else {
                NSLog(@"CwCmdIdExRegStatus Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
            
        case CwCmdIdExGetOtp:
            //output
            //OTP 6B
            if (cmd.cmdResult==0x9000) {
                if (data != NULL) {
                    exOtp = [[NSString alloc] initWithBytes:data length:strlen((char *)(data)) encoding:NSUTF8StringEncoding];
                }
                
                if ([self.delegate respondsToSelector:@selector(didExGetOtp:type:)]) {
                    [self.delegate didExGetOtp:exOtp type:cmd.cmdP1];
                }
            } else {
                NSLog(@"CwCmdIdExGetOtp Error %04lX", (long)cmd.cmdResult);
                if ([self.delegate respondsToSelector:@selector(didExGetOtpError:type:)]) {
                    [self.delegate didExGetOtpError:cmd.cmdResult type:cmd.cmdP1];
                }
            }
            break;
            
        case CwCmdIdExSessionInit:
            //output:
            //seResp 16B
            //seChlng 16B
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didExSessionInit:SeChlng:)]) {
                    [self.delegate didExSessionInit:[NSData dataWithBytes:data length:16] SeChlng: [NSData dataWithBytes:data+16 length:16]];
                }
                
                if (self.exSessionInitCompleteBlock) {
                    self.exSessionInitCompleteBlock([NSData dataWithBytes:data length:16], [NSData dataWithBytes:data+16 length:16]);
                }
                
            } else {
                NSLog(@"CwCmdIdExSessionInit Error %04lX", (long)cmd.cmdResult);
                if (self.exSessionInitCompleteBlock) {
                    self.exSessionInitErrorBlock((long)cmd.cmdResult);
                }
            }
            
            self.exSessionInitCompleteBlock = nil;
            self.exSessionInitErrorBlock = nil;
            
            break;
            
        case CwCmdIdExSessionEstab:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didExSessionEstab)]) {
                    [self.delegate didExSessionEstab];
                }
                
                if (self.exSessionEstablishCompleteBlock) {
                    self.exSessionEstablishCompleteBlock();
                }
            } else {
                NSLog(@"CwCmdIdExSessionEstab Error %04lX", (long)cmd.cmdResult);
                if (self.exSessionEstablishErrorBlock) {
                    self.exSessionEstablishErrorBlock(cmd.cmdResult);
                }
            }
            
            self.exSessionEstablishCompleteBlock = nil;
            self.exSessionEstablishErrorBlock = nil;
            
            break;
            
        case CwCmdIdExSessionLogout:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didExSessoinLogout)]) {
                    [self.delegate didExSessoinLogout];
                }
            } else {
                NSLog(@"CwCmdIdExSessionLogout Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
            
        case CwCmdIdExBlockInfo:
            //output:
            //state 1B
            //accId 4B little-endian
            //amount 8B big-endian
            if (cmd.cmdResult==0x9000) {
                NSLog(@"trxStatus = %ld", (long)trxStatus);
                
                int64_t blockAmount = CFSwapInt64(*(int64_t *)[[NSData dataWithBytes:data+5 length:8] bytes]);
                NSNumber *amount = [NSNumber numberWithLongLong:blockAmount];
                NSLog(@"block amount: %lld, %@", blockAmount, amount);
                if (self.exBlockInfoCompleteBlock) {
                    self.exBlockInfoCompleteBlock(amount);
                }
            } else {
                NSLog(@"CwCmdIdExBlockInfo Error %04lX", (long)cmd.cmdResult);
                if (self.exBlockInfoErrorBlock) {
                    self.exBlockInfoErrorBlock(cmd.cmdResult);
                }
            }
            
            self.exBlockInfoCompleteBlock = nil;
            self.exBlockInfoErrorBlock = nil;
            
            break;
            
        case CwCmdIdExBlockBtc:
            //output:
            //blkSig: 32B block signature, mac of (cardId||uid||trxId||accId||amount||nonce||nonceSe), key is XCHS_SMK
            //okTkn: 4B
            //encUblkTkn: 16B encrypted unblock token, ublkTkn is (prefix 8B || amount 8B), key is ???
            //MAC2: 32B mac of (blkSig||okTkn||ublkTkn), key is XCHS_SK
            //nonceSe: 16B nonce generated by SE
            if (cmd.cmdResult==0x9000) {
                NSLog(@"trxStatus = %ld", (long)trxStatus);
                NSInteger accountID = *(int32_t *)[[cmd.cmdInput subdataWithRange:NSMakeRange(4, 4)] bytes];
                int64_t blockAmount = CFSwapInt64(*(int64_t *)[[cmd.cmdInput subdataWithRange:NSMakeRange(8, 8)] bytes]);
                NSLog(@"block account: %ld, block amount: %lld", accountID, blockAmount);
                
                CwAccount *account = [self.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", accountID]];
                account.blockAmount += blockAmount;
                
                NSData *okToken = [NSData dataWithBytes:data+32 length:4];
                NSData *unBlockToken = [NSData dataWithBytes:data+36 length:16];
                
                if (self.exBlockBtcCompleteBlock) {
                    self.exBlockBtcCompleteBlock(okToken, unBlockToken);
                }
            } else {
                NSLog(@"CwCmdIdExBlockBtc Error %04lX", (long)cmd.cmdResult);
                if (self.exBlockBtcErrorBlock) {
                    self.exBlockBtcErrorBlock(cmd.cmdResult);
                }
            }
            
            if (self.exBlockBtcCompleteBlock || self.exBlockBtcErrorBlock) {
                self.exBlockBtcCompleteBlock = nil;
                self.exBlockBtcErrorBlock = nil;
            }
            
            break;
            
        case CwCmdIdExBlockCancel:
            //output:
            //ublkSig: 32B block signature, mac of (cardId||uid||trxId||accId||amount||nonce||nonceSe), key is XCHS_SMK
            //MAC2: 32B mac of (ublkSig), key is XCHS_SK
            //nonceSe: 16B nonce generated by SE
            if (cmd.cmdResult==0x9000) {
                NSLog(@"trxStatus = %ld", (long)trxStatus);
                if (self.exBlockCancelCompleteBlock) {
                    self.exBlockCancelCompleteBlock();
                }
            } else {
                NSLog(@"CwCmdIdExBlockCancel Error %04lX", (long)cmd.cmdResult);
                if (self.exBlockCancelErrorBlock) {
                    self.exBlockCancelErrorBlock(cmd.cmdResult);
                }
            }
            
            self.exBlockCancelCompleteBlock = nil;
            self.exBlockCancelErrorBlock = nil;
            
            break;
            
        case CwCmdIdExTrxSignLogin:
            //output:
            //trHandle 4B
            if (cmd.cmdResult==0x9000) {
                NSData *loginHandle = [NSData dataWithBytes:data length:4];
                NSLog(@"trxStatus = %ld", (long)trxStatus);
                NSLog(@"loginHandle = %@", loginHandle);
                if (self.exTrxSignLoginCompleteBlock) {
                    self.exTrxSignLoginCompleteBlock(loginHandle);
                }
            } else {
                NSLog(@"CwCmdIdExTrxSignLogin Error %04lX", (long)cmd.cmdResult);
                if (self.exTrxSignLoginErrorBlock) {
                    self.exTrxSignLoginErrorBlock(cmd.cmdResult);
                }
            }
            
            self.exTrxSignLoginCompleteBlock = nil;
            self.exTrxSignLoginErrorBlock = nil;
            
            break;
            
        case CwCmdIdExTrxSignLogout:
            //output:
            //sigRcpt 32B mac of (cardId||uid||trxId||accId||dealAmount||numInputs||out1Addr||out2Addr||nonce||nonceSe), key is XCHS_SMK
            //mac: 32B mac of (sigRcpt), key is XCHS_SK
            //nonceSe: 16B
            if (cmd.cmdResult==0x9000) {
                NSLog(@"trxStatus = %ld", (long)trxStatus);
                
                if (self.exTrxSignLogoutCompleteBlock) {
                    NSData *receipt = [NSData dataWithBytes:data length:sizeof(data)];
                    self.exTrxSignLogoutCompleteBlock(receipt);
                }
            } else {
                NSLog(@"CwCmdIdExTrxSignLogout Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
            
            //MCU Commands
        case CwCmdIdMcuResetSe:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didMcuResetSe)]) {
                    [self.delegate didMcuResetSe];
                }
            } else{
                NSLog(@"CwCmdIdMcuResetSe Error %04lX", (long)cmd.cmdResult);
            }
            break;
            
        case CwCmdIdMcuSetAccount:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
            } else{
                NSLog(@"CwCmdIdMcuSetAccount Error %04lX", (long)cmd.cmdResult);
            }
            break;
            
            //Loader Commands
        
        case CwCmdIdMcuGenOtp:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didGenOTPWithError:)]) {
                    [self.delegate didGenOTPWithError:-1];
                }
            } else{
                NSLog(@"CwCmdIdMcuGenOtp Error %04lX", (long)cmd.cmdResult);
                if ([self.delegate respondsToSelector:@selector(didGenOTPWithError:)]) {
                    [self.delegate didGenOTPWithError:cmd.cmdResult];
                }
            }
            break;
        
        case CwCmdIdMcuVerifyOtp:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                //call delegate
                if ([self.delegate respondsToSelector:@selector(didVerifyOtp)]) {
                    [self.delegate didVerifyOtp];
                }
            } else{
                NSLog(@"CwCmdIdMcuVerifyOtp Error %04lX", (long)cmd.cmdResult);
                if ([self.delegate respondsToSelector:@selector(didVerifyOtpError:)]) {
                    [self.delegate didVerifyOtpError:cmd.cmdResult];
                }
            }
            break;
        
        case CwCmdIdMcuDisplayUsd:
            if (cmd.cmdResult == 0x9000) {
                if (cmd.cmdP1 == 1) {
                    self.cardFiatDisplay = [NSNumber numberWithBool:YES];
                } else {
                    self.cardFiatDisplay = [NSNumber numberWithBool:NO];
                }
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateCurrencyDisplay)]) {
                    [self.delegate didUpdateCurrencyDisplay];
                }
            } else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateCurrencyDisplayError:)]) {
                    [self.delegate didUpdateCurrencyDisplayError:cmd.cmdResult];
                }
            }
            break;
        
        case CwCmdIdBackToLoader:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                fwUpdateState = 1;
                [self resetSe];
                [self firmwareUpdate];
            } else{
                NSLog(@"CwCmdIdBackToLoader Error %04lX", (long)cmd.cmdResult);
                fwUpdateState = 1;
                [self firmwareUpdate];
            }
            break;
            
            //Loader Commands
        case LoaderCmdIdBackToSLE97Loader:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didBackToSLE97Loader)]) {
                    [self.delegate didBackToSLE97Loader];
                }
            } else{
                NSLog(@"LoaderCmdIdBackToSLE97Loader Error %04lX", (long)cmd.cmdResult);
            }
            break;
            
        case LoaderCmdIdLoadingBegin:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                fwUpdateState = 2;
                [self firmwareUpdate];
            } else{
                NSLog(@"CwCmdIdBackToLoader Error %04lX", (long)cmd.cmdResult);
            }
            break;
            
        case LoaderCmdIdWriteRecord:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                fwDataIdx++;
                [self firmwareUpdate];
            } else{
                fwDataIdx++;
                [self firmwareUpdate];
                NSLog(@"CwCmdIdBackToLoader Error %04lX, index:%ld", (long)cmd.cmdResult, (long)fwDataIdx);
            }
            break;
            
        case LoaderCmdIdVerifyMac:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                fwUpdateState = 4;
                [self firmwareUpdate];
            } else{
                NSLog(@"LoaderCmdIdVerifyMac Error %04lX", (long)cmd.cmdResult);
            }
            break;
            
        default:
            break;
    }
    
    if(cmd.cmdResult==0x6624) {
        NSLog(@"CW SE Internal Error %04lX", (long)cmd.cmdResult);
        [self cwCmdGetError];
    }
}


#pragma mark - Peripheral Delegate
/** The Transfer Service was discovered
 */


-(void) peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    //convert the RSSI to scales
    //0: strong, > -80
    //1: weak,   > -95
    //2: far,    < -95
    NSInteger scale=0;
    
    self.rssi = RSSI;
    
    if (self.rssi.floatValue>-80)
        scale=0;
    else if (self.rssi.floatValue>-95)
        scale=1;
    else
        scale=2;
    
    NSLog (@"RSSI %@, scale: %ld", RSSI, scale);
    
//    if (self.securityPolicy_WatchDogEnable.boolValue && scale > [self.securityPolicy_WatchDogScale integerValue]) {
//        if ([self.delegate respondsToSelector:@selector(didWatchDogAlert:)])
//            [self.delegate didWatchDogAlert:scale];
//    }
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"Service discovered");
    if (error) {
        NSLog(@"[Error] didDiscoverServices:%@", [error localizedDescription]);
        return;
    }
    
    NSLog(@"Discovering charateristics A006, A007, A008, A009");
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:@"A006"], [CBUUID UUIDWithString:@"A007"],
                                              [CBUUID UUIDWithString:@"A008"], [CBUUID UUIDWithString:@"A009"],] forService:service];
    }
}

/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"Characteristics discovered for service");
    
    // Deal with errors (if any)
    if (error) {
        NSLog(@"didDiscoverCharacteristicsForService:%@", [error localizedDescription]);
        return;
    }
    
    NSLog(@"[Service %@]\n", [self CBUUIDToString:service.UUID]);
    for (CBCharacteristic *characteristic in service.characteristics) {
        /*
         if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"A009"]]) {
         [peripheral setNotifyValue:YES forCharacteristic:characteristic];
         }
         */
        
        NSLog(@"\t[Characteristic %@]: properties %X",[self CBUUIDToString:characteristic.UUID], (int)characteristic.properties);
    }
    
    sleep(0.5);
    
    if ([self.delegate respondsToSelector:@selector(didPrepareService)]) {
        [self.delegate didPrepareService];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:@"A009"]]) {
        NSLog(@"Notification %@", characteristic);
        return;
    }
    
}

/**
 * Invoked when you retrieve a specified characteristic’s value,
 * or when the peripheral device notifies your app that the characteristic’s value has changed.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"[ERROR] didUpdateValueForCharacteristic [%@]: %@",
              [self CBUUIDToString:characteristic.UUID], [error localizedDescription]);
    } else {
        NSLog(@"        [%@] [BLE_ReadData] %@", [self CBUUIDToString:characteristic.UUID], [self NSDataToHex:characteristic.value]);
        
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"A006"]]) {
            
            if (trxStatus==TrxStatusWaitOtp || trxStatus==TrxStatusWaitBtn) {
                //Get BLE status
                Byte* output = (Byte*)[characteristic.value bytes];
                if (output[characteristic.value.length-1]==0x00) {
                    if (trxStatus==TrxStatusWaitOtp || trxStatus==TrxStatusWaitBtn) {
                        //busy, wait
                        //[NSThread sleepForTimeInterval:0.5];
                        sleep(0.3);
                        [self BLE_ReadStatus];
                    }
                } else if (output[characteristic.value.length-1]==0x80) {
                    //[NSThread sleepForTimeInterval:0.1];
                    [self BLE_ReadData];
                }
            } else {
                if (cmdWaitDataFlag) {
                    //Get BLE status
                    Byte* output = (Byte*)[characteristic.value bytes];
                    if (output[characteristic.value.length-1]==0xFF || output[characteristic.value.length-1]==0x81) {
                        //busy, wait
                        //[NSThread sleepForTimeInterval:0.3];
                        //sleep(0.3);
                        [self BLE_ReadStatus];
                    } else if (output[characteristic.value.length-1]==0x00) {
                        //[NSThread sleepForTimeInterval:0.1];
                        [self BLE_ReadData];
                    }
                }
            }
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"A009"]]) {
            //Get command output
            Byte* output = (Byte*)[characteristic.value bytes];
            
            if (trxStatus==TrxStatusWaitOtp) {
                trxStatus=TrxStatusGetOtp;
                NSLog(@"trxStatus = %ld", (long)trxStatus);
                NSString *OTP = [[NSString alloc] initWithBytes:output+5 length:6 encoding:NSUTF8StringEncoding];
                if ([self.delegate respondsToSelector:@selector(didGetTapTapOtp:)]) {
                    [self.delegate didGetTapTapOtp:OTP];
                }
            } else if (trxStatus==TrxStatusWaitBtn) {
                trxStatus=TrxStatusGetBtn;
                NSLog(@"trxStatus = %ld", (long)trxStatus);
                if ([self.delegate respondsToSelector:@selector(didGetButton)]) {
                    [self.delegate didGetButton];
                }
            } else {
                if(characteristic.value.length==1 && output[0]==0xFC)
                {
                    cmdWaitDataFlag = 0;
                    //End of Command, Parse Results
                    [currentCmd ParseBleOutputData:cwOutputs];
                    
                    //Call Delegates
                    NSLog(@"[BLE_Ret] < %@ SW:%02X", [self NSDataToHex:currentCmd.cmdOutput], (int)currentCmd.cmdResult);
                    
                    //Update CwCards
                    [self updateCwCardByCommand:currentCmd];
                    
                    //Process next command
                    currentCmd.busy = NO;
                    //[NSThread sleepForTimeInterval:0.2];
                    [self cmdProcessor];
                }
                else if (characteristic.value.length==3 && output[0]==0x00)
                {
                    //no data return, sw return only
                    //add this case for speed up, skip read FC
                    Byte swOnly[4] = {0x01, 0x02, output[1], output[2]};
                    
                    [cwOutputs addObject: [NSData dataWithBytes:swOnly length:4]];
                    cmdWaitDataFlag = 0;
                    //End of Command, Parse Results
                    [currentCmd ParseBleOutputData:cwOutputs];
                    
                    //Call Delegates
                    NSLog(@"[BLE_Ret] < %@ SW:%02X", [self NSDataToHex:currentCmd.cmdOutput], (int)currentCmd.cmdResult);
                    
                    //Update CwCards
                    [self updateCwCardByCommand:currentCmd];
                    
                    //Process next command
                    currentCmd.busy = NO;
                    //[NSThread sleepForTimeInterval:0.2];
                    [self cmdProcessor];
                }
                else
                {
                    //use the flag to skip the 1st notification BLE data
                    if (cmdWaitDataFlag==1)
                        cmdWaitDataFlag=2;
                    else
                        [cwOutputs addObject: characteristic.value];
                    //read more data
                    [self BLE_ReadData];
                }
            }
        }
    }
}

/**
 * Invoked when you write data to a characteristic’s value.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"[ERROR] didWriteValueForCharacteristic [%@]: %@",
              [self CBUUIDToString:characteristic.UUID], [error localizedDescription]);
    } else {
        NSLog(@"        [%@] has been written", [self CBUUIDToString:characteristic.UUID]);
        
        //Check if need to send data
        NSData *cmdData = [currentCmd GetBleInputDataPacket];
        if (cmdData.length>0) {
            [self BLE_SendData: cmdData];
        } else {
            
            //if Enable A009 Notify
            //cmdWaitDataFlag = 1;
            cmdWaitDataFlag = 2;
            
            //start timer check BLE returns
            /*
             if (bleTimer == nil) {
             bleTimerCounter = 0;
             bleTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(checkBleStatus) userInfo:nil repeats:YES];
             NSLog(@"BLE Timer Start");
             }
             */
            
            [cwOutputs removeAllObjects];
            //wait for BLE to process
            //[NSThread sleepForTimeInterval:0.1];
            //currentCmd.busy=NO;
            [self BLE_ReadStatus];
            //[self BLE_ReadData];
        }
    }
}

//Timer handler
-(void) checkBleStatus
{
    if (cmdWaitDataFlag == 0 || cmdWaitDataFlag == 2) // 1:no waiting, 2:keep waiting, have receive at least notification, should be end soon
    {
        //stop timer
        if (bleTimer != nil) {
            [bleTimer invalidate];
            bleTimer=nil;
            NSLog(@"BLE Timer Stop");
        }
        return;
    }
    if (cmdWaitDataFlag == 1) //start waiting, not receive any notifications yet
    {
        //check if the BLE status is still busy
        if (bleTimerCounter==0)
            [self BLE_ReadStatus];
    }
    
    bleTimerCounter ++;
    
}

#pragma mark - BLE commands
-(void) BLE_SendCmd:(CwCardCommand*) cwCmd
{
    cmdWaitDataFlag = 0;
    
    for(CBService *service in self.peripheral.services)
    {
        if([service.UUID isEqual:[CBUUID UUIDWithString:@"A000"]])
        {
            for(CBCharacteristic *charac in service.characteristics)
            {
                if([charac.UUID isEqual:[CBUUID UUIDWithString:@"A007"]])
                {
                    //NOW DO YOUR WRITING/READING AND YOU'LL BE GOOD TO GO
                    NSData *cmd = [cwCmd GetBleInputCmdPacket];
                    NSLog(@"[BLE_Cmd] > %@ %@", [self cmdIdToString:cwCmd.cmdId ], [self NSDataToHex:cmd]);
                    [self.peripheral writeValue:cmd forCharacteristic:charac type:CBCharacteristicWriteWithResponse];
                    return;
                }
            }
        }
    }
    
    NSLog(@"[BLE_SendCmd] Service and Characteristic not found");
}

-(void) BLE_SendData:(NSData*)BLE_Data
{
    for(CBService *service in self.peripheral.services)
    {
        if([service.UUID isEqual:[CBUUID UUIDWithString:@"A000"]])
        {
            for(CBCharacteristic *charac in service.characteristics)
            {
                if([charac.UUID isEqual:[CBUUID UUIDWithString:@"A008"]])
                {
                    NSLog(@"[BLE_Out] > %@", [self NSDataToHex:BLE_Data]);
                    [self.peripheral writeValue:BLE_Data forCharacteristic:charac type:CBCharacteristicWriteWithResponse];
                    return;
                }
            }
        }
    }
    NSLog(@"[BLE_SendData] Service and Characteristic not found");
}

-(void) BLE_ReadData
{
    for(CBService *service in self.peripheral.services)
    {
        if([service.UUID isEqual:[CBUUID UUIDWithString:@"A000"]])
        {
            for(CBCharacteristic *charac in service.characteristics)
            {
                if([charac.UUID isEqual:[CBUUID UUIDWithString:@"A009"]])
                {
                    [self.peripheral readValueForCharacteristic:charac];
                    return;
                }
            }
        }
    }
    NSLog(@"[BLE_ReadData] Service and Characteristic not found");
}

-(void) BLE_ReadStatus
{
    for(CBService *service in self.peripheral.services)
    {
        if([service.UUID isEqual:[CBUUID UUIDWithString:@"A000"]])
        {
            for(CBCharacteristic *charac in service.characteristics)
            {
                if([charac.UUID isEqual:[CBUUID UUIDWithString:@"A006"]])
                {
                    [self.peripheral readValueForCharacteristic:charac];
                    return;
                }
            }
        }
    }
    NSLog(@"[BLE_ReadStatus] Service and Characteristic not found");
}

#pragma mark - Utilities
//Internal Functions
- (NSData *)dataFromHexString: (NSString *) hexStr
{
    const char *chars = [hexStr UTF8String];
    int i = 0;
    NSInteger len = hexStr.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}

-(NSString*)CBUUIDToString:(CBUUID*)cbuuid;
{
    NSData* data = cbuuid.data;
    if ([data length] == 2)
    {
        const unsigned char *tokenBytes = [data bytes];
        return [NSString stringWithFormat:@"%02x%02x", tokenBytes[0], tokenBytes[1]];
    }
    else if ([data length] == 16)
    {
        NSUUID* nsuuid = [[NSUUID alloc] initWithUUIDBytes:[data bytes]];
        return [nsuuid UUIDString];
    }
    
    return [cbuuid description]; // an error?
}

-(NSString*) NSDataToHex:(NSData*)data
{
    const unsigned char *dbytes = [data bytes];
    NSMutableString *hexStr =
    [NSMutableString stringWithCapacity:[data length]*2];
    int i;
    for (i = 0; i < [data length]; i++) {
        [hexStr appendFormat:@"%02X", dbytes[i]];
    }
    return [NSString stringWithString: hexStr];
}

@end

