//
//  OLCustomPhotoProvider.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 01/12/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS

#import "OLCustomPhotoProvider.h"

@implementation OLCustomPhotoProvider

- (instancetype)initWithCollections:(NSArray<id<KITAssetCollectionDataSource>> *)collections name:(NSString *)name icon:(UIImage *)icon{
    if (self = [super init]){
        _collections = collections;
        _icon = icon;
        _name = name;
    }
    return self;
}

- (instancetype)initWithController:(UIViewController<KITCustomAssetPickerController> *)controller name:(NSString *)name icon:(UIImage *)icon{
    if (self = [super init]){
        _vc = controller;
        _icon = icon;
        _name = name;
    }
    return self;
}

@end

#endif
