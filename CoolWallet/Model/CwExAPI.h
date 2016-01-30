//
//  CwExAPI.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/1/27.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//


#ifndef CwExAPI_h
#define CwExAPI_h

#define ExBaseUrl @"http://xsm.coolbitx.com:8080/api/res/cw"
#define ExSession ExBaseUrl@"/session/%@"
#define ExSessionLogout ExBaseUrl@"/session/logout"
#define ExGetMatchedOrders ExBaseUrl@"/pending/%@"
#define ExGetTrxInfo ExBaseUrl@"/trxinfo/%@"
#define ExGetTrxPrepareBlocks ExBaseUrl@"/trxblks"

typedef NS_ENUM (int, ExSessionStatus) {
    ExSessionNone,
    ExSessionProcess,
    ExSessionLogin,
    ExSessionFail
};

#endif /* CwExAPI_h */
