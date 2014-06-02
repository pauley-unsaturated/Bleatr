//
//  UNSBleatrRoomList.h
//  bleatr
//
//  Created by Mark Pauley on 2/9/14.
//  Copyright (c) 2014 Unsaturated. All rights reserved.
//

// The Room List is responsible for scanning for available rooms (via BLE)
//  Each of these rooms is an UNSBleatrRoom object that we can post messages to!
// One of the rooms is our own room, that we host.

#import <Foundation/Foundation.h>

#import "UNSBleatrRoom.h"

@interface UNSBleatrRoomList : NSObject

+(instancetype)sharedInstance;

@property (nonatomic,readonly) NSArray* rooms;

-(void)startScanning;
-(void)stopScanning;

-(void)connectToRoomWithIndex:(NSUInteger)index;

@end
