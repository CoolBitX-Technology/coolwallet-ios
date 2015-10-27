//
//  SRWebSocket+CW.h
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/10/26.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRWebSocket.h"

@protocol CWSocketDelegate <NSObject>

@optional
- (void)didSocketReceiveMessage:(id)message;

@end

@interface SRWebSocket(CW) <SRWebSocketDelegate>

@property (weak, nonatomic) id<CWSocketDelegate> cwDelegate;

+(SRWebSocket *) sharedSocket;

@end
