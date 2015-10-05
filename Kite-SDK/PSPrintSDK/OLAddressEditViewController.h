//
//  OLAddressEditViewController.h
//  Kite SDK
//
//  Created by Deon Botha on 04/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLAddressPickerController.h"

@class OLAddress;

@interface OLAddressEditViewController : UITableViewController
@property (weak, nonatomic) id<UINavigationControllerDelegate, OLAddressPickerControllerDelegate> delegate;

- (id)initWithAddress:(OLAddress *)address;
@end
