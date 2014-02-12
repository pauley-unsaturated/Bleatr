//
//  UNSBleatrRoom.m
//  Bleatr
//
//  Created by Mark Pauley on 2/9/14.
//  Copyright (c) 2014 Unsaturated. All rights reserved.
//

#import "UNSBleatrRoom.h"
#import <CoreBluetooth/CoreBluetooth.h>

NSString* const BleatrServiceID = @BLEATR_SERVICE_ID;
NSString* const BleatrToCentralServiceID = @BLEATR_TO_CENTRAL_ID;
NSString* const BleatrToPeripheralServiceID = @BLEATR_TO_PERIPHERAL_ID;

@implementation UNSBleatrRoom

+(CBUUID*)ServiceID {
  static CBUUID* serviceID = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    serviceID = [CBUUID UUIDWithString:BleatrServiceID];
  });
  return serviceID;
}
+(CBUUID*)ToCentralServiceID {
  static CBUUID* toCentralID = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    toCentralID = [CBUUID UUIDWithString:BleatrToCentralServiceID];
  });
  return toCentralID;
}
+(CBUUID*)ToPeripheralServiceID {
  static CBUUID* toPeripheralID = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    toPeripheralID = [CBUUID UUIDWithString:BleatrToPeripheralServiceID];
  });
  return toPeripheralID;
}

-(void)postBleat:(NSString *)bleat {
  assert(!"THIS BLEAT IS ABSTRACT, YO!");
}

@end
