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
#import "CwCard.h"
#import "CwCardApduError.h"
#import "CwHost.h"
#import "CwAddress.h"

#import "CwBtcNetwork.h"

#import "CwCardCommand.h"
#import "KeychainItemWrapper.h"

#import "CwTx.h"
#import "CwTxin.h"
#import "CwTxout.h"
#import "CwUnspentTxIndex.h"
#import "CwBase58.h"

#import "CwCardSoft.h"

//#define CW_SOFT_SIMU

//******************************************************
//Default Init data (set by init tool)
//******************************************************
Byte TEST_PUK[32]= {0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f};
Byte TEST_XCHSSEMK[32]= {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f};
Byte TEST_XCHSOTPK[32]=  {0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f};
Byte TEST_XCHSSMK[32]=   {0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f};

//******************************************************
//Default VMK
//******************************************************
Byte TEST_VMK[32]= {0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f};
/* Host description (64 bytes) */
Byte PreHostDesc0[64] = {
    0x50, 0x72, 0x65, 0x2d, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x65, 0x72, 0x65, 0x64, 0x20, 0x68,
    0x6f, 0x73, 0x74, 0x20, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
Byte PreHostOtpKey0[32] = {
    0xD0, 0xBD, 0xBC, 0x88, 0x84, 0x47, 0x54, 0xC5, 0xDF, 0x9C, 0x40, 0xDA, 0x30, 0x99, 0x95, 0x95,
    0xF4, 0x12, 0x00, 0x75, 0x15, 0x0B, 0x1B, 0xB2, 0xD3, 0x14, 0x5F, 0x6A, 0x3D, 0xC1, 0xB6, 0xE8};
Byte PreHostDesc1[64] = {
    0x50, 0x72, 0x65, 0x2d, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x65, 0x72, 0x65, 0x64, 0x20, 0x68,
    0x6f, 0x73, 0x74, 0x20, 0x31, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
Byte PreHostOtpKey1[32] = {
    0xF1, 0x49, 0x54, 0x11, 0xF8, 0xC0, 0x6A, 0xFC, 0xD2, 0xFF, 0x61, 0x97, 0x99, 0x84, 0x69, 0x63,
    0xB2, 0x63, 0x67, 0x30, 0x14, 0x85, 0x51, 0x29, 0x25, 0xFA, 0x19, 0xFD, 0x41, 0x78, 0x43, 0x2A};
Byte PreHostDesc2[64] = {
    0x50, 0x72, 0x65, 0x2d, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x65, 0x72, 0x65, 0x64, 0x20, 0x68,
    0x6f, 0x73, 0x74, 0x20, 0x32, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
Byte PreHostOtpKey2[32] = {
    0x56, 0x87, 0x55, 0xDD, 0x22, 0x96, 0xEB, 0x70, 0x8E, 0x88, 0x90, 0xAB, 0x7C, 0x7E, 0x8C, 0xC1,
    0x3D, 0xCF, 0x00, 0xD5, 0xD1, 0x42, 0x3A, 0x05, 0xC8, 0x6D, 0xA8, 0x90, 0xC8, 0x28, 0x67, 0x26};
Byte PreHostDesc3[64] = {
    0x50, 0x72, 0x65, 0x2d, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x65, 0x72, 0x65, 0x64, 0x20, 0x68,
    0x6f, 0x73, 0x74, 0x20, 0x33, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
Byte PreHostOtpKey3[32] = {
    0x1F, 0x16, 0xE0, 0x8C, 0x23, 0x68, 0xF8, 0xC0, 0x32, 0xD8, 0xED, 0xB5, 0xFA, 0x29, 0x1F, 0x51,
    0xB5, 0xF4, 0xEA, 0x06, 0x6C, 0xE4, 0xF7, 0xE6, 0xDC, 0x0F, 0x2D, 0xC2, 0xF2, 0x6F, 0x43, 0x7B};
Byte PreHostDesc4[64] = {
    0x50, 0x72, 0x65, 0x2d, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x65, 0x72, 0x65, 0x64, 0x20, 0x68,
    0x6f, 0x73, 0x74, 0x20, 0x34, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
Byte PreHostOtpKey4[32] = {
    0x6D, 0x98, 0x15, 0xBF, 0x1A, 0xD6, 0xB1, 0x8E, 0xDF, 0x8D, 0x97, 0x57, 0x33, 0x23, 0x42, 0xB1,
    0x39, 0x73, 0x46, 0x62, 0x07, 0x0A, 0xA8, 0x6C, 0x80, 0x7F, 0xC8, 0x32, 0xDE, 0xEF, 0xF6, 0xC9};
Byte PreHostDesc5[64] = {
    0x50, 0x72, 0x65, 0x2d, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x65, 0x72, 0x65, 0x64, 0x20, 0x68,
    0x6f, 0x73, 0x74, 0x20, 0x35, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
Byte PreHostOtpKey5[32] = {
    0x60, 0xAC, 0x13, 0x14, 0x29, 0x80, 0x36, 0x79, 0xB5, 0x49, 0xAF, 0x30, 0x46, 0x0E, 0x14, 0x83,
    0xEA, 0xED, 0x34, 0x8A, 0xBF, 0x54, 0x6D, 0x37, 0xD5, 0x5D, 0x98, 0x82, 0xAD, 0x47, 0xA2, 0xB0};
Byte PreHostDesc6[64] = {
    0x50, 0x72, 0x65, 0x2d, 0x72, 0x65, 0x67, 0x69, 0x73, 0x74, 0x65, 0x72, 0x65, 0x64, 0x20, 0x68,
    0x6f, 0x73, 0x74, 0x20, 0x36, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
Byte PreHostOtpKey6[32] = {
    0x18, 0xF3, 0xFB, 0x2D, 0x6D, 0x06, 0xA6, 0x21, 0xD3, 0xAA, 0x54, 0xE1, 0x54, 0x89, 0xB6, 0x66,
    0xE8, 0x01, 0xD4, 0x1C, 0xB7, 0x62, 0x65, 0xE7, 0xFA, 0x49, 0xBE, 0x51, 0x7E, 0x17, 0x64, 0xD0};

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


@interface CwCard () <CBPeripheralDelegate>

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

NSString *defaultPin;
NSString *initCardId;

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

Boolean syncAccNameFlag[5];
Boolean syncAccBalanceFlag[5];
Boolean syncAccBlockAmountFlag[5];
Boolean syncAccExtPtrFlag[5];
Boolean syncAccIntPtrFlag[5];

Boolean syncAccExtAddress[5];
Boolean syncAccIntAddress[5];

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

#ifdef CW_SOFT_SIMU
CwCardSoft *cwSoft;
#endif

NSArray *addresses;

#pragma mark - CwCard Methods
-(id) init {
    if (self = [super init]) {
        //init currentCmd;
        //currentCmd = [[CwCardCommand alloc]init];
        currentCmd = nil;
        cwCmds = [[NSMutableArray alloc] init];
        cwOutputs = [[NSMutableArray alloc] init];
        
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
            syncAccNameFlag[i] = NO;
            syncAccBalanceFlag[i] = NO;
            syncAccBlockAmountFlag[i] = NO;
            syncAccExtPtrFlag[i] = NO;
            syncAccIntPtrFlag[i] = NO;
            syncAccExtAddress[i] = NO;
            syncAccIntAddress[i] = NO;
        }
        
#ifdef CW_SOFT_SIMU
        cwSoft = [[CwCardSoft alloc] init];
        addresses = @[@"1MPMPdKkCnPkupgKCZKvj5Tt5zUky2uif9",
                      @"15UPoUcyLLuiRcoLkVxNS3ZdVTem3r3o3E",
                      @"1qs6k9tpdWoRgEYAzhRVxZrkCvBBW9Ufi",
                      @"16YqRges1zMMf2Ey5DQkLA6oSZchY9BTMR",
                      @"1JYbYSBhv5z3A2Tys1PdZGg83bzAFXY81K",
                      @"1GRE9Mqunm4tQrVi3vkZJVHPoTfeBLpLh",
                      @"13jHaUswio2j5DCyPfEA46S1DpKUKDDGAT",
                      @"1H8YgoiKwMjP3B5t9pHgpKLPUCptmzyecs",
                      @"1588iYaAN4CD9jDJbn1TUmwnsHL7ZDYahQ",
                      @"12ZT68cNakKMeBM7xJXRSRdWpRp6MXsnFf",
                      @"1J9e7LzV976KQ5nMbGGKqa22ym71o1TMp8",
                      @"1N3BuQ4ovZfhhzEe794wVrXX5Sv3pJ9ug2",
                      @"1CdV19C2PPKySGG9bueoGNtEe55rqT5A2u",
                      @"1KctgNgsw3X5Gkb7xvLXC8bfbsnm5tsfUU",
                      @"17YPMsf25qcL2GEGpyaggYHPHDwmgwvoVs",
                      @"1BXJQvisv3frNHWHRqEAy88UqSENZvR3XZ",
                      @"1PbXgkj75Gp4agCpeTe5LenVDiK8f5kpMU",
                      @"1QN5cHfb1eQMGtbcqrT6yXqmccqX6JbmS",
                      @"17X9Hy2gYarsco8CtdF3414vRpuQZcu6Ww",
                      @"12ENefsAYUKuD37BRGdAUTqKxPAxHqxR6d"];
#else
        addresses = [[NSArray alloc] init];
#endif
        
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
    //basic info
    [encoder encodeObject:self.fwVersion forKey:@"fwVersion"];
    [encoder encodeObject:self.uid forKey:@"uid"];
    
    //host info
    //[encoder encodeObject:self.devCredential forKey:@"devCredential"];
    [encoder encodeObject:self.currId forKey:@"currId"];
    [encoder encodeObject:self.currRate forKey:@"currRate"];
    
    //hosts
    [encoder encodeObject:self.cwHosts forKey:@"cwHosts"];
    
    //Security Policy
    [encoder encodeBool:self.securityPolicy_OtpEnable forKey:@"spOtp"];
    [encoder encodeBool:self.securityPolicy_BtnEnable forKey:@"spBtn"];
    [encoder encodeBool:self.securityPolicy_DisplayAddressEnable forKey:@"spAddr"];
    [encoder encodeBool:self.securityPolicy_WatchDogEnable forKey:@"spDog"];
    [encoder encodeBool:self.securityPolicy_WatchDogScale forKey:@"spDogScale"];
    
    //CardInfo
    [encoder encodeObject:self.cardName forKey:@"carName"];
    [encoder encodeObject:self.cardId forKey:@"cardId"];
    
    //HdwInfo
    [encoder encodeInteger:self.hdwStatus forKey:@"hdwStatus"];
    [encoder encodeObject:self.hdwName forKey:@"hdwName"];
    [encoder encodeInteger:self.hdwAcccountPointer forKey:@"hdwAccountPointer"];
    
    //Accounts
    [encoder encodeObject:self.cwAccounts forKey:@"cwAccounts"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    //basic info
    self.fwVersion = [decoder decodeObjectForKey:@"fwVersion"];
    self.uid = [decoder decodeObjectForKey:@"uid"];
    
    //host info
    //self.devCredential = [decoder decodeObjectForKey:@"devCredential"];
    self.currId = [decoder decodeObjectForKey:@"currId"];
    self.currRate = [decoder decodeObjectForKey:@"currRate"];
    
    //hosts
    self.cwHosts = [decoder decodeObjectForKey:@"cwHosts"];
    
    //security policy
    self.securityPolicy_OtpEnable = [decoder decodeBoolForKey:@"spOtp"];
    self.securityPolicy_BtnEnable =[decoder decodeBoolForKey:@"spBtn"];
    self.securityPolicy_DisplayAddressEnable = [decoder decodeBoolForKey:@"spAddr"];
    self.securityPolicy_WatchDogEnable = [decoder decodeBoolForKey:@"spDog"];
    self.securityPolicy_WatchDogScale = [decoder decodeBoolForKey:@"spDogScale"];
    
    //CardInfo
    self.cardName = [decoder decodeObjectForKey:@"carName"];
    self.cardId = [decoder decodeObjectForKey:@"cardId"];
    
    //HdwInfo
    self.hdwStatus = [decoder decodeIntegerForKey:@"hdwStatus"];
    self.hdwName = [decoder decodeObjectForKey:@"hdwName"];
    self.hdwAcccountPointer = [decoder decodeIntegerForKey:@"hdwAccountPointer"];
    
    //Accounts
    self.cwAccounts = [decoder decodeObjectForKey:@"cwAccounts"];
    
    return self;
}

-(void) prepareService
{
    //Prepare network service
    NSLog(@"Connected to peripheral, discovering service A000");
    
#ifdef CW_SOFT_SIMU
    if ([self.delegate respondsToSelector:@selector(didPrepareService)]) {
        [self.delegate didPrepareService];
    }
#else
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:@"A000"]]];
#endif
}


-(NSString *) cmdIdToString: (NSInteger) cmdId
{
    NSString *str;
    
    switch (cmdId) {
        case CwCmdIdGetModeState:       str=@"[GetModeState]"; break;
        case CwCmdIdGetFwVersion:       str=@"[GetFwVersion]"; break;
        case CwCmdIdGetUid:             str=@"[GetUid]"; break;
        case CwCmdIdGetError:           str=@"[GetError]"; break;
            
        case CwCmdIdInitSetData:        str=@"[InitSetData]"; break;
        case CwCmdIdInitConfirm:        str=@"[InitConfirm]"; break;
        case CwCmdIdInitVmkChlng:       str=@"[InitVmkChlng]"; break;
        case CwCmdIdInitBackInit:       str=@"[InitBackInit]"; break;
            
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
            
        default:                        str=@"[UnknownCmdId]"; break;
            
    }
    return str;
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

//Load Commands
-(void) loadCwCardFromFile
{
    //remove for test
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey:self.cardId];
    
    NSData *notesData = [[NSUserDefaults standardUserDefaults] objectForKey:self.bleName];
    CwCard *cwCardSaved = [NSKeyedUnarchiver unarchiveObjectWithData:notesData];
    
    if (cwCardSaved) {
        
        NSLog(@"LoadFromFile:%@ accountptr:%ld accoints:%lu", cwCardSaved.cardId, cwCardSaved.hdwAcccountPointer, (unsigned long)cwCardSaved.cwAccounts.count);
        
        //basic info
        self.fwVersion = cwCardSaved.fwVersion;
        self.uid = cwCardSaved.uid;
        
        //host Info
        //self.devCredential = cwCardSaved.devCredential;
        self.currId = cwCardSaved.currId;
        self.currRate = cwCardSaved.currRate;
        
        //hosts
        self.cwHosts = cwCardSaved.cwHosts;
        
        self.securityPolicy_OtpEnable = cwCardSaved.securityPolicy_OtpEnable;
        self.securityPolicy_BtnEnable = cwCardSaved.securityPolicy_OtpEnable;
        self.securityPolicy_DisplayAddressEnable = cwCardSaved.securityPolicy_OtpEnable;
        self.securityPolicy_WatchDogEnable = cwCardSaved.securityPolicy_OtpEnable;
        self.securityPolicy_WatchDogScale = cwCardSaved.securityPolicy_WatchDogScale;
        
        //CardInfo
        self.cardName = cwCardSaved.cardName;
        self.cardId = cwCardSaved.cardId;
        
        //hdwInfo
        self.hdwStatus = cwCardSaved.hdwStatus;
        self.hdwName = cwCardSaved.hdwName;
        self.hdwAcccountPointer = cwCardSaved.hdwAcccountPointer;
        
        //accounts
        if (cwCardSaved.cwAccounts!=nil)
            self.cwAccounts = cwCardSaved.cwAccounts;
        
        //update sync flags of address
        /*
         for (int a=0; a<self.cwAccounts.count; a++) {
         CwAccount *acc = [self.cwAccounts objectForKey: [NSString stringWithFormat:@"%d", a]];
         
         //check acc ext address status
         for(int i=0; i<acc.extKeyPointer; i++) {
         if (acc.extKeys[i])
         if (((CwAddress*)acc.extKeys[i]).address!=nil && ![((CwAddress*)acc.extKeys[i]).address isEqualToString:@""])
         syncAccExtAddress[acc.accId]=i;
         }
         
         //check acc int address status
         for(int i=0; i<acc.intKeyPointer; i++) {
         if (acc.intKeys[i])
         if (((CwAddress*)acc.intKeys[i]).address!=nil && ![((CwAddress*)acc.intKeys[i]).address isEqualToString:@""])
         syncAccIntAddress[acc.accId]=i;
         }
         }
         */
    }
}

//Save Commands
-(void) saveCwCardToFile
{
    NSLog(@"SaveCwToFile:%@ accountptr:%ld accoints:%lu", self.cardId, self.hdwAcccountPointer, (unsigned long)self.cwAccounts.count);
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:self.bleName];
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

//Re-Init Commands
-(void) reInitCard: (NSString *) cardId Pin:(NSString *)pin
{
    //Back to init mode
    
    //get vmkChallenge
    [self CwCmdInitVmkChlng];
    
    //back to init
    //[self CwCmdInitBackInit];
    
    /*
     0: Default User PIN hash (32 bytes)
     1: PUK (32 bytes)
     2: SEMK (32 bytes)
     3: Card ID (8 bytes)
     4: OTPK (32 bytes)
     5: SMK (32 bytes)
     */
    
    defaultPin = pin;
    initCardId = cardId;
    
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
    if (self.mode==CwCardModeNoHost)
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
    if (self.mode == CwCardModeDisconn) {
        [self cwCmdBindBackNoHost:pin NewPin:newPin];
    } else if (self.mode == CwCardModeNormal) {
        [self cwCmdPersoBackPerso: newPin];
        
        if (!preserveHost)
            [self cwCmdBindBackNoHost:pin NewPin:newPin];
    } else { //other modes, might not work
        [self cwCmdBindBackNoHost:pin NewPin:newPin];
    }
    
    //remove stored file
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.bleName];
    self.cardId = nil;
    self.cwAccounts = nil;
    self.cardName = nil;
    self.currId = nil;
    self.currRate = 0;
    self.hdwStatus = 0;
    self.hdwName = nil;
    self.hdwAcccountPointer = 0;
}

-(void) loginHost //callback: didLoginHost
{
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
                CwHost *host = [self.cwHosts objectForKey: [NSString stringWithFormat:@"%d", i]];
                if (host)
                    if (host.hostBindStatus== CwHostBindStatusConfirmed) {
                        syncHostFlag[i]=YES;
                        continue;
                    }
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

-(void) persoSecurityPolicy: (BOOL)otpEnable ButtonEnable: (BOOL)btnEnable DisplayAddressEnable: (BOOL) addEnable WatchDogEnable: (BOOL)wdEnable
{
    self.securityPolicy_OtpEnable = otpEnable;
    self.securityPolicy_BtnEnable = btnEnable;
    self.securityPolicy_DisplayAddressEnable = addEnable;
    self.securityPolicy_WatchDogEnable = wdEnable;
    
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
    self.securityPolicy_OtpEnable = otpEnable;
    self.securityPolicy_BtnEnable = btnEnable;
    self.securityPolicy_DisplayAddressEnable = addEnable;
    self.securityPolicy_WatchDogEnable = wdEnable;
    
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
        [self cwCmdHdwQueryWalletInfo:CwHdwInfoStatus];
    } else {
        //call delegate
        if ([self.delegate respondsToSelector:@selector(didGetCwHdwStatus)]) {
            [self.delegate didGetCwHdwStatus];
        }
        
        if (self.hdwStatus == CwHdwStatusActive) {
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
    [self setAccount: accountId Balance:0];
}

-(void) getAccounts; //didGetAccounts
{
    //get hostInfos
    for (int i=0; i<self.hdwAcccountPointer; i++) {
        [self getAccountInfo:i];
    }
}

-(void) getAccountInfo: (NSInteger) accountId;
{
    //get account from dictionary
    CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", accountId]];
    
    if (account==nil) {
        account = [[CwAccount alloc] init];
        account.accId = accountId;
        account.accName = @"";
        account.balance = 0;
        account.blockAmount = 0;
        account.extKeyPointer = 0;
        account.intKeyPointer = 0;
        
        //add the host to the dictionary with hostId as Key.
        [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", accountId]];
    }
    
    if (syncAccNameFlag[accountId] == NO) {
        [self cwCmdHdwQueryAccountInfo:CwHdwAccountInfoName AccountId:accountId];
    }
    
    if (syncAccBalanceFlag[accountId] == NO) {
        [self cwCmdHdwQueryAccountInfo:CwHdwAccountInfoBalance AccountId:accountId];
    }
    
    if (syncAccBlockAmountFlag[accountId] == NO) {
        [self cwCmdHdwQueryAccountInfo:CwHdwAccountInfoBlockAmount AccountId:accountId];
    }
    
    if (syncAccExtPtrFlag[accountId] == NO) {
        [self cwCmdHdwQueryAccountInfo:CwHdwAccountInfoExtKeyPtr AccountId:accountId];
    }
    
    if (syncAccIntPtrFlag[accountId] == NO) {
        [self cwCmdHdwQueryAccountInfo:CwHdwAccountInfoIntKeyPtr AccountId:accountId];
    }
    
    //check sync status
    if (syncAccNameFlag[account.accId] && syncAccBalanceFlag[account.accId] && syncAccBlockAmountFlag[account.accId] && syncAccExtPtrFlag[account.accId] && syncAccIntPtrFlag[account.accId]) {
        // && syncAccExtAddress[account.accId] == account.extKeyPointer-1 && syncAccIntAddress[account.accId] == account.intKeyPointer-1
        
        //call delegate
        if ([self.delegate respondsToSelector:@selector(didGetAccountInfo:)]) {
            [self.delegate didGetAccountInfo:account.accId];
        }
        /*
         if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
         [self.delegate didCwCardCommand];
         }*/
    }
}

-(void) getAccountAddresses: (NSInteger) accountId;
{
    //get account from dictionary
    CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", accountId]];
    
    if (account==nil) {
        return;
    }
    
    //get external addresses
    syncAccExtAddress[accountId]=YES;
    for (int i=0; i<account.extKeyPointer; i++)
        [self getAddressInfo:accountId KeyChainId: CwAddressKeyChainExternal KeyId: i];
    
    //get internal addresses
    syncAccIntAddress[accountId]=YES;
    for (int i=0; i<account.intKeyPointer; i++)
        [self getAddressInfo:accountId KeyChainId: CwAddressKeyChainInternal KeyId: i];
    
    if (syncAccExtAddress[accountId] && syncAccIntAddress[accountId]) {
        
        //call delegate
        if ([self.delegate respondsToSelector:@selector(didGetAccountAddresses:)]) {
            [self.delegate didGetAccountAddresses: account.accId];
        }
        if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
            [self.delegate didCwCardCommand];
        }
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

-(BOOL) enableGenAddressWithAccountId:(NSInteger)accId
{
    CwAccount *acc= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", accId]];
    
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
    CwAccount *acc= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", accId]];
    NSInteger accPtr[5][2];
    
    //if it going to gen an internal address, use a address have no trx yet
    /*
    if (keyChainId==CwAddressKeyChainInternal) {
        for (int i=0; i<account.intKeyPointer; i++) {
            CwAddress *addr = account.intKeys[i];
            if (addr.historyTrx==nil || addr.historyTrx.count==0) {
                //no transactions yet
                if ([self.delegate respondsToSelector:@selector(didGenAddress:)]) {
                    [self.delegate didGenAddress:addr];
                }
                return;
            }
        }
    }*/
    
    if (keyChainId==CwAddressKeyChainExternal) {
        //check if there are 20 empty addresses
        for (int i=0; i<acc.extKeyPointer; i++) {
            //check transactions of each keys
            CwAddress *addr = acc.extKeys[i];
            
            if (addr.historyTrx.count>0) {
                //clear the counter
                accPtr[accId][CwAddressKeyChainExternal]=-1;
            }
            
            if (addr.historyTrx.count==0) {
                if (accPtr[accId][CwAddressKeyChainExternal]==-1)
                    accPtr[accId][CwAddressKeyChainExternal]=addr.keyId;
            }
        }
        
        //gen address if the empty address < CwHdwRecoveryAddressWindow
        if (accPtr[accId][CwAddressKeyChainExternal]==-1 || acc.extKeyPointer-accPtr[accId][CwAddressKeyChainExternal]<CwHdwRecoveryAddressWindow)
            [self cwCmdHdwGetNextAddress: keyChainId AccountId: accId];
        else {
            //no transactions yet
            CwAddress *addr = acc.extKeys[acc.extKeyPointer-1];
            if ([self.delegate respondsToSelector:@selector(didGenAddress:)]) {
                [self.delegate didGenAddress:addr];
            }
            if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
                [self.delegate didCwCardCommand];
            }
            return;
        }
    } else if (keyChainId==CwAddressKeyChainInternal) {
        //check if there are 20 empty addresses
        for (int i=0; i<acc.intKeyPointer; i++) {
            //check transactions of each keys
            CwAddress *addr = acc.intKeys[i];
            
            if (addr.historyTrx.count>0) {
                //clear the counter
                accPtr[accId][CwAddressKeyChainInternal]=-1;
            }
            
            if (addr.historyTrx.count==0) {
                if (accPtr[accId][CwAddressKeyChainInternal]==-1)
                    accPtr[accId][CwAddressKeyChainInternal]=addr.keyId;
            }
        }
        
        //gen address if the empty address < CwHdwRecoveryAddressWindow
        if (accPtr[accId][CwAddressKeyChainInternal] == -1 || acc.intKeyPointer-accPtr[accId][CwAddressKeyChainInternal]<CwHdwRecoveryAddressWindow)
            [self cwCmdHdwGetNextAddress: keyChainId AccountId: accId];
        else {
            //no transactions yet
            CwAddress *addr = acc.intKeys[acc.intKeyPointer-1];
            if ([self.delegate respondsToSelector:@selector(didGenAddress:)]) {
                [self.delegate didGenAddress:addr];
            }
            if ([self.delegate respondsToSelector:@selector(didCwCardCommand)]) {
                [self.delegate didCwCardCommand];
            }
            return;
        }
    }
}

-(void) getAddressInfo: (NSInteger)accountId KeyChainId: (NSInteger) keyChainId KeyId: (NSInteger) keyId; //didGenNextAddress
{
    //get account from dictionary
    CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", accountId]];
    
    if (keyChainId==CwAddressKeyChainExternal ) {
        //get address
        if (((CwAddress *)account.extKeys[keyId]).address==nil || [((CwAddress *)account.extKeys[keyId]).address isEqualToString:@""]) {
            syncAccExtAddress[accountId]=NO;
            [self cwCmdHdwQueryAccountKeyInfo:CwHdwAccountKeyInfoAddress
                                   KeyChainId:CwAddressKeyChainExternal
                                    AccountId:accountId
                                        KeyId:keyId];
        }
        //get publickey
//        [self getAddressPublickey:accountId KeyChainId:CwAddressKeyChainExternal KeyId:keyId];
    } else if (keyChainId==CwAddressKeyChainInternal) {
        //get address
        if (((CwAddress *)account.intKeys[keyId]).address==nil || [((CwAddress *)account.intKeys[keyId]).address isEqualToString:@""]) {
            syncAccIntAddress[accountId]=NO;
            [self cwCmdHdwQueryAccountKeyInfo:CwHdwAccountKeyInfoAddress
                                   KeyChainId:CwAddressKeyChainInternal
                                    AccountId:accountId
                                        KeyId:keyId];
        }
        //get publickey
//        [self getAddressPublickey:accountId KeyChainId:CwAddressKeyChainInternal KeyId:keyId];
    }
}

-(void) getAddressPublickey: (NSInteger)accountId KeyChainId: (NSInteger) keyChainId KeyId: (NSInteger) keyId
{
    //get account from dictionary
    CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", accountId]];
    
    if (keyChainId==CwAddressKeyChainExternal ) {
        //get publickey
        if (((CwAddress *)account.extKeys[keyId]).publicKey==nil) {
            syncAccExtAddress[accountId]=NO;
            [self cwCmdHdwQueryAccountKeyInfo:CwHdwAccountKeyInfoPubKey
                                   KeyChainId:CwAddressKeyChainExternal
                                    AccountId:accountId
                                        KeyId:keyId];
        }
        
    } else if (keyChainId==CwAddressKeyChainInternal) {
        //get publickey
        if (((CwAddress *)account.intKeys[keyId]).publicKey==nil) {
            syncAccIntAddress[accountId]=NO;
            [self cwCmdHdwQueryAccountKeyInfo:CwHdwAccountKeyInfoPubKey
                                   KeyChainId:CwAddressKeyChainInternal
                                    AccountId:accountId
                                        KeyId:keyId];
        }
    }
}

//didPrepareTransaction
-(void) prepareTransaction:(int64_t)amount Address: (NSString *)recvAddress Change: (NSString *)changeAddress
{
    //end transaction if exists
    [self cwCmdTrxFinish];
    
    trxStatus = TrxStatusPrepare;
    
    //check unspends in the account
    CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", self.currentAccountId]];
    
    //check amount vs balance
    if (amount>account.balance) {
        if ([self.delegate respondsToSelector:@selector(didPrepareTransactionError:)]) {
            [self.delegate didPrepareTransactionError:@"Amount is lower then balance"];
        }
        return;
    }
    
    //check unspent tx
    if (account.unspentTxs==nil || account.unspentTxs.count==0) {
        if ([self.delegate respondsToSelector:@selector(didPrepareTransactionError:)]) {
            [self.delegate didPrepareTransactionError:@"No avaliable unspent transaction"];
        }
        return;
    }
    
    for (CwUnspentTxIndex *utx in [account unspentTxs])
    {
        NSMutableString *b = [NSMutableString stringWithFormat:@"%@\n",[utx tid]];
        [b appendFormat:@"%@",[[utx amount]BTC]];
        NSLog(@"%@", b);
    }
    
    //Generate UnsignedTx
    CwTx *unsignedTx;
    CwBtc *fee;
    [account genUnsignedTxToAddrByAutoCoinSelection:recvAddress change: changeAddress amount:[CwBtc BTCWithSatoshi:[NSNumber numberWithLongLong:amount]] unsignedTx:&unsignedTx fee:&fee];
    
    //check unsigned tx
    if (unsignedTx==nil) {
        if ([self.delegate respondsToSelector:@selector(didPrepareTransactionError:)]) {
            [self.delegate didPrepareTransactionError:@"At least 1 confirmation needed before sending out."];
        }
        return;
    }
    
    //print IN and OUT of the tx
    for(CwTxin *txin in [unsignedTx inputs])
    {
        NSLog(@"in :  %@ n:%ld %@", [txin addr], txin.n, [[txin amount]BTC]);
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
    //if (trxStatus == TrxStatusGetBtn) {
    for (int i=0; i<currUnsignedTx.inputs.count; i++) {
        [self cwCmdTrxSign:i];
    }
    //}
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
    [self cwCmdExGetOtp];
}

-(void) exSessionInit: (NSData *)svrChlng
{
    [self cwCmdExSessionInit:svrChlng];
}

-(void) exSessionEstab: (NSData *)svrResp
{
    [self cwCmdExSessionEstab:svrResp];
}

-(void) exSessionLogout
{
    [self cwCmdExSessionLogout];
}

-(void) exBlockInfo: (NSData *)okTkn;
{
    [self cwCmdExBlockInfo:okTkn];
}

-(void) exBlockBtc: (NSInteger)trxId AccId: (NSInteger)accId Amount: (int64_t)amount Mac1: (NSData *)mac1 Nonce: (NSData*)nonce
{
    [self cwCmdExBlockBtc:trxId AccId:accId Amount:amount Mac1:mac1 Nonce:nonce];
}

-(void) exBlockCancel: (NSInteger)trxId OkTkn: (NSData *)okTkn EncUblkTkn: (NSData *)encUblkTkn Mac1: (NSData *)mac1 Nonce: (NSData*)nonce
{
    [self cwCmdExBlockCancel:trxId OkTkn:okTkn EncUblkTkn:encUblkTkn Mac1:mac1 Nonce:nonce];
}

-(void) exTrxSignLogin: (NSInteger)trxId OkTkn:(NSData *)okTkn EncUblkTkn:(NSData *)encUblkTkn AccId: (NSInteger)accId DealAmount: (int64_t)dealAmount Mac: (NSData *)mac
{
    [self cwCmdExTrxSignLogin:trxId OkTkn:okTkn EncUblkTkn:encUblkTkn AccId:accId DealAmount:dealAmount Mac:mac];
}

-(void) exTrxSignPrepare: (NSInteger)inId TrxHandle:(NSData *)trxHandle AccId: (NSInteger)accId KcId: (NSInteger)kcId KId: (NSInteger)kId Out1Addr: (NSData*) out1Addr Out2Addr:(NSData*) out2Addr SigMtrl: (NSData *)sigMtrl Mac: (NSData *)mac
{
    [self cwCmdExTrxSignPrepare:inId TrxHandle:trxHandle AccId:accId KcId:kcId KId:kId Out1Addr:out1Addr Out2Addr:out2Addr SigMtrl:sigMtrl Mac:mac];
}

-(void) exTrxSignLogout: (NSInteger)inId TrxHandle:(NSData *)trxHandle Nonce: (NSData *)nonce
{
    [self cwCmdExTrxSignLogout:inId TrxHandle:trxHandle Nonce:nonce];
}


#pragma mark - BCDC Functions
#pragma mark BCDC functions - Basic
- (NSInteger) cwCmdGetModeState
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityExclusive;
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

#pragma mark BCDC functions - ReInit
/*
 //Init Commands
 CwCmdIdInitSetData      = 0xA0,
 CwCmdIdInitConfirm      = 0xA2,
 CwCmdIdInitVmkChlng     = 0xA3,
 CwCmdIdInitBackInit     = 0xA4,
 */

- (NSInteger) CwCmdInitSetData: (NSInteger)initId Data:(NSData *) data PreHostId:(NSInteger)preHostId
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //se_init_set_data
    //80 A0 [IDID] [PRID]  [LC] [INITDATA] [IDHASH]
    
    //[IDID]
    //Init data ID
    //0: Default User PIN hash (32 bytes)
    //1: PUK (32 bytes)
    //2: SEMK (32 bytes)
    //3: Card ID (8 bytes)
    //4: OTPK (32 bytes)
    //5: SMK (32 bytes)
    //6: Pre-reg host description (64 bytes)  (1.4.5.9 only)
    //7: Pre-reg host OTP key (32 bytes)  (1.4.5.9 only)
    //INITDATA Init data (variable length)
    //IDHASH SHA256 value of INITDATA (32 bytes)
    
    //output:
    //none
    
    Byte out[96]; //max length is 64
    memcpy(out, [data bytes], data.length);
    
    CC_SHA256([data bytes], (int)data.length, out+data.length);
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdInitSetDataCLA;
    cmd.cmdId = CwCmdIdInitSetData;
    cmd.cmdP1 = initId;
    cmd.cmdP2 = preHostId;
    cmd.cmdInput =[NSData dataWithBytes:out length:data.length+32];
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) CwCmdInitConfirm
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //none
    
    //output:
    //none
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdInitConfirmCLA;
    cmd.cmdId = CwCmdIdInitConfirm;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) CwCmdInitVmkChlng
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input:
    //none
    
    //output:
    //vmkChlng 16B
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdInitVmkChlngCLA;
    cmd.cmdId = CwCmdIdInitVmkChlng;
    cmd.cmdP1 = 0;
    cmd.cmdP2 = 0;
    cmd.cmdInput = nil;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) CwCmdInitBackInit
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    
    //input
    //vmkResponse: 32B
    
    //output:
    //none
    
    Byte vmkResponse[16];
    unsigned long numBytesEncrypted;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                                          TEST_VMK, kCCKeySizeAES256,
                                          nil /* initialization vector (optional) */,
                                          [vmkChallenge bytes], vmkChallenge.length, /* input */
                                          vmkResponse, sizeof(vmkResponse), /* output */
                                          &numBytesEncrypted);
    if (cryptStatus != kCCSuccess)
    {
        NSLog(@"CwCmdIdInitBackInit Calculate Response Error (%d)", cryptStatus);
    }
    
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdInitBackInitCLA;
    cmd.cmdId = CwCmdIdInitBackInit;
    cmd.cmdP1 = self.hostId;
    cmd.cmdP2 = 0;
    cmd.cmdInput = [NSData dataWithBytes:vmkResponse length:16];;
    
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
    cmd.cmdP1 = self.hostId;
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
    cmd.cmdP1 = self.hostId;
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
    if (self.securityPolicy_OtpEnable)
        sp[0]=sp[0]|CwSecurityPolicyMaskOtp;
    if (self.securityPolicy_BtnEnable)
        sp[0]=sp[0]|CwSecurityPolicyMaskBtn;
    if (self.securityPolicy_DisplayAddressEnable)
        sp[0]=sp[0]|CwSecurityPolicyMaskAddress;
    if (self.securityPolicy_WatchDogEnable)
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
    if (self.securityPolicy_OtpEnable)
        sp[0]=sp[0]|CwSecurityPolicyMaskOtp;
    if (self.securityPolicy_BtnEnable)
        sp[0]=sp[0]|CwSecurityPolicyMaskBtn;
    if (self.securityPolicy_DisplayAddressEnable)
        sp[0]=sp[0]|CwSecurityPolicyMaskAddress;
    if (self.securityPolicy_WatchDogEnable)
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
    cmd.cmdPriority = CwCardCommandPriorityNone;
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
    //P1: keyInfoId 1B (00 address25B, 01 publickey 64B)
    //P2: keyChainId 1B
    //accountId 4B
    //keyId 4B
    
    //output
    //keyInfo
    //  address 25B
    //  publicKey 64B
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

- (NSInteger) cwCmdExGetOtp
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
    cmd.cmdP1 = 0;
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
    cmd.cmdPriority = CwCardCommandPriorityNone;
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
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput = [[NSMutableData alloc] init];
    int64_t amount_bn; //big endian of amount
    
    //input:
    //trxId 4B
    //accId 4B little-endian
    //amount: 8B big-endian
    //mac1: 32B mac of (trxId||accId||amount), key is XCHS_SK
    //nonce: 16B nonce for block signature
    
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
    
    cmdInput = [NSMutableData dataWithBytes: &trxId length: 4];
    [cmdInput appendBytes: &accId length: 4];
    amount_bn = CFSwapInt64((int64_t)amount);
    [cmdInput appendBytes: &amount_bn length: 8];
    [cmdInput appendData: mac1];
    [cmdInput appendData: nonce];
    
    cmd.cmdInput = cmdInput;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdExBlockCancel: (NSInteger)trxId OkTkn: (NSData *)okTkn EncUblkTkn: (NSData *)encUblkTkn Mac1: (NSData *)mac1 Nonce: (NSData*)nonce
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
    
    cmdInput = [NSMutableData dataWithBytes: &trxId length: 4];
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


- (NSInteger) cwCmdExTrxSignPrepare: (NSInteger)inId TrxHandle:(NSData *)trxHandle AccId: (NSInteger)accId KcId: (NSInteger)kcId KId: (NSInteger)kId Out1Addr: (NSData*) out1Addr Out2Addr:(NSData*) out2Addr SigMtrl: (NSData *)sigMtrl Mac: (NSData *)mac
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput = [[NSMutableData alloc] init];
    int64_t amount_bn; //big endian of amount
    
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
    
    //prepare commands
    cmd.cmdPriority = CwCardCommandPriorityNone;
    cmd.cmdCla = CwCmdIdExTrxSignPrepareCLA;
    cmd.cmdId = CwCmdIdExTrxSignPrepare;
    cmd.cmdP1 = inId;
    cmd.cmdP2 = 0;
    
    cmdInput = [NSMutableData  dataWithBytes:[trxHandle bytes] length:4];
    [cmdInput appendBytes: &accId length: 4];
    [cmdInput appendBytes: &kcId length: 4];
    [cmdInput appendBytes: &kId length: 4];
    [cmdInput appendData: out1Addr];
    [cmdInput appendData: out2Addr];
    [cmdInput appendData: sigMtrl];
    [cmdInput appendData: mac];
    
    cmd.cmdInput = cmdInput;
    
    //add command to array
    [self cmdAdd: cmd];
    
    [self cmdProcessor];
    
    return CwCardRetSuccess;
}

- (NSInteger) cwCmdExTrxSignLogout: (NSInteger)inId TrxHandle:(NSData *)trxHandle Nonce: (NSData *)nonce
{
    CwCardCommand *cmd = [[CwCardCommand alloc] init];
    NSMutableData *cmdInput = [[NSMutableData alloc] init];
    int64_t amount_bn; //big endian of amount
    
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
        
#ifdef CW_SOFT_SIMU
        double delayInSeconds = 0.2;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            
            // code to be executed on main thread.If you want to run in another thread, create other queue
            [cwSoft processCwCardCommand:currentCmd];
            
            currentCmd.busy = NO;
            //Update CwCards
            [self updateCwCardByCommand:currentCmd];
            [self cmdProcessor];
            
        });
        
#else
        [self BLE_SendCmd:currentCmd];
#endif
        
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
            if (cmd.cmdResult==0x9000) {
                self.mode = data[0];
                self.state = data[1];
                if ([self.delegate respondsToSelector:@selector(didGetModeState)]) {
                    [self.delegate didGetModeState];
                }
            } else {
                NSLog(@"CwCmdIdGetModeState Error %04lX", (long)cmd.cmdResult);
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
            
            //Init Commands
        case CwCmdIdInitSetData:
            if (cmd.cmdResult==0x9000) {
            } else {
                NSLog(@"CwCmdIdInitSetData Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdInitConfirm:
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didReInitCw)]) {
                    [self.delegate didReInitCw];
                }
            } else {
                NSLog(@"CwCmdIdInitConfirm Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdInitVmkChlng:
            if (cmd.cmdResult==0x9000) {
                vmkChallenge = [NSData dataWithBytes:data length:16];
                [self CwCmdInitBackInit];
            } else {
                NSLog(@"CwCmdIdInitVmkChlng Error %04lX", (long)cmd.cmdResult);
            }
            break;
        case CwCmdIdInitBackInit:
            if (cmd.cmdResult==0x9000 || cmd.cmdResult==0x6601) {
                //set default pin
                Byte pinHash[CC_SHA256_DIGEST_LENGTH];
                CC_SHA256([[defaultPin dataUsingEncoding:NSUTF8StringEncoding] bytes], (CC_LONG)defaultPin.length, pinHash);
                
                [self CwCmdInitSetData:0 Data:[NSData dataWithBytes:pinHash length:sizeof(pinHash)] PreHostId:0];
                
                //set puk
                [self CwCmdInitSetData:1 Data:[NSData dataWithBytes:TEST_PUK length:sizeof(TEST_PUK)] PreHostId:0];
                
                //set semk keys
                [self CwCmdInitSetData:2 Data:[NSData dataWithBytes:TEST_XCHSSEMK length:sizeof(TEST_XCHSSEMK)] PreHostId:0];
                
                //set cardId
                [self CwCmdInitSetData:3 Data: [initCardId dataUsingEncoding:NSUTF8StringEncoding] PreHostId:0];
                
                //set otpk keys
                [self CwCmdInitSetData:4 Data:[NSData dataWithBytes:TEST_XCHSOTPK length:sizeof(TEST_XCHSOTPK)] PreHostId:0];
                
                //set smk keys
                [self CwCmdInitSetData:5 Data:[NSData dataWithBytes:TEST_XCHSSMK length:sizeof(TEST_XCHSSMK)] PreHostId:0];
                
                //set pre-reg host description
                [self CwCmdInitSetData:6 Data:[NSData dataWithBytes:PreHostDesc0 length:sizeof(PreHostDesc0)] PreHostId:0];
                [self CwCmdInitSetData:6 Data:[NSData dataWithBytes:PreHostDesc1 length:sizeof(PreHostDesc1)] PreHostId:1];
                [self CwCmdInitSetData:6 Data:[NSData dataWithBytes:PreHostDesc2 length:sizeof(PreHostDesc2)] PreHostId:2];
                [self CwCmdInitSetData:6 Data:[NSData dataWithBytes:PreHostDesc3 length:sizeof(PreHostDesc3)] PreHostId:3];
                [self CwCmdInitSetData:6 Data:[NSData dataWithBytes:PreHostDesc4 length:sizeof(PreHostDesc4)] PreHostId:4];
                [self CwCmdInitSetData:6 Data:[NSData dataWithBytes:PreHostDesc5 length:sizeof(PreHostDesc5)] PreHostId:5];
                [self CwCmdInitSetData:6 Data:[NSData dataWithBytes:PreHostDesc6 length:sizeof(PreHostDesc6)] PreHostId:6];
                
                //set pre-reg host otp key
                [self CwCmdInitSetData:7 Data:[NSData dataWithBytes:PreHostOtpKey0 length:sizeof(PreHostOtpKey0)] PreHostId:0];
                [self CwCmdInitSetData:7 Data:[NSData dataWithBytes:PreHostOtpKey1 length:sizeof(PreHostOtpKey1)] PreHostId:1];
                [self CwCmdInitSetData:7 Data:[NSData dataWithBytes:PreHostOtpKey2 length:sizeof(PreHostOtpKey2)] PreHostId:2];
                [self CwCmdInitSetData:7 Data:[NSData dataWithBytes:PreHostOtpKey3 length:sizeof(PreHostOtpKey3)] PreHostId:3];
                [self CwCmdInitSetData:7 Data:[NSData dataWithBytes:PreHostOtpKey4 length:sizeof(PreHostOtpKey4)] PreHostId:4];
                [self CwCmdInitSetData:7 Data:[NSData dataWithBytes:PreHostOtpKey5 length:sizeof(PreHostOtpKey5)] PreHostId:5];
                [self CwCmdInitSetData:7 Data:[NSData dataWithBytes:PreHostOtpKey6 length:sizeof(PreHostOtpKey6)] PreHostId:6];
                
                //confirm init after sets
                [self CwCmdInitConfirm];
            } else {
                NSLog(@"CwCmdIdInitBackInit Error %04lX", (long)cmd.cmdResult);
            }
            break;
            
            //Auth Commands
            //Authentication Commands
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
                self.hostId = data[0];
                self.hostConfirmStatus = data[1];
                
                KeychainItemWrapper *keychain =
                [[KeychainItemWrapper alloc] initWithIdentifier:self.cardId accessGroup:nil];
                
                //store OTP in key chain
                [keychain setObject:self.hostOtp forKey:(id)CFBridgingRelease(kSecAttrService)];
                
                if ([self.delegate respondsToSelector:@selector(didConfirmHost)]) {
                    [self.delegate didConfirmHost];
                }
                
            } else {
                self.hostId = -1;
                self.hostConfirmStatus = -1;
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
            }
            break;
        case CwCmdIdBindLogin:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
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
            if (cmd.cmdResult==0x9000) {
                
            } else {
                NSLog(@"CwCmdIdBindLogout Error %04lX", (long)cmd.cmdResult);
            }
            if ([self.delegate respondsToSelector:@selector(didLogoutHost)]) {
                [self.delegate didLogoutHost];
            }
            break;
        case CwCmdIdBindFindHostId:
            //output
            //hostId 1B
            //confirm 1B
            
            if (cmd.cmdResult==0x9000) {
                if (data[0]>=0 && data[0]<=2) {
                    self.hostId = data[0];
                    self.hostConfirmStatus = data[1];
                } else {
                    self.hostId = -1;
                    self.hostConfirmStatus = -1;
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
                    self.securityPolicy_OtpEnable=YES;
                else
                    self.securityPolicy_OtpEnable=NO;
                
                if (data[0] & CwSecurityPolicyMaskBtn)
                    self.securityPolicy_BtnEnable=YES;
                else
                    self.securityPolicy_BtnEnable=NO;
                
                if (data[0] & CwSecurityPolicyMaskWatchDog)
                    self.securityPolicy_WatchDogEnable=YES;
                else
                    self.securityPolicy_WatchDogEnable=NO;
                
                if (data[0] & CwSecurityPolicyMaskAddress)
                    self.securityPolicy_DisplayAddressEnable=YES;
                else
                    self.securityPolicy_DisplayAddressEnable=NO;
                
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
            }
            
            break;
            
            
            //HD Wallet Commands
        case CwCmdIdHdwInitWallet:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                syncHdwStatusFlag = YES;
                self.hdwStatus = CwHdwStatusActive;
                
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
                self.hdwStatus = CwHdwStatusWaitConfirm;
                
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
                self.hdwStatus = CwHdwStatusActive;
                
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
                    case CwHdwInfoStatus:
                        self.hdwStatus = data[0];
                        syncHdwStatusFlag = YES;
                        
                        if ([self.delegate respondsToSelector:@selector(didGetCwHdwStatus)]) {
                            [self.delegate didGetCwHdwStatus];
                        }
                        
                        if (self.hdwStatus == CwHdwStatusActive) {
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
                        self.hdwAcccountPointer = *(int32_t *)data;
                        syncHdwAccPtrFlag = YES;
                        
                        //get account info
                        //[self getAccounts];
                        
                        /*
                         //get account keyspointers
                         for (int i=0; i<self.hdwAcccountPointer; i++) {
                            [self cwCmdHdwQueryAccountInfo:CwHdwAccountInfoExtKeyPtr AccountId:i];
                            [self cwCmdHdwQueryAccountInfo:CwHdwAccountInfoIntKeyPtr AccountId:i];
                         }*/
                        
                        for (int i=0; i<self.hdwAcccountPointer; i++) {
                            //get account from dictionary
                            CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)i]];
                            
                            if (account==nil) {
                                account = [[CwAccount alloc] init];
                                account.accId = i;
                                account.accName = @"";
                                account.balance = 0;
                                account.blockAmount = 0;
                                account.extKeyPointer = 0;
                                account.intKeyPointer = 0;
                                
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
                account.balance = 0;
                account.extKeyPointer = 0;
                account.intKeyPointer = 0;
                
                [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)account.accId]];
                
                self.currentAccountId = account.accId;
                
                self.hdwAcccountPointer = account.accId+1;
                
                syncHdwAccPtrFlag = YES;
                syncAccNameFlag[account.accId] = YES;
                syncAccBalanceFlag[account.accId] = YES;
                syncAccBlockAmountFlag[account.accId] = YES;
                syncAccExtPtrFlag[account.accId] = YES;
                syncAccIntPtrFlag[account.accId] = YES;
                
                if ([self.delegate respondsToSelector:@selector(didNewAccount:)]) {
                    [self.delegate didNewAccount:account.accId];
                }
                
                if ([self.delegate respondsToSelector:@selector(didGetAccountInfo:)]) {
                    [self.delegate didGetAccountInfo: account.accId];
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
                CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                
                switch (cmd.cmdP1) {
                    case CwHdwAccountInfoName:
                        //bytes to NSString
                        account.accName = [[NSString alloc] initWithBytes:data length:strlen((char *)(data)) encoding:NSUTF8StringEncoding];
                        syncAccNameFlag[account.accId] = YES;
                        break;
                    case CwHdwAccountInfoBalance:
                        //big-endian 8 bytes to NSInteger
                        account.balance = CFSwapInt64(*(int64_t *)data);
                        syncAccBalanceFlag[account.accId] = YES;
                        break;
                    case CwHdwAccountInfoBlockAmount:
                        //big-endian 8 bytes to NSInteger
                        account.blockAmount = CFSwapInt64(*(int64_t *)data);
                        syncAccBlockAmountFlag[account.accId] = YES;
                        break;
                    case CwHdwAccountInfoExtKeyPtr:
                        //little-endian 4 bytes to NSInteger
                        account.extKeyPointer = *(int32_t *)data;
                        for (NSInteger i=account.extKeys.count; i<account.extKeyPointer; i++) {
                            CwAddress *add = [[CwAddress alloc]init];
                            add.accountId = account.accId;
                            add.address = nil;
                            add.balance = 0;
                            add.keyChainId = CwAddressKeyChainExternal; //external
                            add.keyId = i;
                            
                            [account.extKeys addObject:add];
                        }
                        
                        syncAccExtPtrFlag[account.accId] = YES;
                        
                        break;
                    case CwHdwAccountInfoIntKeyPtr:
                        //little-endian 4 bytes to NSInteger
                        account.intKeyPointer = *(int32_t *)data;
                        for (NSInteger i=account.intKeys.count; i<account.intKeyPointer; i++) {
                            CwAddress *add = [[CwAddress alloc]init];
                            add.accountId = account.accId;
                            add.address = nil;
                            add.balance = 0;
                            add.keyChainId = CwAddressKeyChainInternal; //internal
                            add.keyId = i;
                            
                            [account.intKeys addObject:add];
                        }
                        
                        syncAccIntPtrFlag[account.accId] = YES;
                        
                        break;
                }
                
                [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                
                //if both pointers are synced, get the addresses/publickey
                /*if (syncAccExtPtrFlag[account.accId] && syncAccIntPtrFlag[account.accId]) {
                 [self getAccountAddresses: account.accId];
                 }*/
                //self.currentAccountId = account.accId;
                
                //check sync status
                if (syncAccNameFlag[account.accId] && syncAccBalanceFlag[account.accId] && syncAccBlockAmountFlag[account.accId] && syncAccExtPtrFlag[account.accId] && syncAccIntPtrFlag[account.accId]) {
                    // && syncAccExtAddress[account.accId] == account.extKeyPointer-1 && syncAccIntAddress[account.accId] == account.intKeyPointer-1
                    
                    //call delegate
                    if ([self.delegate respondsToSelector:@selector(didGetAccountInfo:)]) {
                        [self.delegate didGetAccountInfo:account.accId];
                    }
                }
                
                /*
                 if (accId+1 == self.hdwAcccountPointer) {
                 if ([self.delegate respondsToSelector:@selector(didGetAccounts)]) {
                 [self.delegate didGetAccounts];
                 }
                 }*/
                
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
                
                //get Account from directory
                CwAccount *account= [self.cwAccounts objectForKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                
                switch (cmd.cmdP1) {
                    case CwHdwAccountInfoName:
                        //bytes to NSString
                        account.accName = [[NSString alloc] initWithBytes:[accInfo bytes] length:strlen((char *)[accInfo bytes]) encoding:NSUTF8StringEncoding];
                        [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                        
                        syncAccNameFlag[account.accId] = YES;
                        if ([self.delegate respondsToSelector:@selector(didSetAccountName)]) {
                            [self.delegate didSetAccountName];
                            
                        }
                        break;
                    case CwHdwAccountInfoBalance:
                        //8B Big-endian to NSInteger
                        account.balance = CFSwapInt64(*(int64_t *)[accInfo bytes]);
                        [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                        
                        syncAccBalanceFlag[account.accId] = YES;
                        if ([self.delegate respondsToSelector:@selector(didSetAccountBalance)]) {
                            [self.delegate didSetAccountBalance];
                            
                        }
                        break;
                    case CwHdwAccountInfoExtKeyPtr:
                        //4B Little-endian to NSInteger
                        account.extKeyPointer = *(int32_t *)[accInfo bytes];
                        [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                        
                        syncAccExtPtrFlag[account.accId] = YES;
                        if ([self.delegate respondsToSelector:@selector(didSetAccountExtKeyPtr)]) {
                            [self.delegate didSetAccountExtKeyPtr];
                            
                        }
                        break;
                    case CwHdwAccountInfoIntKeyPtr:
                        //4B Little-endian to NSInteger
                        account.intKeyPointer = *(int32_t *)[accInfo bytes];
                        [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)accId]];
                        
                        syncAccIntPtrFlag[account.accId] = YES;
                        if ([self.delegate respondsToSelector:@selector(didSetAccountIntKeyPtr)]) {
                            [self.delegate didSetAccountIntKeyPtr];
                            
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
#ifdef CW_SOFT_SIMU
                addr.address = addresses[addr.keyId];
#endif
                
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
                Byte addrBytes[34];
                
                if (cmd.cmdP2 == CwAddressKeyChainExternal) {
                    if (account.extKeys.count>0)
                        addr = account.extKeys[keyId];
                } else if (cmd.cmdP2 == CwAddressKeyChainInternal) {
                    if (account.intKeys.count>0)
                        addr = account.intKeys[keyId];
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
                        
#ifdef CW_SOFT_SIMU
                        addr.address = addresses[keyId];
#endif
                        /*
                         int64_t balance;
                         [btcNet getBalanceByAddr:addr.address balance: &balance];
                         addr.balance = balance;
                         
                         {
                         NSMutableArray *htx;
                         
                         [btcNet getHistoryTxsByAddr:addr.address txs: &htx];
                         addr.historyTrx = htx;
                         }
                         */
                        
                        break;
                        
                    case CwAddressInfoPublicKey:
                        //Address
                        //64B Binary
                        addr.publicKey = [NSData dataWithBytes:data length:64];
                        
                        break;
                }
                
                if (addr.keyChainId == CwAddressKeyChainExternal) {
                    account.extKeys[keyId] = addr;
                } else if (addr.keyChainId == CwAddressKeyChainInternal) {
                    account.intKeys[keyId] = addr;
                }
                
                [self.cwAccounts setObject: account forKey: [NSString stringWithFormat: @"%ld", (long)addr.accountId]];
                
                if (cmd.cmdP1 == CwAddressInfoAddress) {
                    if ([self.delegate respondsToSelector:@selector(didGetAddressInfo)]) {
                        [self.delegate didGetAddressInfo];
                    }
                    
                    //if all addresses are synced
                    syncAccExtAddress[accId] = YES;
                    for (int i=0; i<account.extKeyPointer; i++) {
                        addr = account.extKeys[i];
                        if (addr.address==nil) {
                            syncAccExtAddress[accId] = NO;
                            break;
                        }
                    }
                    syncAccIntAddress[accId] = YES;
                    for (int i=0; i<account.intKeyPointer; i++) {
                        addr = account.intKeys[i];
                        if (addr.address==nil) {
                            syncAccIntAddress[accId] = NO;
                            break;
                        }
                    }
                    
                    if (syncAccExtAddress[accId] && syncAccIntAddress[accId]) {
                        if ([self.delegate respondsToSelector:@selector(didGetAccountAddresses:)]) {
                            [self.delegate didGetAccountAddresses: account.accId];
                        }
                    }
                }
                
            } else{
                NSLog(@"CwCmdIdHdwQueryAccountKeyInfo Error %04lX", (long)cmd.cmdResult);
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
                
                if (self.securityPolicy_OtpEnable==YES) {
                    trxStatus=TrxStatusWaitOtp;
                    currentCmd.busy=NO;
                    [self BLE_ReadStatus];
                } else if (self.securityPolicy_BtnEnable==YES) {
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
                if (self.securityPolicy_BtnEnable) {
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
                if ([self.delegate respondsToSelector:@selector(didVerifyOtpError)]) {
                    [self.delegate didVerifyOtpError];
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
                        
                        NSData *scriptSig = [NSData dataWithBytes:"" length:0];
                        [account genScriptSig:txin.signature pubKey:txin.pubKey scriptSig:&scriptSig];
                        ((CwTxin *)(currUnsignedTx.inputs[i])).scriptPub = scriptSig;
                        [sigs addObject: scriptSig];
                    }
                    
                    [account genRawTxData:currUnsignedTx scriptSigs:sigs];
                    
                    //publish to Network
                    NSData *parseResult;
                    
                    CwBtcNetWork *btcNet = [CwBtcNetWork sharedManager];
                    [btcNet decode:currUnsignedTx result:&parseResult];
                    NSLog(@"%@",parseResult);
                    
                    [btcNet publish:currUnsignedTx result:&parseResult];
                    NSLog(@"%@",parseResult);
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
                        //call success delegate
                        if ([self.delegate respondsToSelector:@selector(didSignTransaction)]) {
                            [self.delegate didSignTransaction];
                        }
                    }
                    
                    [self cwCmdTrxFinish];
                }
                
            } else {
                NSLog(@"CwCmdIdTrxSign Error %04lX", (long)cmd.cmdResult);
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
                exOtp = [[NSString alloc] initWithBytes:data length:strlen((char *)(data)) encoding:NSUTF8StringEncoding];
                
                if ([self.delegate respondsToSelector:@selector(didExGetOtp:)]) {
                    [self.delegate didExGetOtp:exOtp];
                }
            } else {
                NSLog(@"CwCmdIdExGetOtp Error %04lX", (long)cmd.cmdResult);
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
                
            } else {
                NSLog(@"CwCmdIdExSessionInit Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
            
        case CwCmdIdExSessionEstab:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                if ([self.delegate respondsToSelector:@selector(didExSessionEstab)]) {
                    [self.delegate didExSessionEstab];
                }
            } else {
                NSLog(@"CwCmdIdExSessionEstab Error %04lX", (long)cmd.cmdResult);
            }
            
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
            } else {
                NSLog(@"CwCmdIdExBlockInfo Error %04lX", (long)cmd.cmdResult);
            }
            
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
            } else {
                NSLog(@"CwCmdIdExBlockBtc Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
            
        case CwCmdIdExBlockCancel:
            //output:
            //ublkSig: 32B block signature, mac of (cardId||uid||trxId||accId||amount||nonce||nonceSe), key is XCHS_SMK
            //MAC2: 32B mac of (ublkSig), key is XCHS_SK
            //nonceSe: 16B nonce generated by SE
            if (cmd.cmdResult==0x9000) {
                NSLog(@"trxStatus = %ld", (long)trxStatus);
            } else {
                NSLog(@"CwCmdIdExBlockCancel Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
            
        case CwCmdIdExTrxSignLogin:
            //output:
            //trHandle 4B
            if (cmd.cmdResult==0x9000) {
                NSLog(@"trxStatus = %ld", (long)trxStatus);
            } else {
                NSLog(@"CwCmdIdExTrxSignLogin Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
            
        case CwCmdIdExTrxSignPrepare:
            //output:
            //none
            if (cmd.cmdResult==0x9000) {
                NSLog(@"trxStatus = %ld", (long)trxStatus);
            } else {
                NSLog(@"CwCmdIdExTrxSignPrepare Error %04lX", (long)cmd.cmdResult);
            }
            
            break;
            
        case CwCmdIdExTrxSignLogout:
            //output:
            //sigRcpt 32B mac of (cardId||uid||trxId||accId||dealAmount||numInputs||out1Addr||out2Addr||nonce||nonceSe), key is XCHS_SMK
            //mac: 32B mac of (sigRcpt), key is XCHS_SK
            //nonceSe: 16B
            if (cmd.cmdResult==0x9000) {
                NSLog(@"trxStatus = %ld", (long)trxStatus);
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
    
    if (scale > self.securityPolicy_WatchDogScale) {
        if ([self.delegate respondsToSelector:@selector(didWatchDogAlert:)])
            [self.delegate didWatchDogAlert:scale];
    }
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

