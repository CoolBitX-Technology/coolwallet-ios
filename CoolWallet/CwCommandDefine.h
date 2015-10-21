//
//  CwCommandDefine.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/10/20.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#ifndef CwCommandDefine_h
#define CwCommandDefine_h

typedef NS_ENUM (NSInteger, LoaderCmdId) {
    //SE Commands
    LoaderCmdIdEcho         = 0xBE,
    LoaderCmdIdGetSn        = 0xC0,
    LoaderCmdIdGetVersion   = 0xC1,
    LoaderCmdIdGetStatus    = 0xC2,
    //LoaderCmdIdGetAuthChlng = 0xC3,
    //LoaderCmdIdGetAuthKeyId = 0xC4,
    //LoaderCmdIdChangeLoaderKey = 0xC5,
    LoaderCmdIdBackToSLE97Loader = 0xC6,
    LoaderCmdIdLoadingBegin = 0xC7,
    LoaderCmdIdWriteRecord  = 0xC8,
    LoaderCmdIdVerifyMac    = 0xC9
};

typedef NS_ENUM (NSInteger, CwCmdId) {
    //SE Commands
    CwCmdIdGetModeState     = 0x10,
    CwCmdIdGetFwVersion     = 0x11,
    CwCmdIdGetUid           = 0x12,
    CwCmdIdGetError         = 0x13,
    
    //Init Commands
    CwCmdIdInitSetData      = 0xA0,
    CwCmdIdInitConfirm      = 0xA2,
    CwCmdIdInitVmkChlng     = 0xA3,
    CwCmdIdInitBackInit     = 0xA4,
    
    //Authentication Commands
    CwCmdIdPinChlng         = 0x20,
    CwCmdIdPinAuth          = 0x21,
    CwCmdIdPinChange        = 0x22,
    CwCmdIdPinLogout        = 0x23,
    
    //Binding Commands
    CwCmdIdBindRegInit      = 0xD0,
    CwCmdIdBindRegChlng     = 0xD1,
    CwCmdIdBindRegFinish    = 0xD2,
    CwCmdIdBindRegInfo      = 0xD3,
    CwCmdIdBindRegApprove   = 0xD4,
    CwCmdIdBindRegRemove    = 0xD5,
    CwCmdIdBindLoginChlng   = 0xD6,
    CwCmdIdBindLogin        = 0xD7,
    CwCmdIdBindLogout       = 0xD8,
    CwCmdIdBindFindHostId   = 0xD9,
    CwCmdIdBindBackNoHost   = 0xDA,
    
    //Perso Commands
    CwCmdIdPersoSetData       = 0x30,
    CwCmdIdPersoConfirm       = 0x32,
    CwCmdIdPersoBackPerso     = 0x33,
    
    //CW Setting Commands
    CwCmdIdSetCurrRate      = 0x40,
    CwCmdIdGetCurrRate      = 0x41,
    CwCmdIdGetCardName      = 0x42,
    CwCmdIdSetCardName      = 0x43,
    CwCmdIdGetPerso         = 0x44,
    CwCmdIdSetPerso         = 0x45,
    CwCmdIdGetCardId        = 0x46,
    
    //HD Wallet Commands
    CwCmdIdHdwInitWallet            = 0xB0,
    CwCmdIdHdwInitWalletGen         = 0xB1,
    CwCmdIdHdwQueryWalletInfo       = 0xB2,
    CwCmdIdHdwSetWalletInfo         = 0xB3,
    CwCmdIdHdwCreateAccount         = 0xB4,
    CwCmdIdHdwQueryAccountInfo      = 0xB5,
    CwCmdIdHdwSetAccountInfo        = 0xB6,
    CwCmdIdHdwGetNextAddress        = 0xB7,
    CwCmdIdHdwPrepTrxSign           = 0xB8,
    CwCmdIdHdwInitWalletGenConfirm  = 0xB9,
    CwCmdIdHdwQueryAccountKeyInfo   = 0xBA,
    
    //Transaction Commands
    CwCmdIdTrxStatus        = 0x80,
    CwCmdIdTrxBegin         = 0x72,
    CwCmdIdTrxVerifyOtp     = 0x73,
    CwCmdIdTrxSign          = 0x74,
    CwCmdIdTrxFinish        = 0x76,
    CwCmdIdTrxGetAddr       = 0x79,
    
    //Exchange Site Commands
    CwCmdIdExRegStatus      = 0xF0,
    CwCmdIdExGetOtp         = 0xF4,
    CwCmdIdExSessionInit    = 0xF5,
    CwCmdIdExSessionEstab   = 0xF6,
    CwCmdIdExSessionLogout  = 0xF7,
    CwCmdIdExBlockInfo      = 0xF8,
    CwCmdIdExBlockBtc       = 0xF9,
    CwCmdIdExBlockCancel    = 0xFA,
    CwCmdIdExTrxSignLogin   = 0xFB,
    CwCmdIdExTrxSignPrepare = 0xFC,
    CwCmdIdExTrxSignLogout  = 0xFD,
    
    //FirmwareUpload Commmands
    CwCmdIdBackToLoader     = 0x78,
    
    //MCU Commands
    CwCmdIdMcuResetSe       = 0x60,
    CwCmdIdMcuQueryBatGague = 0x61,
    CwCmdIdMcuSetAccount    = 0x62,
};

/*
 80: Can’t Power off SE
 81: Ask MCU reserve Memory Credential, Then Power off SE
 82: Ask MCU reserve Flash Credential, Then power off SE
 83: No need to reserve anything, Power off SE after command.
 */
typedef NS_ENUM (NSInteger, CwSeCla) {
    //SE Commands
    CwCmdClaKeepPower           = 0x80,
    CwCmdClaKeepMemory          = 0x81,
    CwCmdClaKeepFlash           = 0x82,
    CwCmdClaKeepNone            = 0x83,
};

typedef NS_ENUM (NSInteger, CwCmdCLA) {
    //SE Commands
    CwCmdIdGetModeStateCLA     = CwCmdClaKeepMemory,
    CwCmdIdGetFwVersionCLA     = CwCmdClaKeepNone,
    CwCmdIdGetUidCLA           = CwCmdClaKeepNone,
    CwCmdIdGetErrorCLA         = CwCmdClaKeepNone,//?
    
    //Init Commands
    CwCmdIdInitSetDataCLA      = CwCmdClaKeepPower,
    CwCmdIdInitConfirmCLA      = CwCmdClaKeepNone,
    CwCmdIdInitVmkChlngCLA     = CwCmdClaKeepPower,
    CwCmdIdInitBackInitCLA     = CwCmdClaKeepPower,
    
    //Authentication Commands
    CwCmdIdPinChlngCLA         = CwCmdClaKeepPower,
    CwCmdIdPinAuthCLA          = CwCmdClaKeepMemory,
    CwCmdIdPinChangeCLA        = CwCmdClaKeepMemory,
    CwCmdIdPinLogoutCLA        = CwCmdClaKeepMemory,
    
    //Binding Commands
    CwCmdIdBindRegInitCLA      = CwCmdClaKeepPower, //?
    CwCmdIdBindRegChlngCLA     = CwCmdClaKeepPower,
    CwCmdIdBindRegFinishCLA    = CwCmdClaKeepMemory,
    CwCmdIdBindRegInfoCLA      = CwCmdClaKeepNone,  //for registered host: 83, for non-registered hot: 80
    CwCmdIdBindRegApproveCLA   = CwCmdClaKeepMemory,
    CwCmdIdBindRegRemoveCLA    = CwCmdClaKeepMemory,
    CwCmdIdBindLoginChlngCLA   = CwCmdClaKeepMemory,  //?
    CwCmdIdBindLoginCLA        = CwCmdClaKeepMemory,
    CwCmdIdBindLogoutCLA       = CwCmdClaKeepMemory, //?CwCmdClaKeepNone
    CwCmdIdBindFindHostIdCLA   = CwCmdClaKeepNone,
    CwCmdIdBindBackNoHostCLA   = CwCmdClaKeepMemory,
    
    //Perso Commands
    CwCmdIdPersoSetDataCLA       = CwCmdClaKeepMemory,
    CwCmdIdPersoConfirmCLA       = CwCmdClaKeepMemory,
    CwCmdIdPersoBackPersoCLA     = CwCmdClaKeepMemory,
    
    //CW Setting Commands
    CwCmdIdSetCurrRateCLA      = CwCmdClaKeepNone,
    CwCmdIdGetCurrRateCLA      = CwCmdClaKeepNone,
    CwCmdIdGetCardNameCLA      = CwCmdClaKeepNone,
    CwCmdIdSetCardNameCLA      = CwCmdClaKeepNone,
    CwCmdIdGetPersoCLA         = CwCmdClaKeepNone,
    CwCmdIdSetPersoCLA         = CwCmdClaKeepNone,
    CwCmdIdGetCardIdCLA        = CwCmdClaKeepNone,
    
    //HD Wallet Commands
    CwCmdIdHdwInitWalletCLA            = CwCmdClaKeepMemory,
    CwCmdIdHdwInitWalletGenCLA         = CwCmdClaKeepMemory,
    CwCmdIdHdwQueryWalletInfoCLA       = CwCmdClaKeepNone,
    CwCmdIdHdwSetWalletInfoCLA         = CwCmdClaKeepMemory,
    CwCmdIdHdwCreateAccountCLA         = CwCmdClaKeepMemory,
    CwCmdIdHdwQueryAccountInfoCLA      = CwCmdClaKeepNone,
    CwCmdIdHdwSetAccountInfoCLA        = CwCmdClaKeepMemory,
    CwCmdIdHdwGetNextAddressCLA        = CwCmdClaKeepMemory,
    CwCmdIdHdwPrepTrxSignCLA           = CwCmdClaKeepMemory,
    CwCmdIdHdwInitWalletGenConfirmCLA  = CwCmdClaKeepMemory,
    CwCmdIdHdwQueryAccountKeyInfoCLA   = CwCmdClaKeepMemory,
    
    //Transaction Commands
    CwCmdIdTrxStatusCLA        = CwCmdClaKeepMemory,
    CwCmdIdTrxBeginCLA         = CwCmdClaKeepMemory,
    CwCmdIdTrxVerifyOtpCLA     = CwCmdClaKeepMemory,
    CwCmdIdTrxSignCLA          = CwCmdClaKeepMemory,
    CwCmdIdTrxFinishCLA        = CwCmdClaKeepMemory,
    CwCmdIdTrxGetAddrCLA       = CwCmdClaKeepMemory, //?
    
    //Exchange Site Commands
    CwCmdIdExRegStatusCLA      = CwCmdClaKeepMemory,
    CwCmdIdExGetOtpCLA         = CwCmdClaKeepMemory,
    CwCmdIdExSessionInitCLA    = CwCmdClaKeepFlash, //?
    CwCmdIdExSessionEstabCLA   = CwCmdClaKeepFlash, //?
    CwCmdIdExSessionLogoutCLA  = CwCmdClaKeepFlash, //?
    CwCmdIdExBlockInfoCLA      = CwCmdClaKeepFlash, //?
    CwCmdIdExBlockBtcCLA       = CwCmdClaKeepFlash, //?
    CwCmdIdExBlockCancelCLA    = CwCmdClaKeepFlash, //?
    CwCmdIdExTrxSignLoginCLA   = CwCmdClaKeepFlash, //?
    CwCmdIdExTrxSignPrepareCLA = CwCmdClaKeepFlash, //?
    CwCmdIdExTrxSignLogoutCLA  = CwCmdClaKeepFlash, //?
    
    //FirmwareUpload Commmands
    CwCmdIdBackToLoaderCLA     = CwCmdClaKeepNone, //?
    
    //MCU Commands
    CwCmdIdMcuResetSeCLA       = CwCmdClaKeepNone, //?
    CwCmdIdMcuQueryBatGagueCLA = CwCmdClaKeepNone, //?
    CwCmdIdMcuSetAccountCLA    = CwCmdClaKeepNone,
};

typedef NS_ENUM (NSInteger, CwSecurityPolicyMask) {
    CwSecurityPolicyMaskOtp         = 0x01,
    CwSecurityPolicyMaskBtn         = 0x02,
    CwSecurityPolicyMaskWatchDog    = 0x10,
    CwSecurityPolicyMaskAddress     = 0x20,
};

typedef NS_ENUM (NSInteger, CwHdwInfo) {
    CwHdwInfoStatus             = 0x00,
    CwHdwInfoName               = 0x01,
    CwHdwInfoAccountPointer     = 0x02
};

typedef NS_ENUM (NSInteger, CwHdwAccountInfo) {
    CwHdwAccountInfoName        = 0x00,
    CwHdwAccountInfoBalance     = 0x01,
    CwHdwAccountInfoExtKeyPtr   = 0x02,
    CwHdwAccountInfoIntKeyPtr   = 0x03,
    CwHdwAccountInfoBlockAmount = 0x04
};

typedef NS_ENUM (NSInteger, CwHdwAccountKeyInfo) {
    CwHdwAccountKeyInfoAddress  = 0x00,
    CwHdwAccountKeyInfoPubKey   = 0x01
};

#endif /* CwCommandDefine_h */
