//
//  OLSingleImageProductReviewViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 2/24/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OLKitePrintSDK.h"
#import "RMImageCropper.h"

@class OLProduct;

@interface OLSingleImageProductReviewViewController : UIViewController

@property (strong, nonatomic) OLProduct *product;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;

@end
