//
//  OLPosterSizeSelectionViewController.h
//  Photo Mosaic
//
//  Created by Alberto De Capitani on 23/09/2014.
//  Copyright (c) 2014 Ocean Labs App Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLPrintOrder.h"
#import "OLKiteViewController.h"

@interface OLPosterSizeSelectionViewController : UIViewController
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;

@property (copy, nonatomic) NSString *userEmail;
@property (copy, nonatomic) NSString *userPhone;

// A set of product template_id strings which if present will restrict which products ultimate show up in the product selection journey
@property (copy, nonatomic) NSArray/*<NSString>*/ *filterProducts;

@end
