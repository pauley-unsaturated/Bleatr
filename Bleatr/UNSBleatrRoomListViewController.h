//
//  UNSMasterViewController.h
//  bleatr
//
//  Created by Mark Pauley on 2/9/14.
//  Copyright (c) 2014 Unsaturated. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UNSBleatrRoomDetailViewController;

@interface UNSBleatrRoomListViewController : UITableViewController

@property (strong, nonatomic) UNSBleatrRoomDetailViewController *detailViewController;

@end
