//
//  ProductHomeViewController.h
//  Kite Print SDK
//
//  Created by Elliott Minns on 12/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLPrintOrder.h"
#import "OLKiteViewController.h"

@interface OLProductHomeViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray *assets;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;

@property (copy, nonatomic) NSString *userEmail;
@property (copy, nonatomic) NSString *userPhone;

@end
