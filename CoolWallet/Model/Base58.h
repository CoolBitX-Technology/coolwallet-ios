//
//  Base58.h
//  CwTest
//
//  Created by CP Hsiao on 2015/4/19.
//  Copyright (c) 2015年 CP Hsiao. All rights reserved.
//

#ifndef __CwTest__Base58__
#define __CwTest__Base58__

#include <stdio.h>

int base58Encode(const char* input,const unsigned int inLen,unsigned char *output,unsigned int outLen);
int base58Decode(const char* addr,const unsigned int addrLen,unsigned char *buf,unsigned int bufLen);

#endif /* defined(__CwTest__Base58__) */
