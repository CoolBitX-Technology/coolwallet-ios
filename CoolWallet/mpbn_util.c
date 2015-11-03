/*** 
 * mpbn: Multi-Precision Big Number Library 
 * mpbn_util: Utility APIs 
 */ 

#include "mpbn_util.h"


/*** 
 * Unsigned big number comparison 
 * [RESULT] 
 *     - cmpres =  0: a == b
 *     - cmpres = -1: a <  b
 *     - cmpres =  1: a >  b
 */ 
int mpbn_comp (
	MPBN_WORD *a,
	MPBN_WORD *b,
	int         nw)
{
    int compar;
    
	/* Compare from MSW */ 
	while (nw > 0) { 
		if ((*a) > (*b)) { 
			/* a > b */ 
			compar = 1;
			return compar;
		} else if ((*a) < (*b)) { 
			/* a < b */ 
			compar = -1;
			return compar;
		}
		
		a++; b++; 
		nw--; 
	}
	
	/* a == b */ 
	compar = 0;
	
	return compar;
}

/***
 * Unsigned big number substraction: r = a - b
 * [NOTE] Stack size: DC
 * [NOTE] Address of r, a and b can be the same
 * [NOTE] If the result is with borrow, the function will return ERR_MPBN_BORROW
 *        (and the result will be still correct if the caller doesn't care about borrow)
 */
int mpbn_sub (
              MPBN_WORD *r,
              MPBN_WORD *a,
              MPBN_WORD *b,
              int         nw)
{
    MPBN_WORD  borrow = 0;
    int  i;
    
    /* Substract from the last (lowest) word */
    for (i = nw - 1; ; i--) {
        if (borrow) {
            if (a[i]) {
                borrow = (((a[i] - 1) < b[i])) ? 1 : 0;
            }
            /* else borrow = 1; */
            
            r[i] = (a[i] - 1) - b[i];
        } else {
            borrow = (a[i] < b[i]);
            r[i]  =  a[i] - b[i];
        }
        
        if (i == 0) { 
            /* The highest word done */ 
            break; 
        }
    }
    
    return (borrow) ? ERR_MPBN_BORROW : 0; 
}