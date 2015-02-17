//
//  OLOrderReviewCollectionViewViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 1/29/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLPrintOrder.h"
#import "OLScrollCropViewController.h"
#import "OLKitePrintSDK.h"

@class OLProduct;

@interface OLOrderReviewCollectionViewViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, OLScrollCropViewControllerDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) OLProduct *product;
@property (strong, nonatomic) NSMutableArray* extraCopiesOfAssets;
@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;

- (void)updateTitleBasedOnSelectedPhotoQuanitity;
- (BOOL) shouldGoToCheckout;
- (void) doCheckout;

@end
