//
//  CwCard.j
//  CwTest
//
//  Created by CP Hsiao on 2014/11/27.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <RMMapper/RMMapper.h>
#import "NSObject+RMArchivable.h" 
#import "CwCardDelegate.h"
#import "CwAccount.h"

#define CwHdwRecoveryAddressWindow  5

#pragma mark - CwEnum
typedef NS_ENUM (NSInteger, CwCardMode) {
    CwCardModeInit = 0x00,
    CwCardModePerso = 0x01,
    CwCardModeNormal = 0x02,
    CwCardModeAuth = 0x03,
    CwCardModeLock = 0x04,
    CwCardModeError = 0x05,
    CwCardModeNoHost = 0x06,
    CwCardModeDisconn = 0x07
};

typedef NS_ENUM (NSInteger, CwCardRet) {
    CwCardRetSuccess = 0x00,
    CwCardRetBusy = 0x01,
    CwCardRetNeedInit = 0x02
};

typedef NS_ENUM (NSInteger, CwHdwStatus) {
    CwHdwStatusInactive = 0x00,
    CwHdwStatusWaitConfirm = 0x01,
    CwHdwStatusActive = 0x02
};

typedef NS_ENUM (NSInteger, CwFwUpdateStatus) {
    CwFwUpdateStatusSuccess = 0x00,
    CwFwUpdateStatusAuthFail = 0x01,
    CwFwUpdateStatusUpdateFail = 0x02,
    CwFwUpdateStatusCheckFail = 0x03,
};

@interface CwCard : NSObject <RMMapping>

@property (nonatomic, assign) id<CwCardDelegate> delegate;

#pragma mark - CwLowLevelProperties
@property NSString *bleName;
@property NSNumber *rssi;
@property BOOL connected;
@property CBPeripheral *peripheral;
@property NSDate *lastUpdate;

#pragma mark - CwProperties - Basic Info
@property NSNumber *mode;
@property NSNumber *state;
@property NSString *fwVersion;
@property NSString *uid;

#pragma mark - CwProperties - Host Info
@property NSString *devCredential; //Query and input from the UIDevice
@property NSNumber *hostId;
@property NSNumber *hostConfirmStatus;
@property NSString *hostOtp;

@property NSMutableDictionary *cwHosts;

#pragma mark - CwProperties - Securityp Policy
@property NSNumber *securityPolicy_OtpEnable;
@property NSNumber *securityPolicy_BtnEnable;
@property NSNumber *securityPolicy_DisplayAddressEnable;
@property NSNumber *securityPolicy_WatchDogEnable;
@property NSNumber *securityPolicy_WatchDogScale;

#pragma mark - CwProperties - Card Info
@property NSString *cardName;
@property NSString *cardId;
@property NSString *currId;
@property NSDecimalNumber *currRate;
@property NSNumber *cardFiatDisplay;

#pragma mark - CwProperties - HDW Info
@property NSNumber *hdwStatus;
@property NSString *hdwName;
@property NSNumber *hdwAcccountPointer;

@property NSMutableDictionary *cwAccounts;
@property NSInteger currentAccountId;

#pragma mark - Current Transaction Info
@property NSString *paymentAddress;
@property int64_t amount;
@property NSString *label;

#pragma mark - CwMethods

-(void) resetSe;
-(void) setDisplayAccount: (NSInteger) accId;

-(void) prepareService;

-(CwCard *) getCardInfoFromFile;
-(void) loadCwCardFromFile;
-(void) saveCwCardToFile;

-(void) syncFromCard;
-(void) syncToCard;

-(void) getModeState;
-(void) getCwInfo; //get CW infos include firmware version/uid/hostId, callback:didGetCwInfo

-(void) reInitCard: (NSString *) cardId Pin:(NSString *)pin;

-(void) registerHost: (NSString *)credential Description: (NSString*)description; //callback: didRegisterHost
-(void) confirmHost: (NSString *)otp; //callback: didConfirmHost
-(void) eraseCw: (BOOL) preserveHost Pin: (NSString *)pin NewPin: (NSString *) newPin; //callback: didEraseCw
-(void) loginHost; //callback: didLoginHost
-(void) logoutHost;

-(void) getHosts; //didGetHosts
-(void) approveHost: (NSInteger) hostId; //didApproveHost
-(void) removeHost: (NSInteger) hostId; //didRemoveHost

-(void) defaultPersoSecurityPolicy;
-(void) persoSecurityPolicy: (BOOL)otpEnable ButtonEnable: (BOOL)btnEnable DisplayAddressEnable: (BOOL) addEnable WatchDogEnable: (BOOL)wdEnable;

-(void) getSecurityPolicy;

-(void) setSecurityPolicy:  (BOOL)otpEnable ButtonEnable: (BOOL)btnEnable DisplayAddressEnable: (BOOL) addEnable WatchDogEnable: (BOOL)wdEnable;


-(void) getCwCardName;
-(void) setCwCardName:(NSString *)cardName;

-(void) getCwCurrRate;
-(void) setCwCurrRate:(NSDecimalNumber *)currRate;

-(void) getCwCardId;

-(void) getCwHdwInfo; //hdwStatus, hdwName, hdwAccountPointer
-(void) setCwHdwName: (NSString *)hdwName;

-(void) initHdw: (NSString *)hdwName BySeed: (NSString *)seed;      //didInitHdwBySeed
-(void) initHdw: (NSString *)hdwName ByCard: (NSInteger)seedLen;    //didInitHdwByCard
-(void) initHdwConfirm: (NSString *)sumOfSeeds;                     //didInitHdwConfirm

-(void) pinChlng;
-(void) pinAuth: (NSString *) pin;
-(void) pinChange: (NSString *) oldPin NewPing: (NSString*) newPin;
-(void) pinLogout;

-(void) getAccounts; //didGetAccounts
-(void) newAccount: (NSInteger) accountId Name: (NSString *)accountName;
-(void) getAccountInfo: (NSInteger) accountId;                                  //didGetAccountInfo
-(void) setAccount: (NSInteger) accountId Name:(NSString *)accountName;         //didSetAccountName
-(void) setAccount: (NSInteger) accountId Balance:(int64_t)balance;             //didSetAccountBalance
-(void) setAccount: (NSInteger) accountId ExtKeyPtr:(NSInteger)extKeyPtr;       //didSetAccountExtKeyPtr
-(void) setAccount: (NSInteger) accountId IntKeyPtr:(NSInteger)intKeyPtr;       //didSetAccountIntKeyPtr

-(void) getAccountAddresses: (NSInteger) accountId;
-(void) genAddress:  (NSInteger)accountId KeyChainId: (NSInteger) keyChainId; //didGenNextAddress, didGetAccountInfo
-(void) getAddressInfo: (NSInteger)accountId KeyChainId: (NSInteger) keyChainId KeyId: (NSInteger) keyId;
-(void) getAddressPublickey: (NSInteger)accountId KeyChainId: (NSInteger) keyChainId KeyId: (NSInteger) keyId;
-(BOOL) enableGenAddressWithAccountId:(NSInteger)accId;

-(void) prepareTransaction:(int64_t)amount Address: (NSString *)recvAddress Change: (NSString *)changeAddress; //didPrepareTransaction
-(void) verifyTransactionOtp: (NSString *)otp; //didVerifyOtp, didVerifyOtpError
-(void) signTransaction; //didSignTransaction
-(void) cancelTrancation; 

-(void) updateFirmwareWithOtp: (NSString *)blotp HexData: (NSData *)hexData; //didUpdateFirmwareProgress, didUpdateFirmwareDone

-(void) backToLoader: (NSString *)blotp;
-(void) backTo7816FromLoader;

-(void) genResetOtp;
-(void) verifyResetOtp: (NSString *)otp;
-(void) displayCurrency: (BOOL) option;

//Exchange Site Functions
-(void) exGetRegStatus;
-(void) exGetOtp;
-(void) exSessionInit: (NSData *)svrChlng withComplete:(void (^)(NSData *seResp, NSData *seChlng))complete withError:(void (^)(NSInteger errorCode))error;
-(void) exSessionEstab: (NSData *)svrResp withComplete:(void (^)(void))complete withError:(void (^)(NSInteger errorCode))error;
-(void) exSessionLogout;
-(void) exBlockInfo: (NSData *)okTkn;
-(void) exBlockBtc: (NSInteger)trxId AccId: (NSInteger)accId Amount: (int64_t)amount Mac1: (NSData *)mac1 Nonce: (NSData*)nonce;
-(void) exBlockCancel: (NSInteger)trxId OkTkn: (NSData *)okTkn EncUblkTkn: (NSData *)encUblkTkn Mac1: (NSData *)mac1 Nonce: (NSData*)nonce;
-(void) exTrxSignLogin: (NSInteger)trxId OkTkn:(NSData *)okTkn EncUblkTkn:(NSData *)encUblkTkn AccId: (NSInteger)accId DealAmount: (int64_t)dealAmount Mac: (NSData *)mac;
-(void) exTrxSignPrepare: (NSInteger)inId TrxHandle:(NSData *)trxHandle AccId: (NSInteger)accId KcId: (NSInteger)kcId KId: (NSInteger)kId Out1Addr: (NSData*) out1Addr Out2Addr:(NSData*) out2Addr SigMtrl: (NSData *)sigMtrl Mac: (NSData *)mac;
-(void) exTrxSignLogout: (NSInteger)inId TrxHandle:(NSData *)trxHandle Nonce: (NSData *)nonce;

-(void) cmdClear;

@end

