//
//  CwHost.h
//  CwTest
//
//  Created by CP Hsiao on 2014/12/14.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <Foundation/Foundation.h>

//return value of reg_info
typedef NS_ENUM (NSInteger, CwHostBindtatus) {
    CwHostBindStatusEmpty = 0x00,
    CwHostBindStatusRegistered = 0x01,
    CwHostBindStatusConfirmed = 0x02
};

//return value of find_hstid
typedef NS_ENUM (NSInteger, CwHostConfirmStatus) {
    CwHostConfirmStatusConfirmed = 0x00,
    CwHostConfirmStatusNotConfirmed = 0x01
};

@interface CwHost : NSObject <NSCoding>

@property NSString  *hostDescription;
@property NSInteger hostBindStatus;

@end
