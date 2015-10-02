//
//  CwAccountError.h
//  CwTest
//
//  Created by Coolbitx on 2015/7/30.
//  Copyright (c) 2015年 CoolBitX Technology Ltd. All rights reserved.
//

#ifndef CwTest_CwAccountError_h
#define CwTest_CwAccountError_h


typedef enum
{
    SYNCFROMNETWORK_BASE,
    SYNCFROMNETWORK_BALANCE,
    SYNCFROMNETWORK_ALLTX,
    SYNCFROMNETWORK_UNSPENTTX
} SyncFromNetworkErr;

typedef enum
{
    SYNCFROMCARD_BASE,
    SYNCFROMCARD_FAIL
} SyncFromCardErr;

typedef enum
{
    SYNCTOCARD_BASE,
    SYNCTOCARD_FAIL
} SyncToCardErr;

typedef enum
{
    GENTX_BASE  ,
    GENTX_LESS
} GenTxErr;

typedef enum
{
    UNSPENTTXSSELECT_BASE ,
    UNSPENTTXSSELECT_LESS
} UnspentTxsSelectionErr;

typedef enum
{
    GENRAWTXDATA_BASE,
    GENRAWTXDATA_NOTSIGNEDTX
} GenRawTxDataErr;

typedef enum
{
    GENSCRIPTSIG_BASE
} GenScriptSigErr;

#endif
