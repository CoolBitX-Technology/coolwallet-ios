//
//  CWBTCNetworkError.h
//  BCDC
//
//  Created by LIN CHIH-HUNG on 2014/8/28.
//  Copyright (c) 2014年 LIN CHIH-HUNG. All rights reserved.
//

typedef enum
{
    GETTRXBYACCT_BASE       ,
    GETTRXBYACCT_NETWORK    ,
    GETTRXBYACCT_JSON       ,
    GETTRXBYACCT_ALLTX      ,
    GETTRXBYACCT_UNSPENTTX  ,
} GetTransactionByAccountErr;

typedef enum
{
    GETBALANCEBYADDR_BASE       ,
    GETBALANCEBYADDR_NETWORK    ,
    GETBALANCEBYADDR_JSON       ,
} GetBalanceByAddrErr;


typedef enum
{
    REGNOTIFYBYADDR_BASE       ,
    REGNOTIFYBYADDR_NETWORK    ,
    REGNOTIFYBYADDR_JSON       ,
} RegisterNotifyByAddrErr;

typedef enum
{
    GETALLTXSBYADDR_BASE     ,
    GETALLTXSBYADDR_NETWORK  ,
    GETALLTXSBYADDR_JSON
} GetAllTxsByAddrErr;

typedef enum
{
    GETUNSPENTTXSBYADDR_BASE    ,
    GETUNSPENTTXSBYADDR_NETWORK ,
    GETUNSPENTTXSBYADDR_JSON    ,
} GetUnspentTxsByAddrErr;

typedef enum
{
    PUBLISH_BASE    ,
    PUBLISH_NETWORK ,
    PUBLISH_DOUBLE  ,
    PUBLISH_FORMAT
} PublishErr;

typedef enum
{
    GETCURR_BASE    ,
    GETCURR_NETWORK ,
    CETCURR_JSON
} GetCurrErr;

typedef enum
{
    DECODE_BASE
} DecodeErr;
