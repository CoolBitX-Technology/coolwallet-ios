//
//  CwCardCommand.h
//  CwTest
//
//  Created by CP Hsiao on 2014/12/10.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CwCardCommand : NSObject

typedef NS_ENUM (NSInteger, CwCardCommandPriority) {
    CwCardCommandPriorityNone = 0x00,       //lowest
    CwCardCommandPriorityTop = 0x01,       //insert to the front
    CwCardCommandPriorityExclusive = 0x02   //insert to the front and delete others
};

@property (nonatomic) NSInteger cmdPriority;
@property (nonatomic) NSInteger cmdCla;
@property (nonatomic) NSInteger cmdId;
@property (nonatomic)NSInteger cmdP1;
@property (nonatomic)NSInteger cmdP2;
@property (nonatomic)NSData *cmdInput;
@property (nonatomic)NSData *cmdOutput;
@property (nonatomic)NSInteger cmdResult;
@property BOOL busy;

-(NSData *) GetBleInputCmdPacket;
-(NSData *) GetBleInputDataPacket;
-(void) ParseBleOutputData: (NSArray *)outputData;
@end
