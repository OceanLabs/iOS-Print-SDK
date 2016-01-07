//
//  OLPosterViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 31/7/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLSingleImageProductReviewViewController.h"

@class OLProduct;

@interface OLPosterViewController : OLSingleImageProductReviewViewController

+(void)changeOrderOfPhotosInArray:(NSMutableArray*)array forProduct:(OLProduct *)product;

@end
