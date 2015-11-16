//
//  PrintPhoto.h
//  Print Studio
//
//  Created by Elliott Minns on 16/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OLAsset.h"
#import "OLPhotoEdits.h"

typedef void (^OLImageEditorImageGetImageCompletionHandler)(UIImage *image);
typedef void (^OLImageEditorImageGetImageProgressHandler)(float progress);

typedef enum {
    kPrintPhotoAssetTypeALAsset,
    kPrintPhotoAssetTypePHAsset,
    kPrintPhotoAssetTypeOLAsset,
    kPrintPhotoAssetTypeInstagramPhoto,
    kPrintPhotoAssetTypeFacebookPhoto
} PrintPhotoAssetType;

@interface OLPrintPhoto : NSObject <OLAssetDataSource>

- (void)setImageSize:(CGSize)destSize cropped:(BOOL)cropped progress:(OLImageEditorImageGetImageProgressHandler)progressHandler completionHandler:(void(^)(UIImage *image))handler;
- (void)getImageWithProgress:(OLImageEditorImageGetImageProgressHandler)progressHandler completion:(OLImageEditorImageGetImageCompletionHandler)completionHandler;
- (void)unloadImage;
+ (void)calcScreenScaleForTraitCollection:(UITraitCollection *)traitCollection;

@property (nonatomic, assign, readonly) PrintPhotoAssetType type;
@property (nonatomic, strong) id asset;
@property (assign, nonatomic) NSInteger extraCopies;
@property (strong, nonatomic) OLPhotoEdits *edits;

@end
