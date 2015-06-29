//
//  OLPhotobookViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/17/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLKitePrintSDK.h"

@interface OLPhotobookViewController : UIViewController

@property (strong, nonatomic) OLProduct *product;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;

@end
