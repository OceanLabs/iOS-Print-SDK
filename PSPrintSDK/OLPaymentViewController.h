//
//  PaymentViewController.h
//  Print Studio
//
//  Created by Deon Botha on 06/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLCheckoutDelegate.h"

@class OLPrintOrder;

@interface OLPaymentViewController : UIViewController

@property (strong, nonatomic) id<OLCheckoutDelegate> delegate;

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;
@end
