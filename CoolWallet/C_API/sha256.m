/***
 * [ Project     ] bcdc-se app 
 * [ Module      ] sha256 
 * [ Description ] SHA256 calculation 
 * [ Note        ] 
 */ 

#include <string.h> 
#include "sha256.h" 
#include "sha256_err.h" 

/***************************************************************/ 
/***************** MACRO and TYPE definitions ******************/ 
/***************************************************************/ 

/* Byte order of "Processor" */ 
#define LITTLE_ENDIAN_ORDER 


/* Minimal value of x and y */ 
#define MIN(x, y)  \
	(((x) < (y)) ? (x) : (y))


#define Ch(x,y,z)       (z ^ (x & (y ^ z)))
#define Maj(x,y,z)      (((x | y) & z) | (x & y))
#define S(x, n)         rotrFixed(x, n)
#define R(x, n)         (((x)&0xFFFFFFFFU)>>(n))
#define Sigma0(x)       (S(x, 2) ^ S(x, 13) ^ S(x, 22))
#define Sigma1(x)       (S(x, 6) ^ S(x, 11) ^ S(x, 25))
#define Gamma0(x)       (S(x, 7) ^ S(x, 18) ^ R(x, 3))
#define Gamma1(x)       (S(x, 17) ^ S(x, 19) ^ R(x, 10))

/***************************************************************/ 
/********************** Global variables ***********************/ 
/***************************************************************/ 

/* Constant table K */ 
static const u4 K[64] = { 
	0x428A2F98L, 0x71374491L, 0xB5C0FBCFL, 0xE9B5DBA5L, 0x3956C25BL,
	0x59F111F1L, 0x923F82A4L, 0xAB1C5ED5L, 0xD807AA98L, 0x12835B01L,
	0x243185BEL, 0x550C7DC3L, 0x72BE5D74L, 0x80DEB1FEL, 0x9BDC06A7L,
	0xC19BF174L, 0xE49B69C1L, 0xEFBE4786L, 0x0FC19DC6L, 0x240CA1CCL,
	0x2DE92C6FL, 0x4A7484AAL, 0x5CB0A9DCL, 0x76F988DAL, 0x983E5152L,
	0xA831C66DL, 0xB00327C8L, 0xBF597FC7L, 0xC6E00BF3L, 0xD5A79147L,
	0x06CA6351L, 0x14292967L, 0x27B70A85L, 0x2E1B2138L, 0x4D2C6DFCL,
	0x53380D13L, 0x650A7354L, 0x766A0ABBL, 0x81C2C92EL, 0x92722C85L,
	0xA2BFE8A1L, 0xA81A664BL, 0xC24B8B70L, 0xC76C51A3L, 0xD192E819L,
	0xD6990624L, 0xF40E3585L, 0x106AA070L, 0x19A4C116L, 0x1E376C08L,
	0x2748774CL, 0x34B0BCB5L, 0x391C0CB3L, 0x4ED8AA4AL, 0x5B9CCA4FL,
	0x682E6FF3L, 0x748F82EEL, 0x78A5636FL, 0x84C87814L, 0x8CC70208L,
	0x90BEFFFAL, 0xA4506CEBL, 0xBEF9A3F7L, 0xC67178F2L
}; 

/***************************************************************/ 
/********************** Local Utilities ************************/ 
/***************************************************************/ 

/* Rotate x right by n bits */ 
static u4 rotrFixed(u4 x, u4 n)
{
	return (x >> n) | (x << (32 - n)); 
}


/*** 
 * Inputs:  a, b, c, d, e, f, g, h, i 
 * Outputs: d and h 
 */ 
static void RND(u4 a, u4 b, u4 c, u4 *d, u4 e, u4 f, u4 g, u4 *h, u4 i, u4 *W) 
{ 
	u4 t0, t1; 
	
	t0    = (*h) + Sigma1(e) + Ch(e, f, g) + K[i] + W[i]; 
	t1    = Sigma0(a) + Maj(a, b, c); 
	(*d) += t0; 
	(*h)  = t0 + t1; 

}


static void Transform(sha256_ctx_t* ctx)
{
	u4 S[8], W[64];
	int i;

	/* Copy context->state[] to working vars */
	for (i = 0; i < 8; i++)
		S[i] = ctx->digest[i];

	for (i = 0; i < 16; i++)
		W[i] = ctx->buffer[i];

	for (i = 16; i < 64; i++)
		W[i] = Gamma1(W[i-2]) + W[i-7] + Gamma0(W[i-15]) + W[i-16];

	for (i = 0; i < 64; i += 8) {
		RND(S[0],S[1],S[2],&S[3],S[4],S[5],S[6],&S[7],i+0,W);
		RND(S[7],S[0],S[1],&S[2],S[3],S[4],S[5],&S[6],i+1,W);
		RND(S[6],S[7],S[0],&S[1],S[2],S[3],S[4],&S[5],i+2,W);
		RND(S[5],S[6],S[7],&S[0],S[1],S[2],S[3],&S[4],i+3,W);
		RND(S[4],S[5],S[6],&S[7],S[0],S[1],S[2],&S[3],i+4,W);
		RND(S[3],S[4],S[5],&S[6],S[7],S[0],S[1],&S[2],i+5,W);
		RND(S[2],S[3],S[4],&S[5],S[6],S[7],S[0],&S[1],i+6,W);
		RND(S[1],S[2],S[3],&S[4],S[5],S[6],S[7],&S[0],i+7,W);
	}

	/* Add the working vars back into digest state[] */
	for (i = 0; i < 8; i++) {
		ctx->digest[i] += S[i];
	}
}



static u4 ByteReverseWord32(u4 value)
{ 
	return ((value & 0xff000000) >> 24) | 
	       ((value & 0x00ff0000) >>  8) | 
	       ((value & 0x0000ff00) <<  8) | 
	       ((value & 0x000000ff) << 24); 
}


/* Reverse byte order of words in a u4-array */ 
static void ByteReverseWords ( 
	u4 *out, 
	const u4* in, 
	u4 byteCount) 
{
	u4  count = byteCount / sizeof(u4); 
	u4  i; 

	for (i = 0; i < count; i++) { 
		out[i] = ByteReverseWord32(in[i]); 
	}

}


static void ByteReverseBytes(u1 *out, const u1 *in,  u4 byteCount)
{
	u4 *op = (u4 *) out; 
	const u4 *ip = (const u4 *) in; 

	ByteReverseWords(op, ip, byteCount); 
}

static void AddLength(sha256_ctx_t *ctx, u4 len) 
{
	u4 tmp = ctx->loLen;
	if ( (ctx->loLen += len) < tmp)
		ctx->hiLen++;                       /* carry low to high */
}



/***************************************************************/ 
/******************** Exported Functions ***********************/ 
/***************************************************************/ 

/*** 
 * [Function   ] sha256_init 
 * [Description] Initialize SHA256 calculation 
 * [Parameters ] 
 *       (out) ctx : SHA256 calculation context 
 * [Return     ] 0: success (Error code in sha256_err.h) 
 * [Note       ] None 
 */ 
int sha256_init( 
	OUT    sha256_ctx_t *ctx)
{
	ctx->digest[0] = 0x6A09E667L;
	ctx->digest[1] = 0xBB67AE85L;
	ctx->digest[2] = 0x3C6EF372L;
	ctx->digest[3] = 0xA54FF53AL;
	ctx->digest[4] = 0x510E527FL;
	ctx->digest[5] = 0x9B05688CL;
	ctx->digest[6] = 0x1F83D9ABL;
	ctx->digest[7] = 0x5BE0CD19L;

	ctx->buffLen = 0; 
	ctx->loLen   = 0; 
	ctx->hiLen   = 0; 
	
	return 0; 
}


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
	IN     SE_BYTE      *msg)
{
	/* do block size increments */
	u1* local = (u1*)ctx->buffer; 
	
	if (msg_len == 0) { 
		return SHA256_ERR_MSGLEN; 
	}

	while (msg_len) { 
		u4 add = MIN(msg_len, SHA256_BLOCK_SIZE - ctx->buffLen); 
		
		memcpy(&local[ctx->buffLen], msg, add); 

		ctx->buffLen += add; 
		msg          += add; 
		msg_len      -= add; 

		if (ctx->buffLen == SHA256_BLOCK_SIZE) { 
#ifdef LITTLE_ENDIAN_ORDER
			ByteReverseBytes(local, local, SHA256_BLOCK_SIZE);
#endif
			Transform(ctx);
			AddLength(ctx, SHA256_BLOCK_SIZE);
			ctx->buffLen = 0; 
		}
	}
	
	return 0; 
}


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
	OUT    SE_BYTE      *digest) 
{
	u1 *local = (u1 *) ctx->buffer; 

	AddLength(ctx, ctx->buffLen);  /* before adding pads */

	local[ctx->buffLen++] = 0x80;  /* add 1 */

	/* pad with zeros */
	if (ctx->buffLen > SHA256_PAD_SIZE) {
		memset(&local[ctx->buffLen], 0, SHA256_BLOCK_SIZE - ctx->buffLen);
		ctx->buffLen += SHA256_BLOCK_SIZE - ctx->buffLen;

#ifdef LITTLE_ENDIAN_ORDER
		ByteReverseBytes(local, local, SHA256_BLOCK_SIZE);
#endif
		Transform(ctx);
		ctx->buffLen = 0; 
	}
	memset(&local[ctx->buffLen], 0, SHA256_PAD_SIZE - ctx->buffLen); 

	/* put lengths in bits */ 
	ctx->hiLen = (ctx->loLen >> (8 * sizeof(ctx->loLen) - 3)) + 
		(ctx->hiLen << 3); 
	ctx->loLen = ctx->loLen << 3; 

	/* store lengths */ 
#ifdef LITTLE_ENDIAN_ORDER
	ByteReverseBytes(local, local, SHA256_BLOCK_SIZE);
#endif
	/* ! length ordering dependent on digest endian type ! */
	memcpy(&local[SHA256_PAD_SIZE], (void *) &(ctx->hiLen), sizeof(u4)); 
	memcpy(&local[SHA256_PAD_SIZE + sizeof(u4)], (void *) &(ctx->loLen), sizeof(u4)); 

	Transform(ctx);
#ifdef LITTLE_ENDIAN_ORDER
	ByteReverseWords(ctx->digest, ctx->digest, SHA256_DIGEST_SIZE); 
#endif
	memcpy(digest, ctx->digest, SHA256_DIGEST_SIZE); 

	sha256_init(ctx);  /* reset state */ 
	
	return 0; 
}


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
	OUT    SE_BYTE  *digest) 
{ 
	sha256_ctx_t ctx; 
	
	if (msg_len == 0) { 
		return SHA256_ERR_MSGLEN; 
	}
	
	sha256_init  (&ctx); 
	sha256_update(&ctx, msg_len, msg); 
	sha256_final (&ctx, digest); 
	
	return 0; 
}


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
	IN     SE_BYTE  *digest) 
{ 
	SE_BYTE  digest_val[SHA256_LEN];   /* Correct SHA256 digest value */ 

	if (msg_len == 0) { 
		return SHA256_ERR_MSGLEN; 
	}
	
	sha256_calc(msg_len, msg, digest_val); 
	
	if (memcmp(digest, digest_val, SHA256_LEN) != 0) { 
		/* Verificatin result false */ 
		return SHA256_ERR_VERIFY; 
	}
	
	return 0; 
}
