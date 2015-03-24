//
//  OLPosterSizeSelectionViewController.h
//  Photo Mosaic
//
//  Created by Alberto De Capitani on 23/09/2014.
//  Copyright (c) 2014 Ocean Labs App Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLPrintOrder.h"
#import "OLKiteViewController.h"

@interface OLPosterSizeSelectionViewController : UIViewController
@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;

@end
