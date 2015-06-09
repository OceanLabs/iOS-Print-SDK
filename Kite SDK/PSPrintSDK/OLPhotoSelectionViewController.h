//
//  PhotoSelectionViewController.h
//  Print Studio
//
//  Created by Elliott Minns on 12/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLProduct.h"
#import "OLKiteViewController.h"

@interface OLPhotoSelectionViewController : UIViewController
@property (nonatomic, strong) OLProduct *product;
@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;
@end
