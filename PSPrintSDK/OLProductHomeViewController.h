//
//  ProductHomeViewController.h
//  Print Studio
//
//  Created by Elliott Minns on 12/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLPrintOrder.h"

@interface OLProductHomeViewController : UITableViewController

@property (strong, nonatomic) OLPrintOrder *printOrder;

@end
