//
//  OLImagePickerProvider.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 22/07/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OLImagePickerProviderCollection.h"

typedef enum {
    OLImagePickerProviderTypeCustom,
    OLImagePickerProviderTypeApp,
    OLImagePickerProviderTypePhotoLibrary,
    OLImagePickerProviderTypeFacebook,
    OLImagePickerProviderTypeInstagram,
    OLImagePickerProviderTypeQRCode
} OLImagePickerProviderType;

@interface OLImagePickerProvider : NSObject

@property (strong, nonatomic) NSArray<OLImagePickerProviderCollection *> *collections;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) UIImage *icon;
@property (assign, nonatomic) OLImagePickerProviderType providerType;

- (instancetype)initWithCollections:(NSArray<id<NSFastEnumeration>> *)collections name:(NSString *)name icon:(UIImage *)icon;

@end
