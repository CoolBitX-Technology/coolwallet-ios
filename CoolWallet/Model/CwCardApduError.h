//
//  CwCardApduError.h
//  CwTest
//
//  Created by CP Hsiao on 2015/6/9.
//  Copyright (c) 2015年 CP Hsiao. All rights reserved.
//

#ifndef CwTest_CwCardApduError_h
#define CwTest_CwCardApduError_h

#define ERR_CMD_NOT_SUPPORT     0x6601    /* Command not supported */
#define ERR_MODE_ID             0x6602    /* Wrong mode ID */
#define ERR_LC                  0x6603    /* Wrong APDU LC */
#define ERR_TEST_FUNC_ID        0x6604    /* Wrong test function ID */
#define ERR_BCDC_TRX_STATE      0x6605    /* Wrong trx signing state */
#define ERR_TRX_VERIFY_OTP      0x6606    /* Trx OTP verification fail */
#define ERR_WALLET_INACTIVE     0x6607    /* Wallet is not active */
#define ERR_WALLET_ACTIVE       0x6608    /* Wallet is active */
#define ERR_WALLET_MISMATCH     0x6609    /* Wallet id mismatch */
#define ERR_WRONG_OUTID         0x660A    /* Wrong output id for trx_sign */
#define ERR_CDATA_TIMEOUT       0x660B    /* Waiting for cdata timeout (7816 interface only) */
#define ERR_NO_RESP             0x660C    /* No response data (7816 interface only) */
#define ERR_HASH_CHECK          0x660D    /* Fail to pass hash check */
#define ERR_WAADDR_CHECK        0x660E    /* Fail to pass wallet address check */
#define ERR_BCDC_INITSTATE      0x660F    /* Wrong BCDC init state */
#define ERR_BCDC_IDATAINFO      0x6610    /* Wrong input init data information */
#define ERR_BCDC_IDATASTATE     0x6611    /* Wrong init data state */
#define ERR_BCDC_PERSOSTATE     0x6612    /* Wrong BCDC perso state */
#define ERR_BCDC_PDATAINFO      0x6613    /* Wrong input perso data information */
#define ERR_BCDC_PDATASTATE     0x6614    /* Wrong perso data state */
#define ERR_DRNG_GEN_RAND       0x6615    /* DRNG module failed to generate random bytes */
#define ERR_BCDC_TRX_INID       0x6616    /* Wrong input ID */
#define ERR_NO_CHLNG            0x6617    /* No auth challenge generated */
#define ERR_LOCK                0x6618    /* Auth locked */
#define ERR_AUTHFAIL            0x6619    /* Auth fail, not locked yet */
#define ERR_AUTHLOCK            0x661A    /* Auth fail and locked */
#define ERR_NO_AUTH             0x661B    /* Not authed yet */
#define ERR_NO_LOCK             0x661C    /* Not locked */
#define ERR_TEST_SUBFUNC_ID     0x661D    /* Wrong test sub-function ID */
#define ERR_NO_CARDNAME         0x661E    /* No card name exists */
#define ERR_WALLET_ID           0x661F    /* Wrong wallet ID */
#define ERR_EWAINFO_ID          0x6620    /* Wrong export wallet info ID */
#define ERR_NO_CURRENCY         0x6621    /* No currency data exists */
#define ERR_TRX_INFOID          0x6622    /* Wrong trx context INFO ID */
#define ERR_WAPKG_ID            0x6623    /* Wrong wallet package ID */
#define ERR_INTER_MODULE        0x6624    /* Internal module error */
#define ERR_BAK_STATE           0x6625    /* Wrong backup status */
#define ERR_BAK_HANDLE          0x6626    /* Wrong backup handle */
#define ERR_WA_STATUS           0x6627    /* Wrong wallet status */
#define ERR_RES_STATE           0x6628    /* Wrong restore status */
#define ERR_RES_CHKSUM          0x6629    /* Wrong restore checksum */
#define ERR_RES_HANDLE          0x662A    /* Wrong restore handle */
#define ERR_RES_RSID            0x662B    /* Wrong restore seed ID */
#define ERR_BIND_HSTID          0x662C    /* Wrong binding host ID */
#define ERR_BIND_NOLOGIN        0x662D    /* Not in binding login state */
#define ERR_BIND_HSTSTAT        0x662E    /* Wrong host binding status */
#define ERR_BIND_LOGINSTAT      0x662F    /* Wrong host login status */
#define ERR_BIND_LOGIN          0x6630    /* Binding login fail */
#define ERR_HDW_STATUS          0x6631    /* Wrong HD wallet status */
#define ERR_HDW_NULEN           0x6632    /* Wrong number set length */
#define ERR_HDW_INFOID          0x6633    /* Wrong HDW info ID */
#define ERR_HDW_INFOLEN         0x6634    /* Wrong HDW info length */
#define ERR_HDW_ACCID           0x6635    /* Wrong HDW account ID */
#define ERR_HDW_ACCINFOID       0x6636    /* Wrong HDW account info ID */
#define ERR_HDW_KCID            0x6637    /* Wrong key chain ID */
#define ERR_HDW_KEYID           0x6638    /* Wrong key ID */
#define ERR_HDW_ACCINFOLEN      0x6639    /* Wrong account info length */
#define ERR_HDW_ACTVCODE        0x6640    /* Wrong activation code */
#define ERR_HDW_ACCPTR          0x6641    /* Wrong account pointer value */
#define ERR_HDW_OUTOFKEY        0x6642    /* Out of keys */
#define ERR_BIND_ALRDYNOHOST    0x6643    /* Already no host */
#define ERR_BIND_FIRST          0x6644    /* Wrong first flag */
#define ERR_BIND_HOSTFULL       0x6645    /* Full of hosts */
#define ERR_BIND_REGSTAT        0x6646    /* Wrong host registration status */
#define ERR_BIND_BRHANDLE       0x6647    /* Wrong brhandle */
#define ERR_BIND_REGRESP        0x6648    /* Wrong registration response */
#define ERR_FW_UPDATE_OTP       0x6649    
#define ERR_HDW_SUM             0x6653    /* Sum of number set error*/
//MCU Errors
#define ERR_MCU_CMD_NOT_ALLOW   0x6986
#define ERR_MCU_CMD_TIME_OUT    0x6984

#endif
