//
//  UNSBleatrRoomList.m
//  bleatr
//
//  Created by Mark Pauley on 2/9/14.
//  Copyright (c) 2014 Unsaturated. All rights reserved.
//

// This model object manages a list of Bleatr rooms.

//  The first room will always be your hosted room.
//  The remaining rooms are remote rooms, identified via BLE advertisement.

// Currently, the Room List is responsible for connecting to the remote rooms, this means
//  the room list must:
// 0) Start scanning for the Bleatr service
// 1) Initiate connection to a peripheral
// 2) Discover Services
// 3) Discover Characteristics
// 4) Set notify state on the known inbound characteristic
// 5) COMMENCE WITH THE BLEATING

#import "UNSBleatrRoomList.h"
#import "UNSRemoteBleatrRoom.h"
#import "UNSHostedBleatrRoom.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>

@interface UNSBleatrRoomList () <CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic,readwrite,strong) CBCentralManager* centralManager;
@end

@implementation UNSBleatrRoomList {
  BOOL _isScanning;
  NSMutableArray* _rooms;
  UNSHostedBleatrRoom* _hostedRoom;
  NSMutableDictionary* _roomsByPeripheral;
}

+(instancetype)sharedInstance {
  static UNSBleatrRoomList* _sharedRoomList = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedRoomList = [[UNSBleatrRoomList alloc] init];
  });
  return _sharedRoomList;
}

-(id)init {
  self = [super init];
  if(!self) return nil;
  self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
  _rooms = [NSMutableArray array];
  _hostedRoom = [[UNSHostedBleatrRoom alloc] initWithName:[UIDevice currentDevice].name];
  [_rooms addObject:_hostedRoom];
  [_hostedRoom startAdvertising];
  _roomsByPeripheral = [NSMutableDictionary dictionary];
  return self;
}

-(void)dealloc {
  [_hostedRoom stopAdvertising];
}

-(void)startScanning {
  if(!_isScanning) {
    _isScanning = YES;
    if([self.centralManager state] == CBCentralManagerStatePoweredOn) {
      [self doStartScan];
    }
  }
}

-(void)doStartScan {
  [self.centralManager scanForPeripheralsWithServices:@[[UNSBleatrRoom ServiceID]] options:@{}];
}

-(void)stopScanning {
  if(_isScanning) {
    _isScanning = NO;
    [self.centralManager stopScan];
  }
}

//Connection 1) Initiate connection to peripheral.
-(void)connectToRoomWithIndex:(NSUInteger)index {
  if(index > 0 && index < _rooms.count) {
    UNSRemoteBleatrRoom* remoteRoom = (UNSRemoteBleatrRoom*)_rooms[index];
    if(!remoteRoom.isConnected) {
      NSLog(@"Connecting to peripheral %@", remoteRoom.peripheral);
      [self.centralManager connectPeripheral:remoteRoom.peripheral options:nil];
    }
    else {
      NSLog(@"Already connected to %@", remoteRoom.name);
    }
  }
}

-(void)roomConnected:(UNSRemoteBleatrRoom*)remoteRoom {
  NSLog(@"Connected to remote room %@", remoteRoom.name);
}

-(void)updateServiceForRoom:(UNSRemoteBleatrRoom*)remoteRoom withPeripheral:(CBPeripheral*)peripheral {
  // Find the service we care about, and save it.
  for(CBService* service in peripheral.services) {
    if([service.UUID isEqual:[UNSBleatrRoom ServiceID]]) {
      NSLog(@"Found Bleatr Service!");
      remoteRoom.service = service;
    }
  }
}

#pragma - CBCentralManager callbacks

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
  if(central.state == CBCentralManagerStatePoweredOn) {
    if(_isScanning) {
      // We may have started scanning before bluetooth turned on.
      // if so: start scanning now.
      [self doStartScan];
    }
  }
}

-(void)centralManager:(CBCentralManager *)central
didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary *)advertisementData
                 RSSI:(NSNumber *)RSSI {
  NSString* name = advertisementData[CBAdvertisementDataLocalNameKey];
  if(_roomsByPeripheral[peripheral]) {
    // We actually already know about this room..
    NSLog(@"Was reminded of room %@", name);
    return;
  }
  UNSRemoteBleatrRoom* newRoom = [[UNSRemoteBleatrRoom alloc] initWithPeripheral:peripheral name:name];
  [self updateServiceForRoom:newRoom withPeripheral:peripheral];
  // Notify our observers that the room was discovered.
  [self willChangeValueForKey:@"rooms"];
  [_rooms addObject:newRoom];
  [_roomsByPeripheral setObject:newRoom forKey:peripheral];
  peripheral.delegate = self;
  [self didChangeValueForKey:@"rooms"];
}

// Connection 2) Discover Services, now that we're connected.
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  NSLog(@"Did Connect Peripheral %@", peripheral);
  UNSRemoteBleatrRoom* remoteRoom = _roomsByPeripheral[peripheral];
  [self updateServiceForRoom:remoteRoom withPeripheral:peripheral];
  if(!remoteRoom.service) {
    [peripheral discoverServices:@[[UNSBleatrRoom ServiceID]]];
  }
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  NSLog(@"Did Disconnect Peripheral %@", peripheral);
  UNSHostedBleatrRoom* remoteRoom = _roomsByPeripheral[peripheral];
  [self willChangeValueForKey:NSStringFromSelector(@selector(rooms))];
  [_rooms removeObject:remoteRoom];
  [_roomsByPeripheral removeObjectForKey:peripheral];
  [self didChangeValueForKey:NSStringFromSelector(@selector(rooms))];
}


#pragma - CBPeripheral callbacks

// Connection 3) Discover Characteristics
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
  if(error) {
    NSLog(@"ERROR discoverServices: %@", error);
    return;
  }
  NSLog(@"Found services for %@", peripheral);
  UNSRemoteBleatrRoom* remoteRoom = _roomsByPeripheral[peripheral];
  [self updateServiceForRoom:remoteRoom withPeripheral:peripheral];
  if(remoteRoom.service
     && !(remoteRoom.toCentralCharacteristic && remoteRoom.toPeripheralCharacteristic)) {
    // Found the service, need to discover the characteristics.
    [peripheral discoverCharacteristics:@[[UNSBleatrRoom ToPeripheralServiceID],
                                          [UNSBleatrRoom ToCentralServiceID]]
                             forService:remoteRoom.service];
  }
}

// Connection 4) Save the Characteristics and set Notify if needed.
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
            error:(NSError *)error {
  if(error) {
    NSLog(@"ERROR (didDiscoverServices): %@", error);
    return;
  }
  UNSRemoteBleatrRoom* remoteRoom = _roomsByPeripheral[peripheral];
  if([service.UUID isEqual:[UNSBleatrRoom ServiceID]]) {
    for (CBCharacteristic* characteristic in service.characteristics) {
      if([characteristic.UUID isEqual:[UNSBleatrRoom ToPeripheralServiceID]]) {
        remoteRoom.toPeripheralCharacteristic = characteristic;
      }
      else if([characteristic.UUID isEqual:[UNSBleatrRoom ToCentralServiceID]]) {
        remoteRoom.toCentralCharacteristic = characteristic;
      }
    }
    
    if(remoteRoom.toCentralCharacteristic && remoteRoom.toPeripheralCharacteristic) {
      // Almost connected, just need to set notify on the toCentral characteristic in order to
      //  receive messages asynchronously.
      [remoteRoom.peripheral setNotifyValue:YES forCharacteristic:remoteRoom.toCentralCharacteristic];
    }
  }
}

// Connection 5) Notify was set, we are done!
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  if(error) {
    NSLog(@"ERROR (didUpdateNotificationState): %@", error);
    return;
  }
  
  UNSRemoteBleatrRoom* remoteRoom = _roomsByPeripheral[peripheral];
  if([characteristic isEqual:remoteRoom.toCentralCharacteristic]) {
    if(characteristic.isNotifying) {
      // Woo Hoo, we're done!  Let everybody know about it.
      [self roomConnected:remoteRoom];
    }
  }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  if(error) {
    NSLog(@"ERROR (didUpdateValueForCharacteristic): %@", error);
    return;
  }
  NSString* bleatPayload = [[NSString alloc] initWithBytes:characteristic.value.bytes length:characteristic.value.length encoding:NSUTF8StringEncoding];
  UNSRemoteBleatrRoom* remoteRoom = _roomsByPeripheral[peripheral];
  [remoteRoom addBleat:bleatPayload];
}

@end
