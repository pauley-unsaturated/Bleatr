//
//  UNSRemoteBleatrRoom.m
//  bleatr
//
//  Created by Mark Pauley on 2/9/14.
//  Copyright (c) 2014 Unsaturated. All rights reserved.
//

#import "UNSRemoteBleatrRoom.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface UNSRemoteBleatrRoom ()
@property (nonatomic,readwrite,strong) CBPeripheral* peripheral;
@end

@implementation UNSRemoteBleatrRoom {
  NSMutableArray* _bleats;
}

// Abusing property synthesis to make these writable on the subclass
//  hence the explicit synthesize. My appologies!
@synthesize name = _name;
@synthesize connected = _connected;

-(id)initWithPeripheral:(CBPeripheral*)peripheral {
  self = [super init];
  if(!self)return nil;
  self.peripheral = peripheral;
  self.name = peripheral.name;
  _bleats = [NSMutableArray array];
  return self;
}

-(BOOL)isConnected {
  return self.toCentralCharacteristic.isNotifying == YES;
}

-(void)postBleat:(NSString *)bleat {
  if(bleat.length > BLEATR_MAX_MESSAGE_LENGTH) {
    // FIXME: UTF-8 may bust this!
    //  We need to make sure the number of bytes is at most BLEATR_MAX_MESSAGE_LENGTH total.
    bleat = [bleat substringWithRange:NSMakeRange(0, BLEATR_MAX_MESSAGE_LENGTH)];
  }
  NSData* bleatData = [bleat dataUsingEncoding:NSUTF8StringEncoding];
  if(self.isConnected) {
    [self _postBleat:bleatData];
  }
}

-(void)_postBleat:(NSData*)bleatData {
  [self.peripheral writeValue:bleatData
            forCharacteristic:self.toPeripheralCharacteristic
                         type:CBCharacteristicWriteWithoutResponse];
}

-(void)addBleat:(NSString*)bleat {
  [self willChangeValueForKey:NSStringFromSelector(@selector(bleats))];
  [_bleats addObject:bleat];
  [self didChangeValueForKey:NSStringFromSelector(@selector(bleats))];
}

-(NSArray*)bleats {
  return _bleats;
}


@end
