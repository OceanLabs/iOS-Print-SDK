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

@interface OLProductHomeViewController : UICollectionViewController

@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;

@property (copy, nonatomic) NSString *userEmail;
@property (copy, nonatomic) NSString *userPhone;

// A set of product template_id strings which if present will restrict which products ultimate show up in the product selection journey
@property (copy, nonatomic) NSArray/*<NSString>*/ *filterProducts;

@end
