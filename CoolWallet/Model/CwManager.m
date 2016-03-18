//
//  CwManager.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/5.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CwManager.h"
#import "CwCard.h"
#import "CwCardDelegate.h"

@interface CwManager () <CBCentralManagerDelegate, CwCardDelegate>
@property (strong, nonatomic) CBCentralManager *bleMgr;
@property (strong, nonatomic) CBPeripheral *myPeri;
@property NSMutableArray *cwCards;
@end

#define MIN_CONN_INTERVAL                    MSEC_TO_UNITS(500, UNIT_1_25_MS)           /**< Minimum acceptable connection interval (0.5 seconds). */
#define MAX_CONN_INTERVAL                    MSEC_TO_UNITS(1000, UNIT_1_25_MS)          /**< Maximum acceptable connection interval (1 second). */
#define SLAVE_LATENCY                        0                                          /**< Slave latency. */
#define CONN_SUP_TIMEOUT                     MSEC_TO_UNITS(4000, UNIT_10_MS)            /**< Connection supervisory timeout (4 seconds). */

NSTimer *rssiTimer;
NSTimer *scanTimer;

@implementation CwManager

#pragma mark - Singleton methods
+(id) sharedManager {
    static CwManager *sharedCwManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{sharedCwManager = [[self alloc] init];});
    return sharedCwManager;
}

-(id) init {
    if (self = [super init]) {

        self.cwCards = [[NSMutableArray alloc] init];
        
        //init bleMgr;
        //self.bleMgr = [[CBCentralManager alloc] initWithDelegate:self queue: nil];
    }
    return self;
}

-(void) checkTimeoutDevices
{
    //check if it's in the list already, update rssi only
    for (int i=0; i<self.cwCards.count; i++) {
        CwCard *cw = self.cwCards[i];
        NSLog(@"Check CW %@ lastUpdate %@", cw.bleName, cw.lastUpdate);
        if ([[NSDate date] timeIntervalSinceDate:cw.lastUpdate] > 7) {
            [self.cwCards removeObjectAtIndex:i];
            NSLog(@"Remove CW %@", cw.bleName);
            //call discover peripheral delegate
            if ([self.delegate respondsToSelector:@selector(didScanCwCards:)]) {
                [self.delegate didScanCwCards:self.cwCards];
            }
        }
    }
}

#pragma mark - CwManager Methods

-(void) scanCwCards
{
    /*
    NSLog(@"BLE Mgr State: %ld", self.bleMgr.state);

    [self.bleMgr stopScan];
    
    if (self.bleMgr.state==CBCentralManagerStatePoweredOn) {
        //scan CW
        [self.bleMgr scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"A000"]]
                                            options: @{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
    }
     
     if ([self.delegate respondsToSelector:@selector(didScanCwCards:)]) {
     [self.delegate didScanCwCards:self.cwCards];
     }
     */
    
    NSLog(@"startScan");
    //double timeout = 1000;
    //BOOL repeat = NO;
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_queue_t centralQueue = dispatch_queue_create("ble_mgr_thread", DISPATCH_QUEUE_SERIAL);
        self.bleMgr = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue];
    });*/
    
    //begin a timer to check device status
    //start timer to check RSSI
    [scanTimer invalidate];
    scanTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(checkTimeoutDevices) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:scanTimer forMode:NSRunLoopCommonModes];

    self.bleMgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
}

-(void) stopScan
{
    NSLog(@"Stop Scan, ScanTimer Stoped");
    [scanTimer invalidate];
    [self.bleMgr stopScan];
}

-(void) connectCwCard: (CwCard *)cwCard
{
    if (cwCard.peripheral.state == CBPeripheralStateDisconnected) {
        //connect peripheral, with disconnect notify
        [self.bleMgr connectPeripheral:cwCard.peripheral options: @{CBConnectPeripheralOptionNotifyOnDisconnectionKey: @YES}];
        self.connectedCwCard = cwCard;
    }
}

-(void) disconnectCwCard
{
    if (self.connectedCwCard.peripheral.state == CBPeripheralStateConnected) {
        //disconnect peripheral
        [self.bleMgr cancelPeripheralConnection:self.connectedCwCard.peripheral];
    }
}

#pragma mark - CentralManager Delegates

// launch scan
-(void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    if (central.state < CBCentralManagerStatePoweredOn)
    {
        NSLog(@"BLE not enabled");
    } else {
        if ([self.delegate respondsToSelector:@selector(didCwManagerReady)]) {
            [self.delegate didCwManagerReady];
        }
    }
    
    
    NSLog(@"Did update state called... start scan");
    NSLog(@"scanForPeripherals");

    if (self.cwCards !=nil)
        [self.cwCards removeAllObjects];
    
    [self.bleMgr scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"A000"]]
                                        options: @{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
    
}

-(void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered [%@], Advertise [%@]", peripheral.name, [advertisementData objectForKey:@"kCBAdvDataLocalName"]);
    
    //update cwCards if CW found
    
    if ([peripheral.name containsString:@"CoolWallet"])
    {
        //[central stopScan];
        NSLog(@"CoolWallet Found");
        
        self.myPeri = peripheral;
        
        CwCard *cwItem = nil;
        
        //check if it's in the list already, update rssi only
        for (CwCard *cw in self.cwCards) {
            if ([cw.peripheral.identifier isEqual: peripheral.identifier]) {
                cwItem = cw;
                cwItem.rssi = RSSI;
                cwItem.lastUpdate = [NSDate date];
                if ([advertisementData objectForKey:@"kCBAdvDataLocalName"]!=nil)
                    cwItem.bleName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
                else
                    cwItem.bleName = peripheral.name;
            }
        }
        
        //add cw to card
        if (cwItem==nil) {
            cwItem = [[CwCard alloc] init];
            if ([advertisementData objectForKey:@"kCBAdvDataLocalName"]!=nil)
                cwItem.bleName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
            else
                cwItem.bleName = peripheral.name;
            cwItem.rssi = RSSI;
            cwItem.peripheral = peripheral;
            cwItem.lastUpdate = [NSDate date];
            [self.cwCards addObject:cwItem];
        }
    }
    
    //call discover peripheral delegate
    if ([self.delegate respondsToSelector:@selector(didScanCwCards:)]) {
        [self.delegate didScanCwCards:self.cwCards];
    }
}

-(void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%@ connecte fail. %@", peripheral.name, error);
    
    if ([self.delegate respondsToSelector:@selector(didConnectCwCardFail:)]) {
        [self.delegate didConnectCwCardFail:error];
    }
    
}

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"%@ connected", peripheral.name);
    
    [self stopScan];

    //start timer to check RSSI
    [rssiTimer invalidate];
    rssiTimer = [NSTimer timerWithTimeInterval:5.0 target:peripheral selector:@selector(readRSSI) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:rssiTimer forMode:NSRunLoopCommonModes];
    
    //prepare Cw Service
    self.connectedCwCard.delegate = self;

    //read stored file
//    [self.connectedCwCard loadCwCardFromFile];

    [self.connectedCwCard prepareService];
    
}

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%@ disconnected", peripheral.name);

    //stop timer to check RSSI
    [rssiTimer invalidate];
    
    if ([self.delegate respondsToSelector:@selector(didDisconnectCwCard:)]) {
        [self.delegate didDisconnectCwCard: self.connectedCwCard.bleName];
    }
    
    self.connectedCwCard = nil;

}

//CwCard Delegate
-(void) didPrepareService
{
    if ([self.delegate respondsToSelector:@selector(didConnectCwCard:)]) {
        [self.delegate didConnectCwCard:self.connectedCwCard];
    }
    
}


@end
