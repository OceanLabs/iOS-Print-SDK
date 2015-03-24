//
//  OLCaseSelectionViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 2/24/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLKitePrintSDK.h"

@interface OLProductTypeSelectionViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;
@property (assign, nonatomic) NSString *templateClass;

@end
