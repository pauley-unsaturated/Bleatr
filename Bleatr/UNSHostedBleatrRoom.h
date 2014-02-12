//
//  UNSHostedBleatrRoom.h
//  bleatr
//
//  Created by Mark Pauley on 2/9/14.
//  Copyright (c) 2014 Unsaturated. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UNSBleatrRoom.h"

@interface UNSHostedBleatrRoom : UNSBleatrRoom

-(id)initWithName:(NSString*)name;

-(void)startAdvertising;
-(void)stopAdvertising;

@end
