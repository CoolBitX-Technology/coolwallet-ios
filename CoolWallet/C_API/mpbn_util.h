/*** 
 * mpbn_word: MPBN utility module
 */ 
#ifndef __MPBN_UTIL_H__
#define __MPBN_UTIL_H__

typedef unsigned char      MPBN_WORD;


#define ERR_MPBN_BORROW 1

#define MPBN_WSZ          sizeof(MPBN_WORD) 

#define MPBN_WORDMAX      0xffffffff 
#define MPBN_HWORDVAL     0x80000000   /* Half word value */ 
#define MPBN_WORD_MSBIT   0x80000000   /* Most significant bit */ 
#define MPBN_WORD_NBIT    32           /* Number of bits */ 


int mpbn_comp (
               MPBN_WORD *a,
               MPBN_WORD *b,
               int         nw);

int mpbn_sub (
              MPBN_WORD *r,
              MPBN_WORD *a,
              MPBN_WORD *b,
              int         nw);

#endif 
