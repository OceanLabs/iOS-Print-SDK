//
//  ReceiptViewController.h
//  Kite Print SDK
//
//  Created by Deon Botha on 10/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLPrintOrder;

@interface OLReceiptViewController : UITableViewController
- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;
@end
