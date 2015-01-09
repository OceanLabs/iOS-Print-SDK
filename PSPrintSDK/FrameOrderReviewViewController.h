//
//  FrameOrderReviewViewController.h
//  HuggleUp
//
//  Created by Kostas Karayannis on 23/07/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OrderReviewViewController.h"
#import <LXReorderableCollectionViewFlowLayout.h>

@interface FrameOrderReviewViewController : OrderReviewViewController <LXReorderableCollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end
