#import <Foundation/Foundation.h>

#include "tx.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "CwBase58.h"

#define MAIN_NETWORK 0x00
#define TEST_NETWORK 0x6f
#define NAMECOIN_NET 0x34
#define EGD_NETWORK  0x20

#define NETWORK MAIN_NETWORK

int coinCmp(const void *a,const void *b)
{
	if(((Txin*)b)->value - ((Txin*)a)->value>0)
		return 1;
	if(((Txin*)b)->value - ((Txin*)a)->value<0)
		return -1;
	return 0;
}

void doubleSha256(unsigned char *data,const size_t sz,unsigned char hash[SHA256_DIGEST_SIZE])
{
	unsigned char buf[SHA256_DIGEST_SIZE];
	sha256_calc(sz,data,buf);
	sha256_calc(SHA256_DIGEST_SIZE,buf,hash);
}

int addrVerify(const char* addr)
{
	//unsigned char buf[25];
	unsigned char hash[SHA256_DIGEST_SIZE];
    
    //base58Decode(addr,34,buf,25);
    NSString *address = [[NSString alloc] initWithBytes:addr length:strlen(addr) encoding:NSUTF8StringEncoding];
    NSData *addDecode = [CwBase58 base58ToData:address];
    
    Byte *bytePtr = (Byte *)[addDecode bytes];
    
    if (bytePtr[0] != NETWORK)
        return ADDRESS_VERIFY_DECODE;
    
    doubleSha256(bytePtr,21,hash);
	
	if(memcmp(bytePtr+21,hash,4) != 0)
		return ADDRESS_VERIFY_CHECKSUM;
	else
		return ADDRESS_VERIFY_BASE;
}

int setFeeRate(int64_t feeRate)
{
	if(feeRate >= FEE_RATE_UNIT)
	{
		FEERATE = feeRate;
		return SET_FEE_RATE_BASE;
	}
	else
	{
		return SET_FEE_RATE_INVALID_VALUE;
	}
}

int addrToPubKeyHash(char* addr, unsigned char pubKeyHash[20])
{
	//unsigned char buf[25]={0};
	if(addrVerify(addr)!=ADDRESS_VERIFY_BASE)
	{
		return ADDR_TO_PUBKEY_HASH_ADDR;
	}
    
	//base58Decode(addr,34,buf,25);
    NSString *address = [[NSString alloc] initWithBytes:addr length:strlen(addr) encoding:NSUTF8StringEncoding];
    NSData *addDecode = [CwBase58 base58ToData:address];
    
	memcpy(pubKeyHash, (addDecode.bytes)+1, 20);
    
	return ADDR_TO_PUBKEY_HASH_BASE;
}

size_t VItoBytes(unsigned int vi, unsigned char *ptr)
{
	if(vi < 0xfd)
	{
		ptr[0] = vi;
		return 1;
	}
	else if(vi <= 0xffff)
	{
		ptr[0] = 0xfd;
		ptr[1] = vi & 0xff;
		ptr[2] = (vi & 0xff00) >> 2*8;
		return 3;
	}
	else
	{
		ptr[0] = 0xfe;
		ptr[1] = vi & 0xff;
		ptr[2] = (vi & 0xff00) >> 1*8;
		ptr[3] = (vi & 0xff0000) >> 2*8;
		ptr[4] = (vi & 0xff000000) >> 3*8;
		return 5;
	}
	/*TODO: uint64_t*/
}
size_t int32toBytes(unsigned int n, unsigned char *ptr)
{
	ptr[0] = n & 0xff;
	ptr[1] = (n & 0xff00) >> 1*8;
	ptr[2] = (n & 0xff0000) >> 2*8;
	ptr[3] = (n & 0xff000000) >> 3*8;
	return 4;
}
size_t int64toBytes(int64_t n, unsigned char *ptr)
{
	ptr[0] = n & 0xff;
	ptr[1] = (n & 0xff00) >> 1*8;
	ptr[2] = (n & 0xff0000) >> 2*8;
	ptr[3] = (n & 0xff000000) >> 3*8;
	ptr[4] = (n & 0xff00000000) >> 4*8;
	ptr[5] = (n & 0xff0000000000) >> 5*8;
	ptr[6] = (n & 0xff000000000000) >> 6*8;
	ptr[7] = (n & 0xff00000000000000) >> 7*8;
	return 8;
}
size_t scriptPubPayToHash(char* addr,unsigned char *ptr)
{
	unsigned char scriptPub[25] = {0x76,0xa9,0x14,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0x88,0xac};
	if(addrToPubKeyHash(addr,scriptPub+3) == ADDR_TO_PUBKEY_HASH_BASE)
	{
		memcpy(ptr,scriptPub,25);
		return 25;
	}
	return 0;
}
int txCopyHashGen(const Tx *tx,const int index,unsigned char txCopyHash[32])
{
    unsigned char *buf = (unsigned char*)malloc(sizeofTx(tx)+1000);
	unsigned char *pivot = buf;
	size_t szTxNew;
	unsigned int i;
	
	// version no.
	pivot += int32toBytes(tx->version,pivot);
	// In-counter
	pivot += VItoBytes(tx->txinCnt,pivot);
    
	//List of inputs
	for(i=0;i<tx->txinCnt;i++)
	{
		//prehash
		memcpy(pivot,tx->txinList[i].tx,32);
		pivot += 32;
		//index
		pivot += int32toBytes(tx->txinList[i].index,pivot);
		if(i==index)
		{
			//script len
			pivot += VItoBytes(tx->txinList[i].scriptPubLen,pivot);
			//script
			memcpy(pivot,tx->txinList[i].scriptPub,tx->txinList[i].scriptPubLen);
			pivot += tx->txinList[i].scriptPubLen;
		}
		else
		{
			//script len
			pivot += VItoBytes(0,pivot);
		}
		//sequence_no
		pivot += int32toBytes(0xffffffff,pivot);
	}
	
	// Out-counter
	pivot += VItoBytes(tx->txoutCnt,pivot);
    
	//List of outputs
	for(i=0;i<tx->txoutCnt;i++)
	{
		//value
		pivot += int64toBytes(tx->txoutList[i].value,pivot);
		//script len
		pivot += VItoBytes(25,pivot);
		//script
		pivot += scriptPubPayToHash(tx->txoutList[i].addr,pivot);
	}
	//sequence_no
    pivot += int32toBytes(tx->lock,pivot);
	//signature type: All
	pivot += int32toBytes(0x00000001,pivot);
	
	szTxNew = pivot - buf;
	
	//_dumpBytes(buf,szTxNew);
	//getchar();
    
	doubleSha256(buf,szTxNew,txCopyHash);
	free(buf);
    
    return 0;
}
size_t signatureToDER(const unsigned char r[32],const unsigned char s[32],unsigned char signatureDER[73])
{
    unsigned char *ptr = signatureDER;
    
    *(ptr++) = (32+32+7)+((r[0]&0x80) !=0)+((s[0]&0x80) !=0);
	//DER encoding
	*(ptr++) = 0x30;
	*(ptr++) = (32+32+4)+((r[0]&0x80) !=0)+((s[0]&0x80) !=0);
    
	// r
	*(ptr++) = 0x02;
	*(ptr++) = 32+((r[0]&0x80) !=0);
	if((r[0]&0x80) !=0)
		*(ptr++) = 0;
	memcpy(ptr,r,32);
	ptr+=32;
    
	// s
	*(ptr++) = 0x02;
	*(ptr++) = 32+((s[0]&0x80) !=0);
	if((s[0]&0x80) !=0)
		*(ptr++) = 0;
	memcpy(ptr,s,32);
	ptr+=32;
    
	//hashTypeCode
	*(ptr++) = 0x01;
    
    return ptr - signatureDER;
}
size_t pubkey(unsigned char* buf,int *ret)
{
	unsigned char* ptr = buf;
	unsigned char priKey[32],pubKey[64];
	//*ret = bcdc_ecdsa_get_keypair(priKey,pubKey);
    
    memset(pubKey,0,sizeof(pubKey));
    memset(priKey,0,sizeof(priKey));

	if(*ret != 0)
		return 0;

	*(ptr++) = 0x21;
	*(ptr++) = ((pubKey[31] & 0x01)==1?0x03:0x02);
	memcpy(ptr,pubKey,32);
	ptr += 32;

	return ptr-buf;
}
size_t sizeofVI(const unsigned int n)
{
	if(n<0xfd)
		return 1;
	else if(n<=0xffff)
		return 3;
	else
		return 5;
}
size_t sizeofTx(const Tx* tx)
{
	// 8 + IN(VI+n*INPUT) +OUT(VI+n*OUTPUT)
	// INPUT = 32+4+(VI+script)+4
	// OUTPUT = 8+(VI+script)
	size_t  szTx = tx->txinCnt*148 + tx->txoutCnt * 34 + 10;
	return szTx;
}
size_t txToBytes(const Tx* tx,unsigned char** rawTx)
{
	unsigned char *pivot,*buf;
	unsigned int i;
	int ret = 0;
    
	if(tx == NULL)
		return 0;

    buf = (unsigned char*)malloc(sizeofTx(tx));
    pivot = buf;
    
	// version no.
	pivot += int32toBytes(tx->version,pivot);
	// In-counter
	pivot += VItoBytes(tx->txinCnt,pivot);

	//List of inputs
	for(i=0;i<tx->txinCnt && ret==0;i++)
	{
		//prehash
		memcpy(pivot,tx->txinList[i].tx,32);
		pivot += 32;
		//index
		pivot += int32toBytes(tx->txinList[i].index,pivot);
		//script len
		pivot += VItoBytes(tx->txinList[i].scriptSigLen,pivot);
		//scriptSig
		memcpy(pivot,tx->txinList[i].scriptSig,tx->txinList[i].scriptSigLen);
		pivot+=tx->txinList[i].scriptSigLen;
		//sequence_no
		pivot += int32toBytes(0xffffffff,pivot);
	}

	// Out-counter
	pivot += VItoBytes(tx->txoutCnt,pivot);

	//List of outputs
	for(i=0;i<tx->txoutCnt && ret==0;i++)
	{
		//value
		pivot += int64toBytes(tx->txoutList[i].value,pivot);
		//script len
		pivot += VItoBytes(25,pivot);
		//script
		pivot += scriptPubPayToHash(tx->txoutList[i].addr,pivot);
	}

    pivot += int32toBytes(tx->lock,pivot);
	*rawTx = buf;
	return (ret==0?pivot - buf:0);
}

int coinSelect(Txin* txinList,unsigned int txinCnt,int64_t outputSum,unsigned int*coinSelectedCnt,int64_t* change,int64_t *fee)
{
    int64_t nTotal=0,_fee=0;
    size_t txBlank;
    unsigned int _coinSelectedCnt;
    unsigned int i;
    
    qsort(txinList,txinCnt,sizeof(Txin),coinCmp);

    for(_coinSelectedCnt=0;_coinSelectedCnt<txinCnt && nTotal<outputSum ;_coinSelectedCnt++)
    {
        nTotal += txinList[_coinSelectedCnt].value;
    }
    
    txBlank = 1024 - ((149*_coinSelectedCnt+34*2+10)%1024);
    for(i=0 ; i<txBlank/149 && _coinSelectedCnt<txinCnt ; i++, _coinSelectedCnt++)
    {
        nTotal += txinList[_coinSelectedCnt].value;
    }
    _fee = ((149*_coinSelectedCnt+34*2+10-1)/1024 +1) * FEERATE;
    
    while(nTotal < outputSum+_fee && _coinSelectedCnt<txinCnt)
    {
        txBlank = (1024 - txBlank) + 1024;
        for(i=0 ; i<txBlank/149 && _coinSelectedCnt<txinCnt ; i++, _coinSelectedCnt++)
        {
            nTotal += txinList[_coinSelectedCnt].value;
        }
        _fee = ((149*_coinSelectedCnt+34*2+10-1)/1024 +1) * FEERATE;
    }
    
    if(nTotal < outputSum+_fee)
    {
        return COIN_SELECT_NOT_ENOUOH_INPUTS;
    }
    else
    {
        *fee = _fee;
        *coinSelectedCnt = _coinSelectedCnt;
        *change = nTotal - (outputSum + _fee);
        return COIN_SELECT_BASE;
    }
}
//--------------------------------


size_t signature(const Tx *tx,const int index,unsigned char* outPtr,int *ret)
{
    unsigned char *buf = (unsigned char*)malloc(sizeofTx(tx)+1000);
    unsigned char *pivot = buf;
    size_t szTxNew;
    unsigned char r[32];
    unsigned char s[32];
    unsigned char hash[SHA256_DIGEST_SIZE];
    unsigned char *outStart = outPtr;
    unsigned int i;

    // version no.
    pivot += int32toBytes(tx->version,pivot);
    // In-counter
    pivot += VItoBytes(tx->txinCnt,pivot);

    //List of inputs
    for(i=0;i<tx->txinCnt;i++)
    {
        //prehash
        memcpy(pivot,tx->txinList[i].tx,32);
        pivot += 32;
        //index
        pivot += int32toBytes(tx->txinList[i].index,pivot);
        if(i==index)
        {
            //script len
            pivot += VItoBytes(tx->txinList[i].scriptPubLen,pivot);
            //script
            memcpy(pivot,tx->txinList[i].scriptPub,tx->txinList[i].scriptPubLen);
            pivot += tx->txinList[i].scriptPubLen;
        }
        else
        {
            //script len
            pivot += VItoBytes(0,pivot);
        }
        //sequence_no
        pivot += int32toBytes(0xffffffff,pivot);
    }

    // Out-counter
    pivot += VItoBytes(tx->txoutCnt,pivot);

    //List of outputs
    for(i=0;i<tx->txoutCnt;i++)
    {
        //value
        pivot += int64toBytes(tx->txoutList[i].value,pivot);
        //script len
        pivot += VItoBytes(25,pivot);
        //script
        pivot += scriptPubPayToHash(tx->txoutList[i].addr,pivot);
    }
    //sequence_no
    pivot += int32toBytes(tx->lock,pivot);
    //signature type: All
    pivot += int32toBytes(0x00000001,pivot);

    szTxNew = pivot - buf;

    //_dumpBytes(buf,szTxNew);
    //getchar();

    doubleSha256(buf,szTxNew,hash);
    free(buf);


    //----------------     sign     ----------------------------
    //ret = bcdc_ecdsa_sign(hash , NULL , r , s);

    memset(r, 0, sizeof(r));
    memset(s, 0, sizeof(s));
    //----------------     sign     ----------------------------


    if(*ret != 0)
    return 0;

    *(outPtr++) = (32+32+7)+((r[0]&0x80) !=0)+((s[0]&0x80) !=0);
    //DER encoding
    *(outPtr++) = 0x30;
    *(outPtr++) = (32+32+4)+((r[0]&0x80) !=0)+((s[0]&0x80) !=0);

    // r
    *(outPtr++) = 0x02;
    *(outPtr++) = 32+((r[0]&0x80) !=0);
    if((r[0]&0x80) !=0)
    *(outPtr++) = 0;
    memcpy(outPtr,r,32);
    outPtr+=32;

    // s
    *(outPtr++) = 0x02;
    *(outPtr++) = 32+((s[0]&0x80) !=0);
    if((s[0]&0x80) !=0)
    *(outPtr++) = 0;
    memcpy(outPtr,s,32);
    outPtr+=32;

    //hashTypeCode
    *(outPtr++) = 0x01;

    return outPtr-outStart;
}
 
int txGen(Txin* txinList,unsigned int txinCnt,Txout* txoutList,unsigned int txoutCnt,Tx** tx,int64_t* fee)
{
	unsigned int coinCnt=0;
	unsigned int i;
	int64_t outputSum,change;
	Tx* _tx = NULL;
	unsigned char *pivot;
	int ret = TXGEN_BASE;

    outputSum = 0;
    for(i=0;i<txoutCnt-1;i++)
	{
		outputSum += txoutList[i].value;
	}

	if(coinSelect(txinList, txinCnt, outputSum, &coinCnt, &change, fee) == COIN_SELECT_BASE)
	{
        if(change == 0)
        {
            txoutCnt--;
        }
        else
        {
            txoutList[txoutCnt-1].value = change;
        }
        
		_tx = (Tx*)calloc(1,sizeof(Tx));
		_tx->version = 1;
		_tx->txinCnt = coinCnt;
		_tx->txoutCnt = txoutCnt;
		_tx->txinList = txinList;
		_tx->txoutList = txoutList;
		_tx->lock = 0x00000000;

		for(i=0;i<coinCnt;i++)
		{
			txinList[i].scriptSig = (unsigned char*)malloc(256);
			pivot = txinList[i].scriptSig;
            
			pivot += signature(_tx,i,pivot,&ret);
            
			if(ret != SIGNATURE_BASE)
            {
                ret = TXGEN_SIGFAIL;
                break;
            }
			pivot += pubkey(pivot,&ret);
			if(ret != PUBKEY_BASE)
            {
                ret = TXGEN_PUBFAIL;
				break;
            }
			txinList[i].scriptSigLen = pivot-txinList[i].scriptSig;
		}
        if(ret)
        {
            for(i=0;i<coinCnt;i++)
            {
                if(txinList[i].scriptSig != NULL)
                {
                    free(txinList[i].scriptSig);
                }
            }
            free(_tx);
            _tx = NULL;
        }
	}
    else
    {
        _tx = NULL;
        ret = TXGEN_NOT_ENOUOH_INPUTS;
    }
  
    *tx = _tx;
	return ret;
}