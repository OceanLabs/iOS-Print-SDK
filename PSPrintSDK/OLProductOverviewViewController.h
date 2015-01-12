//
//  ProductOverviewViewController.h
//  Print Studio
//
//  Created by Deon Botha on 03/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLPrintOrder.h"

@class OLProduct;

@interface OLProductOverviewViewController : UIViewController
@property (strong, nonatomic) OLProduct *product;
@property (strong, nonatomic) OLPrintOrder *printOrder;
@end
