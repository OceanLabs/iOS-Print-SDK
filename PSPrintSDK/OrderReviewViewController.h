//
//  OrderReviewViewController.h
//  HuggleUp
//
//  Created by Kostas Karayannis on 17/07/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OLImageEditorViewController.h>
#import "OLPrintOrder.h"

@class OLProduct;

@interface OrderReviewViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, OLImageEditorViewControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) OLProduct *product;
@property (strong, nonatomic) NSMutableArray* extraCopiesOfAssets;
@property (strong, nonatomic) OLPrintOrder *printOrder;

- (void)updateTitleBasedOnSelectedPhotoQuanitity;
- (BOOL) shouldGoToCheckout;
- (void) doCheckout;
-(NSArray *) userSelectedPhotos;

@end
