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

@synthesize name;

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
  if(bleat.length > 20) {
    // FIXME: UTF-8 may bust this!
    bleat = [bleat substringWithRange:NSMakeRange(0, 20)];
  }
  [_bleats addObject:bleat];
  if(self.isConnected) {
    [self.peripheral writeValue:[bleat dataUsingEncoding:NSUTF8StringEncoding]
              forCharacteristic:self.toPeripheralCharacteristic
                           type:CBCharacteristicWriteWithoutResponse];
  }
}

-(void)addBleat:(NSString*)bleat {
  
}

-(NSArray*)bleats {
  return _bleats;
}


@end
