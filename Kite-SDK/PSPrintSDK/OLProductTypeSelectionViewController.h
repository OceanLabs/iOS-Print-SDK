//
//  OLCaseSelectionViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 2/24/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLKitePrintSDK.h"

@interface OLProductTypeSelectionViewController : UICollectionViewController

@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;
@property (assign, nonatomic) NSString *templateClass;

// A set of product template_id strings which if present will restrict which products ultimate show up in the product selection journey
@property (copy, nonatomic) NSArray<NSString *> *filterProducts;

@end
