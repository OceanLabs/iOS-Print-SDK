//
//  PaymentViewController.h
//  Print Studio
//
//  Created by Deon Botha on 06/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLPrintOrder;

@interface OLPaymentViewController : UIViewController
- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;
@end
