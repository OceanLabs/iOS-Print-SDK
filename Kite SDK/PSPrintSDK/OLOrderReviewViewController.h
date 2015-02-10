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

@class OLProduct;

@interface OLOrderReviewViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, OLScrollCropViewControllerDelegate>

@property (nonatomic, strong) OLProduct *product;
@property (strong, nonatomic) NSMutableArray *extraCopiesOfAssets;
@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;

- (void)updateTitleBasedOnSelectedPhotoQuanitity;
- (BOOL) shouldGoToCheckout;
- (void) doCheckout;

@end
