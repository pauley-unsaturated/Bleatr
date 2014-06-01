//
//  UNSHostedBleatrRoom.h
//  bleatr
//
//  Created by Mark Pauley on 2/9/14.
//  Copyright (c) 2014 Unsaturated. All rights reserved.
//

// Since BLE inverts the client / server relationship,
//  a peripheral is actually the 'server'.
// The hosted room therefore must advertise its availability
//  and manage a list of connected clients (publishing new messages to all of those clients).


#import <Foundation/Foundation.h>
#import "UNSBleatrRoom.h"

@interface UNSHostedBleatrRoom : UNSBleatrRoom

-(id)initWithName:(NSString*)name;

-(void)startAdvertising;
-(void)stopAdvertising;

@end
