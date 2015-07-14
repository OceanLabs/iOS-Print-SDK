//
//  OLPosterViewController.h
//  Photo Mosaic
//
//  Created by Konstadinos Karayannis on 27/10/14.
//  Copyright (c) 2014 Ocean Labs App Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLPrintOrder.h"
#import "OLProduct.h"
#import "OLKiteViewController.h"

@interface OLPosterViewController : UIViewController

@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (strong, nonatomic) OLProduct *product;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;

@end
