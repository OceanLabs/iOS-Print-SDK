//
//  PrintPhoto.h
//  Print Studio
//
//  Created by Elliott Minns on 16/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OLImageEditorImage.h>
#import "OLAsset.h"

typedef enum {
    kPrintPhotoAssetTypeALAsset,
    kPrintPhotoAssetTypeOLAsset
} PrintPhotoAssetType;

@interface OLPrintPhoto : NSObject <OLImageEditorImage, OLAssetDataSource>

- (void)setThumbImageForImageView:(UIImageView *)imageView;
- (void) setThumbImageIdealSizeForImageView:(UIImageView *)imageView;

@property (nonatomic, assign, readonly) PrintPhotoAssetType type;
@property (nonatomic, strong) id asset;
@property (nonatomic, assign) CGSize serverImageSize;
@property (assign, nonatomic) CGSize transformFactor;

@end
