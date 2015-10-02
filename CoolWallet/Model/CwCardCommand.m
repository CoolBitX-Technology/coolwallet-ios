//
//  CwCardCommand.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/10.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//
#
#import "CwCardCommand.h"

@interface CwCardCommand ()
@property NSInteger dataPacketIdx;
@end

@implementation CwCardCommand

//NSInteger dataPacketIdx; //index for current data

-(void) setCmdId: (NSInteger) cmdId
{
    _cmdId = cmdId;
    self.dataPacketIdx = 0;
}

-(NSData *) GetBleInputCmdPacket
{
    NSMutableData *commandToSend;
    NSInteger totalDataPackets = ceil((double)(self.cmdInput.length)/16);
    
    /*
    if (self.cmdInput.length>0 && self.cmdInput.length < 16)
        totalDataPackets = 1;
    */
    
    Byte blePacketId[1] = {self.dataPacketIdx};
    Byte blePacketLen[1] = {9};
    Byte bleApdu[4] = {self.cmdCla, self.cmdId, self.cmdP1, self.cmdP2};
    Byte bleLc[2] = {self.cmdInput.length & 0x00FF, (self.cmdInput.length >> 8) & 0x00FF}; //little endian
    Byte bleTotalDataLen[2] = {bleLc[1], bleLc[0]}; //big endian
    Byte bleTotalDataPacket[1] = {totalDataPackets};
    
    commandToSend = [NSMutableData dataWithBytes:blePacketId length: sizeof(blePacketId)];
    [commandToSend appendBytes:blePacketLen length: sizeof(blePacketLen)];
    [commandToSend appendBytes:bleApdu length: sizeof(bleApdu)];
    [commandToSend appendBytes:bleLc length: sizeof(bleLc)];
    [commandToSend appendBytes:bleTotalDataLen length: sizeof(bleTotalDataLen)];
    [commandToSend appendBytes:bleTotalDataPacket length: sizeof(bleTotalDataPacket)];

    //NSLog(@"BleInputCmd: %@", commandToSend);
    self.dataPacketIdx++;
    
    return commandToSend;
}

-(NSData *) GetBleInputDataPacket
{
    NSMutableData *commandData;
    NSInteger totalDataPackets = ceil((double)(self.cmdInput.length)/16);
    
    /*
    if (self.cmdInput.length>0 && self.cmdInput.length < 16)
        totalDataPackets = 1;
    */
    
    if (self.cmdInput.length==0)
        return nil;
    
    if (self.dataPacketIdx <= totalDataPackets) {
        Byte blePacketId[1] = {self.dataPacketIdx};
        Byte blePacketLen[1] = {(self.cmdInput.length-(self.dataPacketIdx-1)*16)>=16? 16: (self.cmdInput.length-(self.dataPacketIdx-1)*16)};
        NSData *blePacketData = [self.cmdInput subdataWithRange:NSMakeRange((self.dataPacketIdx-1)*16, blePacketLen[0])];
        
        commandData = [NSMutableData dataWithBytes:blePacketId length: sizeof(blePacketId)];
        [commandData appendBytes:blePacketLen length: sizeof(blePacketLen)];
        [commandData appendBytes:blePacketData.bytes length: blePacketData.length];
        
        //NSLog(@"BleInputData: %@", commandData);
        self.dataPacketIdx++;
    }
    
    return commandData;
}

-(void) ParseBleOutputData: (NSArray *)outputData
{
    NSMutableData *cmdOutput;
    Byte packetId = 1; //ble output data packet starts from 1
    
    if (outputData == nil || outputData.count==0)
        return;
    
    for (NSData *outData in outputData) {
        //convert NSData to Byte Array
        const unsigned char *byteData = [outData bytes];
        //NSLog(@"byteData %@", outData);
        
        //Check packet Id, skip wrong/duplicate packets
        if (byteData[0] != packetId)
            continue;
        
        //Check length
        if (byteData[1] > 16)
            return;
        
        //Form the real data from SE
        NSData *blePacketData = [outData subdataWithRange:NSMakeRange(2, byteData[1])];

        if (cmdOutput == nil)
            cmdOutput = [NSMutableData dataWithBytes:[blePacketData bytes] length: blePacketData.length];
        else
            [cmdOutput appendBytes:[blePacketData bytes] length: blePacketData.length];
        packetId ++;
    }
    
    //convert NSData to Byte Array
    const unsigned char *byteData = [cmdOutput bytes];
    
    //Sw1 and Sw2
    self.cmdResult = byteData[cmdOutput.length-2]<<8 | byteData[cmdOutput.length-1];
    
    //truncat the last 2 bytes as SW1 and SW2
    self.cmdOutput = [cmdOutput subdataWithRange:NSMakeRange(0, cmdOutput.length-2)];
}

@end
