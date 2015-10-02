/***
 * [ Project     ] bcdc-se app 
 * [ Module      ] sha256 
 * [ Description ] SHA256 calculation 
 * [ Note        ] 
 */ 

#ifndef __SHA256_ERR_H__ 
#define __SHA256_ERR_H__ 

#define SHA256_ERR_BASE      (0x00000000) 
#define SHA256_ERR_MSGLEN    (SHA256_ERR_BASE + 0x01)    /* Wrong message length */ 
#define SHA256_ERR_VERIFY    (SHA256_ERR_BASE + 0x02)    /* SHA256 verification false */ 

#endif 
