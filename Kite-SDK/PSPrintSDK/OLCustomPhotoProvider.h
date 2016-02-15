//
//  OLCustomPhotoProvider.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 01/12/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS

#import <Foundation/Foundation.h>

@protocol KITAssetCollectionDataSource;
@protocol KITCustomAssetPickerController;

@interface OLCustomPhotoProvider : NSObject

@property (strong, nonatomic) NSArray<id<KITAssetCollectionDataSource>> *collections;
@property (strong, nonatomic) UIViewController<KITCustomAssetPickerController> *vc;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) UIImage *icon;

- (instancetype)initWithCollections:(NSArray<id<KITAssetCollectionDataSource>> *)collections name:(NSString *)name icon:(UIImage *)icon;
- (instancetype)initWithController:(UIViewController<KITCustomAssetPickerController> *)controller name:(NSString *)name icon:(UIImage *)icon;


@end

#endif
