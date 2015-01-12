//
//  KiteViewController.h
//  Kite Print SDK
//
//  Created by Konstadinos Karayannis on 12/24/14.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLPrintOrder;

@interface OLKiteViewController : UIViewController

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;

@end
