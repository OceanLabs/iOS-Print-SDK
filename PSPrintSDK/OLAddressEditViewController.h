//
//  OLAddressEditViewController.h
//  PS SDK
//
//  Created by Deon Botha on 04/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLAddress;

@interface OLAddressEditViewController : UITableViewController
- (id)initWithAddress:(OLAddress *)address;
@end
