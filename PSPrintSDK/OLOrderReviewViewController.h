//
//  OrderReviewViewController.h
//  Kite Print SDK
//
//  Created by Kostas Karayannis on 17/07/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OLImageEditorViewController.h>
#import "OLPrintOrder.h"

@class OLProduct;

@interface OLOrderReviewViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, OLImageEditorViewControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) OLProduct *product;
@property (strong, nonatomic) NSMutableArray* extraCopiesOfAssets;
@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (strong, nonatomic) NSArray *userSelectedPhotos;

- (void)updateTitleBasedOnSelectedPhotoQuanitity;
- (BOOL) shouldGoToCheckout;
- (void) doCheckout;
-(NSArray *) userSelectedPhotos;

@end
