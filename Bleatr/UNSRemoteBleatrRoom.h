//
//  UNSRemoteBleatrRoom.h
//  bleatr
//
//  Created by Mark Pauley on 2/9/14.
//  Copyright (c) 2014 Unsaturated. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "UNSBleatrRoom.h"


@class CBPeripheral;
@class CBCharacteristic;
@class CBService;

@interface UNSRemoteBleatrRoom : UNSBleatrRoom

-(id)initWithPeripheral:(CBPeripheral*)peripheral name:(NSString*)peripheralName;
-(void)addBleat:(NSString*)bleat;

@property (nonatomic,readonly,strong)  CBPeripheral* peripheral;

@property (nonatomic,readwrite,strong) CBService* service;
@property (nonatomic,readwrite,strong) CBCharacteristic* toPeripheralCharacteristic;
@property (nonatomic,readwrite,strong) CBCharacteristic* toCentralCharacteristic;

@property (nonatomic,readwrite,strong) NSString* name;
@property (nonatomic,readonly,strong) NSArray* bleats;
@property (nonatomic,readwrite,assign,getter=isConnected) BOOL connected;

@end
