//
//  OLSingleImageProductReviewViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 2/24/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OLKitePrintSDK.h"

@class OLProduct;

@interface OLSingleImageProductReviewViewController : UIViewController

@property (strong, nonatomic) OLProduct *product;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIButton *ctaButton;

@property (strong, nonatomic) id<OLPrintJob> editingPrintJob;

- (void)saveJobWithCompletionHandler:(void(^)())handler;

@end
