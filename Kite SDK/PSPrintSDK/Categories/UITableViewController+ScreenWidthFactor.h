//
//  UITableViewController+ScreenWidthFactor.h
//  HuggleUp
//
//  Created by Konstadinos Karayannis on 30/9/14.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableViewController (ScreenWidthFactor)


// This is a hack for UITableView cells assuming 320 point width screens.
// Should be used in tableView:heightForRowAtIndexPath: to multiply with the old width to maintain the same aspect ratio
-(CGFloat) screenWidthFactor;

@end
