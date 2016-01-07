//
//  FrameOrderReviewViewController.h
//  Kite Print SDK
//
//  Created by Kostas Karayannis on 23/07/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLOrderReviewViewController.h"
#import "LXReorderableCollectionViewFlowLayout.h"

@interface OLFrameOrderReviewViewController : OLOrderReviewViewController <LXReorderableCollectionViewDataSource, UICollectionViewDelegateFlowLayout>

+(void)reverseRowsOfPhotosInArray:(NSMutableArray*)array forProduct:(OLProduct *)product;

@end
