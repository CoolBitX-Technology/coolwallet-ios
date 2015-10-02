/***
 * [ Project     ] bcdc app 
 * [ Module      ] 
 * [ Description ] BCDC Tx interface, including Tx,Txin,Txout structure,Address Verifier, Coin Selection Policy 
 * [ Note        ] 
 */ 

#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include "sha256.h"
#include "tx_err.h"

#define FEE_RATE_UNIT 10000
static int64_t FEERATE = FEE_RATE_UNIT;

typedef struct
{
    unsigned char *bytes;
    size_t txSz;
}RawTx;
typedef struct Txin
{
	unsigned char tx[32];
	unsigned int index;
	size_t scriptPubLen,scriptSigLen;
	unsigned char *scriptPub,*scriptSig;
    int64_t value;
}Txin;
typedef struct Txout
{
	char addr[35];
	int64_t value;
}Txout;
typedef struct Tx
{
	unsigned int version;
	unsigned txinCnt,txoutCnt;
	Txin* txinList;
	Txout* txoutList;
	unsigned int lock;
}Tx;

size_t VItoBytes(unsigned int vi,unsigned char *ptr);
size_t int32toBytes(unsigned int n,unsigned char *ptr);
size_t int64toBytes(int64_t n,unsigned char *ptr);
size_t scriptPubPayToHash(char* addr,unsigned char *ptr);

void doubleSha256(unsigned char *data,const size_t sz,unsigned char hash[SHA256_DIGEST_SIZE]);

/***
 * [Function   ] txToBytes 
 * [Description] Generate a raw transaction from transaction tx
 * [Parameters ] 
 *       (in ) tx : Transaction
 *       (out) rawTx : Raw transaction
 * [Return     ] Number of raw transaction bytes
 * [Note       ] 
 */
size_t txToBytes(const Tx* tx,unsigned char** rawTx);

/***
 * [Function   ] addrToPubKeyHash 
 * [Description] Convert address to hash(HASH160) of public key
 * [Parameters ] 
 *       (in ) addr : address  encoding in base58
 *       (out) pubKeyHash : hash(HASH160) of public key (20bytes)
 * [Return     ]
 *       0 : Success
 *       1 : Invalid address
 * [Note       ] 
 */
int addrToPubKeyHash(char* addr,unsigned char *pubKeyHash);

/***
 * [Function   ] addrVerify
 * [Description] Verify an address
 * [Parameters ]
 *       (in ) addr : address encoding in base58
 * [Return     ]
 *       0 : sucess
 *       1 : Base58 decode fail
 *       2 : Invalid checksum
 * [Note       ]
 *    -- addr is variable length between 25 to 34 bytes
 */
int addrVerify(const char* addr);

/***
 * [Function   ] sizeofTx 
 * [Description] Calculate a approximate size of a transaction
 * [Parameters ] 
 *       (in ) tx : Transaction
 * [Return     ] Number of raw transaction bytes
 * [Note       ] 
 */
size_t sizeofTx(const Tx*);
/*** 
 * Unused now, testing use
 * [Function   ] txGen 
 * [Description] Generate a transaction
 * [Parameters ] 
 *       (in ) txinList : array of txins (usable coins)
 *       (in ) txinCnt : length of txinList
 *       (in ) txoutList : array of recipient and value
 *       (in ) txoutCnt : length of txoutList
 *       (in ) priKeyList: array of private keys    (testing)
 *       (in ) priKeyCnt: length of priKeyList      (testing)
 *       (out) tx : transaction with signed inputs
 * [Return     ]
 *       0 : Success
 *       1 : Total amount of inputs are not enough to pay outputs
 *       2 : Fail to sign one(or more) input(s)
 *       3 : Fail to get one(or more) public key
 * [Note       ] 
 */
int txGen(Txin *txinList,const unsigned int txinCnt,Txout *txoutList,const unsigned int txoutCnt,Tx** tx,int64_t *fee);

size_t signatureToDER(const unsigned char r[32],const unsigned char s[32],unsigned char signatureDER[73]);
int txCopyHashGen(const Tx *tx,const int index,unsigned char txCopyHash[32]);