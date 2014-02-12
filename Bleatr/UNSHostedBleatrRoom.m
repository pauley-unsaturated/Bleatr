//
//  UNSHostedBleatrRoom.m
//  bleatr
//
//  Created by Mark Pauley on 2/9/14.
//  Copyright (c) 2014 Unsaturated. All rights reserved.
//

#import "UNSHostedBleatrRoom.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface UNSHostedBleatrRoom () <CBPeripheralManagerDelegate>
@property (nonatomic,readwrite,strong) CBPeripheralManager* peripheralManager;

@property (nonatomic,readwrite,strong) NSString* name;

@end

@implementation UNSHostedBleatrRoom {
  CBMutableService* _bleatrService;
  CBMutableCharacteristic* _toCentralCharacteristic;
  CBMutableCharacteristic* _toPeripheralCharacteristic;
  BOOL _isAdvertising;
  
  NSMutableArray* _bleats;
}

@synthesize name;

-(id)initWithName:(NSString*)name {
  self = [super init];
  if(!self) return nil;
  
  self.name = name;
  self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                   queue:dispatch_get_main_queue()
                                                                 options:@{}];
  self.peripheralManager.delegate = self;
  [self addService];
  _bleats = [NSMutableArray array];
  return self;
}

-(CBMutableService*)bleatrService {
  if(!_bleatrService) {
    _bleatrService = [[CBMutableService alloc] initWithType:[UNSBleatrRoom ServiceID]
                                                    primary:YES];
    _bleatrService.characteristics = @[[self toCentralCharacteristic], [self toPeripheralCharacteristic]];
  }
  return _bleatrService;
}

-(CBMutableCharacteristic*)toCentralCharacteristic {
  if(!_toCentralCharacteristic) {
    _toCentralCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[UNSBleatrRoom ToCentralServiceID]
                                                                  properties:( CBCharacteristicPropertyNotify
                                                                             | CBCharacteristicPropertyRead )
                                                                       value:nil
                                                                 permissions:CBAttributePermissionsReadable];
  }
  return _toCentralCharacteristic;
}

-(CBMutableCharacteristic*)toPeripheralCharacteristic {
  if(!_toPeripheralCharacteristic) {
    _toPeripheralCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[UNSBleatrRoom ToPeripheralServiceID]
                                                                     properties:( CBCharacteristicPropertyWrite
                                                                                | CBCharacteristicPropertyWriteWithoutResponse )
                                                                          value:nil
                                                                    permissions:CBAttributePermissionsWriteable];
  }
  return _toPeripheralCharacteristic;
}

-(void)addService {
  [self.peripheralManager addService:[self bleatrService]];
}

-(void)startAdvertising {
  if(!_isAdvertising) {
    _isAdvertising = YES;
    if(self.peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
      [self doStartAdvertising];
    }
  }
}

-(void)doStartAdvertising {
  [self.peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey: self.name,
                                             CBAdvertisementDataServiceUUIDsKey: @[[UNSBleatrRoom ServiceID]]} ];
}

-(void)stopAdvertising {
  if(_isAdvertising) {
    _isAdvertising = NO;
    [self.peripheralManager stopAdvertising];
  }
}

-(void)postBleat:(NSString *)bleat {
  if(bleat.length > 20) {
    bleat = [bleat substringWithRange:NSMakeRange(0, 20)];
  }
  // Drop the bleat!
  [self.peripheralManager updateValue:[bleat dataUsingEncoding:NSUTF8StringEncoding]
                    forCharacteristic:_toCentralCharacteristic
                 onSubscribedCentrals:nil];
  [self addBleat:@"BLEAT!"];
}

-(void)addBleat:(NSString *)bleat {
  [self willChangeValueForKey:@"bleats"];
  NSLog(@"BLEAT!");
  [_bleats addObject:bleat];
  [self didChangeValueForKey:@"bleats"];
}

// Implement callbacks!

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
  if(peripheral.state == CBPeripheralManagerStatePoweredOn) {
    NSLog(@"Peripheral Manager Powered On");
    if(_isAdvertising) {
      [self doStartAdvertising];
    }
  }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral
                 central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
  NSLog(@"Somebaaahdy connected! What are they going to say??");
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
  for (CBATTRequest* request in requests) {
    if([request.characteristic isEqual:_toPeripheralCharacteristic]) {
      NSString* bleatString = [[NSString alloc] initWithData:request.value
                                                    encoding:NSUTF8StringEncoding];
      [self addBleat:bleatString];
      [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }
    else {
      [peripheral respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
  }
}

@end
