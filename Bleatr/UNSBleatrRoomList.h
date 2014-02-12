//
//  UNSBleatrRoomList.h
//  bleatr
//
//  Created by Mark Pauley on 2/9/14.
//  Copyright (c) 2014 Unsaturated. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UNSBleatrRoom.h"

@interface UNSBleatrRoomList : NSObject

@property (nonatomic,readonly) NSArray* rooms;

-(void)startScanning;
-(void)stopScanning;

-(void)connectToRoomWithIndex:(NSUInteger)index;

@end
