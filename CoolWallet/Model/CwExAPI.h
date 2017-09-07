//
//  CwExAPI.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/27.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//


#ifndef CwExAPI_h
#define CwExAPI_h

#define ExBaseUrl               @"http://xsm.coolbitx.com:8080/api/res/cw"
#define ExSession               ExBaseUrl@"/session/%@"
#define ExSessionLogout         ExBaseUrl@"/session/logout"
#define ExSyncCardInfo          ExBaseUrl@"/%@"
#define ExSyncAccountInfo       ExSyncCardInfo@"/%ld"
#define ExGetPendingOrders      ExBaseUrl@"/pending/%@" // Url: /pending/:CWID(/:orderId)
#define ExGetTrxInfo            ExBaseUrl@"/trxinfo/%@"
#define ExGetTrxPrepareBlocks   ExBaseUrl@"/trxblks/%@"  // Url: /trxblks/:orderId
#define ExTrx                   ExBaseUrl@"/trx/%@"
#define ExTrxOrderBlock         ExBaseUrl@"/trx/%@/%@" // Url: /trx/:orderId/:otp
#define ExCancelOrder           ExBaseUrl@"/order/%@"
#define ExWriteOKToken          ExBaseUrl@"/oktoken/%@" // Url: /oktoken/:orderId
#define ExUnblockOrders         ExBaseUrl@"/unblock/%@"  // Url: /unblock/:orderId
#define ExOpenOrderCount        ExBaseUrl@"/open/count"
#define ExGetOrders             ExBaseUrl@"/cw/order/%@"

typedef NS_ENUM (int, ExSessionStatus) {
    ExSessionNone,
    ExSessionProcess,
    ExSessionLogin,
    ExSessionFail
};

typedef NS_ENUM (int, ExSiteErrorCode) {
    NotRegistered = 9000,
};

#endif /* CwExAPI_h */
