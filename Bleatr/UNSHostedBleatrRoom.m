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

@property (nonatomic,readonly) CBMutableCharacteristic* toCentralCharactistic;
@property (nonatomic,readonly) CBMutableCharacteristic* toPeripheralCharactistic;

@property (nonatomic,readonly) NSMutableArray* subscribedCentrals;

@end

@implementation UNSHostedBleatrRoom {
  CBMutableService* _bleatrService;
  CBMutableCharacteristic* _toCentralCharacteristic;
  CBMutableCharacteristic* _toPeripheralCharacteristic;
  BOOL _isAdvertising;
  BOOL _isAvailable;
  
  NSMutableArray* _bleats;
}

// Required because the superclass (UNSBleatrRoom) declares the property as read-only.
@synthesize name = _name;

#pragma mark Initializer
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
  _subscribedCentrals = [NSMutableArray array];
  
  return self;
}

#pragma mark CBMutableService
-(CBMutableService*)bleatrService {
  if(!_bleatrService) {
    _bleatrService = [[CBMutableService alloc] initWithType:[UNSBleatrRoom ServiceID]
                                                    primary:YES];
    _bleatrService.characteristics = @[[self toCentralCharacteristic], [self toPeripheralCharacteristic]];
  }
  return _bleatrService;
}

#pragma mark CBMutableCharacteristics
-(CBMutableCharacteristic*)toCentralCharacteristic {
  if(!_toCentralCharacteristic) {
    // Outbound characteristic, is readable and can be set to notify of updates.
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
    // Inbound characteristic, is writable (with and without response)
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

-(BOOL)isConnected {
  // Let's just say we're connected if others may connect to us.
  return _isAvailable;
}


#pragma mark Advertisement Control
-(void)startAdvertising {
  if(!_isAdvertising) {
    _isAdvertising = YES;
    if(self.peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
      [self _startAdvertising];
    }
  }
}

-(void)_startAdvertising {
  // Actually start advertising (only call this when we know the peripheral manager is in the PoweredOn state!)
  [self.peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey: self.name,
                                             CBAdvertisementDataServiceUUIDsKey: @[[UNSBleatrRoom ServiceID]]} ];
}

-(void)stopAdvertising {
  if(_isAdvertising) {
    _isAdvertising = NO;
    [self.peripheralManager stopAdvertising];
  }
}

#pragma mark Data Transmission
-(void)postBleat:(NSString *)bleat {
  if(bleat.length > BLEATR_MAX_MESSAGE_LENGTH ) {
    // FIXME: UTF-8 may bust this.
    bleat = [bleat substringWithRange:NSMakeRange(0, BLEATR_MAX_MESSAGE_LENGTH)];
  }
  // Drop the bleat!
  [self.peripheralManager updateValue:[bleat dataUsingEncoding:NSUTF8StringEncoding]
                    forCharacteristic:_toCentralCharacteristic
                 onSubscribedCentrals:nil];
  [self addBleat:bleat];
}

#pragma mark Data Reception
-(void)addBleat:(NSString*)bleat {
  [self willChangeValueForKey:@"bleats"];
  NSLog(@"BLEAT!");
  [_bleats addObject:bleat];
  [self didChangeValueForKey:@"bleats"];
}

-(NSArray*)bleats {
  return _bleats;
}


#pragma mark - Peripheral Manager Delegate Callbacks
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager*)peripheral {
  if(peripheral.state == CBPeripheralManagerStatePoweredOn) {
    NSLog(@"Peripheral Manager Powered On");
    // Recall that we cannot actually begin advertising until the peripheral manager
    //  wakes up, or CoreBluetooth will become grumpy.
    // If we wanted to start advertising before, then actually start now.
    if(_isAdvertising) {
      [self _startAdvertising];
    }
    
    // Let anybody watching know that we are now awake.
    [self willChangeValueForKey:@"connected"];
    _isAvailable = YES;
    [self didChangeValueForKey:@"connected"];
  }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral
                 central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
  [self.subscribedCentrals addObject:central];
  // TODO: let clients know?
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral
                 central:(CBCentral *)central
didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
  [self.subscribedCentrals removeObject:central];
  // TODO: let clients know?
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
  // Corebluetooth requires that we respond to each and every write request.
  for (CBATTRequest* request in requests) {
    if([request.characteristic isEqual:_toPeripheralCharacteristic]) {
      // Somebody bleated at us, let our clients know, and save the bleat
      NSString* bleatString = [[NSString alloc] initWithData:request.value
                                                    encoding:NSUTF8StringEncoding];
      [self addBleat:bleatString];
      
      // Let the other end know that we got the bleat
      [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }
    else {
      // Somehow we're getting input on the wrong characteristic.
      [peripheral respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
  }
}

@end
