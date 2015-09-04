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
    kPrintPhotoAssetTypePHAsset,
    kPrintPhotoAssetTypeOLAsset,
    kPrintPhotoAssetTypeInstagramPhoto,
    kPrintPhotoAssetTypeFacebookPhoto
} PrintPhotoAssetType;

@protocol OLPrintPhotoDownloadDelegate <NSObject>

-(void)downloadDidProgressWithProgress:(double) progress error:(NSError *)error stop:(BOOL *)stop  info:(NSDictionary *)info;

@end

@interface OLPrintPhoto : NSObject <OLAssetDataSource>

- (void)setImageSize:(CGSize)destSize cropped:(BOOL)cropped completionHandler:(void(^)(UIImage *image))handler;
- (void)getImageWithProgress:(OLImageEditorImageGetImageProgressHandler)progressHandler completion:(OLImageEditorImageGetImageCompletionHandler)completionHandler;
- (void)unloadImage;

@property (nonatomic, assign, readonly) PrintPhotoAssetType type;
@property (nonatomic, strong) id asset;
@property (assign, nonatomic) NSInteger extraCopies;
@property (assign, nonatomic) CGRect cropImageRect;
@property (assign, nonatomic) CGRect cropImageFrame;
@property (assign, nonatomic) CGSize cropImageSize;
@property (strong, nonatomic) void (^downloadProgress)(double progress, NSError *error, BOOL *stop, NSDictionary *info);
@property (weak, nonatomic) id<OLPrintPhotoDownloadDelegate> delegate;

- (BOOL)isCropped;

@end
