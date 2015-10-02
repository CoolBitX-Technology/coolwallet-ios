/***
 * [ Project     ] bcdc-se app 
 * [ Module      ] sha256 
 * [ Description ] SHA256 calculation 
 * [ Note        ] 
 */ 

#ifndef __SHA256_H__ 
#define __SHA256_H__ 

//#include "se_common.h" 
#include "types.h"

#define SHA256_LEN           32 
#define SHA256_DIGEST_SIZE   32 
#define SHA256_BLOCK_SIZE    64 
#define SHA256_PAD_SIZE      56 


/* Sha256 digest */
typedef struct sha256_ctx_s { 
	u4  buffLen;   /* in bytes          */
	u4  loLen;     /* length in bytes   */
	u4  hiLen;     /* length in bytes   */
	u4  digest[SHA256_DIGEST_SIZE / 4]; 
	u4  buffer[SHA256_BLOCK_SIZE  / 4]; 
} sha256_ctx_t; 


/*** 
 * [Function   ] sha256_init 
 * [Description] Initialize SHA256 calculation 
 * [Parameters ] 
 *       (out) ctx : SHA256 calculation context 
 * [Return     ] 0: success (Error code in sha256_err.h) 
 * [Note       ] None 
 */ 
int sha256_init( 
	OUT    sha256_ctx_t *ctx); 


/*** 
 * [Function   ] sha256_update 
 * [Description] Update message in SHA256 calculation 
 * [Parameters ] 
 *       (in ) ctx     : SHA256 calculation context 
 *       (in ) msg_len : Updated message length (in bytes) 
 *       (in ) msg     : Updated message 
 * [Return     ] 0: success (Error code in sha256_err.h) 
 * [Note       ] 
 *    -- ctx has to be initialized by sha256_init first, although it's not checked 
 *       in function 
 */ 
int sha256_update( 
	IN     sha256_ctx_t *ctx, 
	IN     SE_USIZ       msg_len, 
	IN     SE_BYTE      *msg); 


/*** 
 * [Function   ] sha256_final 
 * [Description] Finalize SHA256 calculation 
 * [Parameters ] 
 *       (in ) ctx     : SHA256 calculation context 
 *       (out) digest  : SHA256 digest calculation result (SHA256_LEN bytes) 
 * [Return     ] 0: success (Error code in sha256_err.h) 
 * [Note       ] 
 *    -- ctx has to be initialized by sha256_init first, although it's not checked 
 *       in function 
 */ 
int sha256_final ( 
	IN     sha256_ctx_t *ctx, 
	OUT    SE_BYTE      *digest); 



/*** 
 * [Function   ] sha256_calc 
 * [Description] SHA256 calculation 
 * [Parameters ] 
 *       (in ) msg_len : Message length (in bytes) 
 *       (in ) msg     : Message 
 *       (out) digest  : SHA256 digest calculation result (SHA256_LEN bytes) 
 * [Return     ] 0: success (Error code in sha256_err.h) 
 * [Note       ] None 
 */ 
int sha256_calc( 
	IN     SE_USIZ   msg_len, 
	IN     SE_BYTE  *msg, 
	OUT    SE_BYTE  *digest); 
	

/*** 
 * [Function   ] sha256_verify 
 * [Description] Verify SHA256 value 
 * [Parameters ] 
 *       (in ) msg_len : Message length (in bytes) 
 *       (in ) msg     : Message 
 *       (in ) digest  : SHA256 digest of message to be verified (SHA256_LEN bytes) 
 * [Return     ] 0: success (Error code in sha256_err.h) 
 * [Note       ] None 
 */ 
int sha256_verify( 
	IN     SE_USIZ   msg_len, 
	IN     SE_BYTE  *msg, 
	IN     SE_BYTE  *digest); 

#endif 
