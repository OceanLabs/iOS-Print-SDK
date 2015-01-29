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

@class OLProduct;

@interface OLOrderReviewCollectionViewViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, OLScrollCropViewControllerDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) OLProduct *product;
@property (strong, nonatomic) NSMutableArray* extraCopiesOfAssets;
@property (strong, nonatomic) NSArray *assets;
@property (strong, nonatomic) NSArray *userSelectedPhotos;

- (void)updateTitleBasedOnSelectedPhotoQuanitity;
- (BOOL) shouldGoToCheckout;
- (void) doCheckout;
-(NSArray *) userSelectedPhotos;

@end
