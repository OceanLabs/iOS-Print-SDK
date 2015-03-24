//
//  PrintPhoto.h
//  Print Studio
//
//  Created by Elliott Minns on 16/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OLAsset.h"

typedef void (^OLImageEditorImageGetImageCompletionHandler)(UIImage *image);
typedef void (^OLImageEditorImageGetImageProgressHandler)(float progress);

typedef enum {
    kPrintPhotoAssetTypeALAsset,
    kPrintPhotoAssetTypeOLAsset,
    kPrintPhotoAssetTypeInstagramPhoto,
    kPrintPhotoAssetTypeFacebookPhoto
} PrintPhotoAssetType;

@interface OLPrintPhoto : NSObject <OLAssetDataSource>

- (void) setImageIdealSizeForImageView:(UIImageView *)imageView highQuality:(BOOL)highQuality;
- (void)getImageWithProgress:(OLImageEditorImageGetImageProgressHandler)progressHandler completion:(OLImageEditorImageGetImageCompletionHandler)completionHandler;
- (void)unloadImage;

@property (nonatomic, assign, readonly) PrintPhotoAssetType type;
@property (nonatomic, strong) id asset;
@property (assign, nonatomic) CGSize transformFactor;

@end
