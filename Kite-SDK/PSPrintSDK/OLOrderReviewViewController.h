//
//  OrderReviewViewController.h
//  Kite Print SDK
//
//  Created by Kostas Karayannis on 17/07/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLPrintOrder.h"
#import "OLScrollCropViewController.h"
#import "OLKiteViewController.h"

@class OLProduct;

@interface OLOrderReviewViewController : UICollectionViewController <UINavigationControllerDelegate, OLScrollCropViewControllerDelegate>

@property (nonatomic, strong) OLProduct *product;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *checkoutPhotos;
@property (strong, nonatomic) id<OLPrintJob> editingPrintJob;

- (void)saveJobWithCompletionHandler:(void(^)())handler;

@end
