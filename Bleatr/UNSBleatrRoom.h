//
//  UNSBleatrRoom.h
//  Bleatr
//
//  Created by Mark Pauley on 2/9/14.
//  Copyright (c) 2014 Unsaturated. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * Bleatr BLE GATT Service definition
 */
// Bleatr Service UUID
#define BLEATR_SERVICE_ID       "1A3E65D0-26D3-4BCC-A85E-545D04FEB5A0"
extern NSString* const BleatrServiceID;

// Bleatr inbound characteristic UUID
#define BLEATR_TO_CENTRAL_ID    "1A3E65D0-26D3-4BCC-A85E-545D04FEB5A1"
extern NSString* const BleatrToCentralServiceID;

// Bleatr outbound characteristic UUID
#define BLEATR_TO_PERIPHERAL_ID "1A3E65D0-26D3-4BCC-A85E-545D04FEB5A2"
extern NSString* const BleatrToPeripheralServiceID;

// BLE enforces an MTU of 20 bytes at least
#define BLEATR_MAX_MESSAGE_LENGTH 20


@class CBUUID;

@interface UNSBleatrRoom : NSObject

+(CBUUID*)ServiceID;
+(CBUUID*)ToCentralServiceID;
+(CBUUID*)ToPeripheralServiceID;

@property (nonatomic,readonly,getter = isConnected) BOOL connected;
// Human readable name of this room
@property (nonatomic,readonly,strong) NSString* name;

// List of 'bleats' in NSString form
@property (nonatomic,readonly,weak) NSArray* bleats;


-(void)postBleat:(NSString*)bleat;



@end
