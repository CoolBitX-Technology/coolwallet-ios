//
//  CwCardDelegate.h
//  CwTest
//
//  Created by CP Hsiao on 2014/12/8.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#ifndef CwTest_CwCardDelegate_h
#define CwTest_CwCardDelegate_h


#import <Foundation/Foundation.h>
#import "CwCard.h"
#import "CwAddress.h"

@class CwCard;

@protocol CwCardDelegate <NSObject>

//@required

@optional

typedef NS_ENUM (NSInteger, CwCardRSSI) {
    CwCardRSSIStrong = 0x00,    // > -80
    CwCardRSSIWeak = 0x01,      // > -95
    CwCardRSSIFar = 0x02        // < -95
};

-(void) didWatchDogAlert: (NSInteger) scale; //0: strong, 1: weak, 2: far

-(void) didPrepareService;
-(void) didCwCardCommand;
-(void) didCwCardCommandError:(NSInteger)cmdId ErrString:(NSString*)errString;
-(void) didSyncFromCard;
-(void) didSyncToCard;

-(void) didGetModeState;
-(void) didGetCwInfo;

-(void) didReInitCw;

-(void) didPinChlng;
-(void) didPinAuth;
-(void) didPinChange;
-(void) didPinLogout;

-(void) didRegisterHost: (NSString *)OTP;
-(void) didConfirmHost;
-(void) didEraseCw;     //erase wallet & hosts
-(void) didEraseWallet; //erase wallet, perserved hosts
-(void) didLoginHost;
-(void) didLogoutHost;

-(void) didGetHosts;
-(void) didApproveHost: (NSInteger) hostId;
-(void) didRemoveHost: (NSInteger) hostId;

-(void) didPersoSecurityPolicy;
-(void) didGetSecurityPolicy;
-(void) didSetSecurityPolicy;

-(void) didGetCwCardName; //cardName
-(void) didSetCwCardName; //cardName

-(void) didGetCwCurrRate; //currRate
-(void) didSetCwCurrRate; //currRate

-(void) didGetCwCardId;

-(void) didGetCwHdwStatus; //hdwStatus,
-(void) didGetCwHdwName; //hdwName,
-(void) didGetCwHdwAccountPointer; //hdwAccointPointer
-(void) didSetCwHdwName; //hdwName
-(void) didSetCwHdwAccointPointer; //hdwAccointPointer

-(void) didInitHdwBySeed;
-(void) didInitHdwByCard;
-(void) didInitHdwConfirm;

-(void) didNewAccount: (NSInteger) accId;
-(void) didGetAccounts;
-(void) didGetAccountInfo: (NSInteger) accId;
-(void) didSetAccountName;
-(void) didSetAccountBalance;
-(void) didSetAccountExtKeyPtr;
-(void) didSetAccountIntKeyPtr;

-(void) didGenAddress: (CwAddress *) addr;
-(void) didGenAddressError;
-(void) didGetAccountAddresses: (NSInteger) accId;
-(void) didGetAddressInfo;

-(void) didPrepareTransaction: (NSString *)OTP;
-(void) didPrepareTransactionError: (NSString *)errMsg;
-(void) didGetTapTapOtp: (NSString *)OTP;
-(void) didGetButton;
-(void) didVerifyOtp;
-(void) didVerifyOtpError;
-(void) didSignTransaction;
-(void) didSignTransactionError: (NSString *)errMsg;
-(void) didCancelTransaction;
-(void) didFinishTransaction;

//Exchange Site Callbacks
-(void) didExGetRegStatus: (NSInteger) status;
-(void) didExGetOtp: (NSString *) exOtp;
-(void) didExSessionInit: (NSData *)seResp SeChlng: (NSData*)seChlng;
-(void) didExSessionEstab;
-(void) didExSessoinLogout;


-(void) didMcuResetSe;

-(void) didUpdateFirmwareProgress: (float)progress;
-(void) didUpdateFirmwareDone: (NSInteger)status; //AuthError, DownloadError, MacError, DownloadSuccess

-(void) didBackToSLE97Loader;

@end

#endif
