//
//  ReceiptViewController.h
//  Kite Print SDK
//
//  Created by Deon Botha on 10/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLCheckoutDelegate.h"

@class OLPrintOrder;

@interface OLReceiptViewController : UITableViewController

@property (weak, nonatomic) id<OLCheckoutDelegate> delegate;

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;

@end
