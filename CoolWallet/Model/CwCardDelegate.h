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
-(void) didRegisterHostError:(NSInteger)errorId;
-(void) didConfirmHost;
-(void) didConfirmHostError:(NSInteger)errId;
-(void) didEraseCw;     //erase wallet & hosts
-(void) didEraseCwError:(NSInteger)errId;     //fail to erase wallet & hosts
-(void) didEraseWallet; //erase wallet, perserved hosts
-(void) didLoginHost;
-(void) didLogoutHost;

-(void) didGenOTPWithError:(NSInteger)errId;

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
-(void) didSetAccountBalance:(NSInteger) accId;
-(void) didSetAccountExtKeyPtr:(NSInteger) accId keyPtr:(NSInteger)keyPtr;
-(void) didSetAccountIntKeyPtr:(NSInteger) accId keyPtr:(NSInteger)keyPtr;

-(void) didGenAddress: (CwAddress *) addr;
-(void) didGenAddressError;
-(void) didGetAccountAddresses: (NSInteger) accId;
-(void) didGetAddressInfo;
-(void) didGetAddressPublicKey:(CwAddress *)addr;

-(void) didPrepareTransaction: (NSString *)OTP;
-(void) didPrepareTransactionError: (NSString *)errMsg;
-(void) didGetTapTapOtp: (NSString *)OTP;
-(void) didGetButton;
-(void) didVerifyOtp;
-(void) didVerifyOtpError:(NSInteger)errId;
-(void) didSignTransaction:(NSString *)txId;
-(void) didSignTransactionError: (NSString *)errMsg;
-(void) didCancelTransaction;
-(void) didFinishTransaction;

//Exchange Site Callbacks
-(void) didExGetRegStatus: (NSInteger) status;
-(void) didExGetOtp:(NSString *)exOtp type:(NSInteger)otpType;
-(void) didExGetOtpError:(NSInteger)errId type:(NSInteger)otpType;
-(void) didExSessionInit: (NSData *)seResp SeChlng: (NSData*)seChlng;
-(void) didExSessionEstab;
-(void) didExSessoinLogout;


-(void) didMcuResetSe;

-(void) didUpdateFirmwareProgress: (float)progress;
-(void) didUpdateFirmwareDone: (NSInteger)status; //AuthError, DownloadError, MacError, DownloadSuccess

-(void) didBackToSLE97Loader;

-(void) didUpdateCurrencyDisplay;
-(void) didUpdateCurrencyDisplayError:(NSInteger)errorCode;

@end

#endif
