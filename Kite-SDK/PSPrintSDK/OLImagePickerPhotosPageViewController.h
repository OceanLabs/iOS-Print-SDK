//
//  OLImagePickerPhotosPageViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 15/07/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OLImagePickerPhotosPageViewController : UIViewController

/**
 *  Either an NSArray or PHFetchResult
 */
@property (strong, nonatomic) id assets;
@property (assign, nonatomic) NSInteger quantityPerItem;
@property (assign, nonatomic) NSInteger minimumPhotos;
@property (assign, nonatomic) NSInteger maximumPhotos;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end
