//
//  SRWebSocket+CW.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2015/10/26.
//  Copyright © 2015年 MAC-BRYAN. All rights reserved.
//

#import <objc/runtime.h>

#import "SRWebSocket+CW.h"

SRWebSocket *sharedInstance;

static id<CWSocketDelegate> const * const CWDelegate;

@interface SRWebSocket () 

@end

@implementation SRWebSocket(CW)

@dynamic cwDelegate;

+(SRWebSocket *) sharedSocket
{
    if (!sharedInstance) {
        sharedInstance = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"wss://n.block.io/"]]];
        sharedInstance.delegate = sharedInstance;
        [sharedInstance open];
    }
    
    return sharedInstance;
}

-(void) setCwDelegate:(id<CWSocketDelegate>)cwDelegate
{
    objc_setAssociatedObject(self, CWDelegate, cwDelegate, OBJC_ASSOCIATION_ASSIGN);
}

-(id<CWSocketDelegate>) cwDelegate
{
    return (id<CWSocketDelegate>)objc_getAssociatedObject(self, CWDelegate);
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket Connected");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@"%@:( Websocket Failed With Error %@", webSocket, error);
    sharedInstance = nil;
    
    // try reopen socket after 5 seconds
    [SRWebSocket performSelector:@selector(sharedSocket) withObject:nil afterDelay:3];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
    NSLog(@"Websocket Received \"%@\"", message);
    
    if (webSocket.cwDelegate != nil && [webSocket.cwDelegate respondsToSelector:@selector(didSocketReceiveMessage:)]) {
        [webSocket.cwDelegate didSocketReceiveMessage:message];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    sharedInstance = nil;
    [SRWebSocket performSelector:@selector(sharedSocket) withObject:nil afterDelay:2];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;
{
    NSLog(@"Websocket received pong");
}

@end
