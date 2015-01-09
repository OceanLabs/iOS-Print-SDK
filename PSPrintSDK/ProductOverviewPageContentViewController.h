//
//  ProductOverviewViewController.h
//  Print Studio
//
//  Created by Deon Botha on 03/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLProduct;

@interface ProductOverviewPageContentViewController : UIViewController
@property (assign, nonatomic) NSUInteger pageIndex;
@property (strong, nonatomic) OLProduct *product;
@end
