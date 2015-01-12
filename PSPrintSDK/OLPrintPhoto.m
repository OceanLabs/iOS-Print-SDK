//
//  PrintPhoto.m
//  Print Studio
//
//  Created by Elliott Minns on 16/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import "OLPrintPhoto.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <OLInstagramImage.h>
#import <OLFacebookImage.h>
#import <UIImageView+FadeIn.h>
#import <SDWebImageManager.h>
#import "OLAsset+Private.h"

static NSString *const kKeyType = @"co.oceanlabs.psprintstudio.kKeyType";
static NSString *const kKeyAsset = @"co.oceanlabs.psprintstudio.kKeyAsset";
static NSString *const kKeyCropTransform = @"co.oceanlabs.psprintstudio.kKeyCropTransform";
static NSString *const kKeyServerImageSize = @"co.oceanlabs.psprintstudio.kKeyServerImageSize";

@implementation ALAsset (isEqual)

- (NSURL*)defaultURL {
    return [self valueForProperty:ALAssetPropertyAssetURL];
}

- (BOOL)isEqual:(id)obj {
    if(![obj isKindOfClass:[ALAsset class]])
        return NO;
    
    NSURL *u1 = [self defaultURL];
    NSURL *u2 = [obj defaultURL];
    
    return ([u1 isEqual:u2]);
}

@end

@interface OLPrintPhoto ()
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, assign) CGAffineTransform cropTransform;
@property (nonatomic, strong) UIImage *cachedCroppedThumbnailImage;
@end

@implementation OLPrintPhoto

- (id)init {
    if (self = [super init]) {
        self.cropTransform = CGAffineTransformIdentity;
    }
    
    return self;
}

- (void)setTransform:(CGAffineTransform)transform {
    self.cropTransform = transform;
}

- (CGAffineTransform)transform {
    return self.cropTransform;
}

- (BOOL)transformed {
    return !CGAffineTransformIsIdentity(self.cropTransform);
}

- (void)setTransformed:(BOOL)transformed {
    
}

- (void)setAsset:(id)asset {
    _asset = asset;
    if ([asset isKindOfClass:[ALAsset class]]) {
        _type = kPrintPhotoAssetTypeALAsset;
    } else if ([asset isKindOfClass:[OLInstagramImage class]]) {
        _type = kPrintPhotoAssetTypeOLInstagramPhoto;
        //[self downloadFullImageWithProgress:nil completion:nil];
    } else if ([asset isKindOfClass:[OLFacebookImage class]]) {
        _type = kPrintPhotoAssetTypeOLFacebookPhoto;
        //[self downloadFullImageWithProgress:nil completion:nil];
    } else if ([asset isKindOfClass:[OLAsset class]]){
        _type = kPrintPhotoAssetTypeOLAsset;
    }
}

- (void) setThumbImageIdealSizeForImageView:(UIImageView *)imageView {
    if (!CGAffineTransformIsIdentity(self.transform) || self.type == kPrintPhotoAssetTypeALAsset) {
        if (self.cachedCroppedThumbnailImage) {
            imageView.image = self.cachedCroppedThumbnailImage;
        } else {
            [OLImageEditorImage croppedImageWithEditorImage:self size:CGSizeMake(imageView.frame.size.width * [UIScreen mainScreen].scale, imageView.frame.size.height * [UIScreen mainScreen].scale) progress:nil completion:^(UIImage *image) {
//                NSAssert([NSThread isMainThread], @"oops assumption about being on the main thread is wrong");
                self.cachedCroppedThumbnailImage = image;
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    imageView.image = image;
                });
                
            }];
        }
    } else {
        if (self.type == kPrintPhotoAssetTypeOLInstagramPhoto) {
            [imageView setAndFadeInImageWithURL:[self.asset fullURL]];
        } else if (self.type == kPrintPhotoAssetTypeOLFacebookPhoto) {
            OLFacebookImage *fbImage = self.asset;
            [imageView setAndFadeInImageWithURL:[fbImage bestURLForSize:CGSizeMake(imageView.frame.size.width * [UIScreen mainScreen].scale, imageView.frame.size.height * [UIScreen mainScreen].scale)]];
        } else if (self.type == kPrintPhotoAssetTypeOLAsset){
            OLAsset *asset = (OLAsset *)self.asset;
            
            if (asset.assetType == kOLAssetTypeRemoteImageURL){
                [imageView setAndFadeInImageWithURL:[self.asset imageURL]];
            }
            else{
                [asset dataWithCompletionHandler:^(NSData *data, NSError *error){
                    OLImageEditorImage *editorImage = [OLImageEditorImage imageWithImage:[UIImage imageWithData:data]];
                    [OLImageEditorImage croppedImageWithEditorImage:editorImage size:CGSizeMake(imageView.frame.size.width * [UIScreen mainScreen].scale, imageView.frame.size.height * [UIScreen mainScreen].scale) progress:nil completion:^(UIImage *image) {
                        self.cachedCroppedThumbnailImage = image;
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            imageView.image = image;
                        });
                    }];
                    
                }];
            }
        }
    }
}

- (void)setThumbImageForImageView:(UIImageView *)imageView {
    if (!CGAffineTransformIsIdentity(self.transform)) {
        if (self.cachedCroppedThumbnailImage) {
            imageView.image = self.cachedCroppedThumbnailImage;
        } else {
            [OLImageEditorImage croppedImageWithEditorImage:self size:CGSizeMake(215, 215) progress:nil completion:^(UIImage *image) {
                NSAssert([NSThread isMainThread], @"oops assumption about being on the main thread is wrong");
                self.cachedCroppedThumbnailImage = image;
                imageView.image = image;
            }];
        }
    } else {
        if (self.type == kPrintPhotoAssetTypeALAsset) {
            ALAsset *asset = (ALAsset *)self.asset;
            imageView.image = [UIImage imageWithCGImage:asset.thumbnail];
        } else if (self.type == kPrintPhotoAssetTypeOLInstagramPhoto) {
            [imageView setAndFadeInImageWithURL:[self.asset thumbURL]];
        } else if (self.type == kPrintPhotoAssetTypeOLFacebookPhoto) {
            OLFacebookImage *fbImage = self.asset;
            [imageView setAndFadeInImageWithURL:[fbImage bestURLForSize:CGSizeMake(220, 220)]];
        }
    }
}

- (BOOL)isEqual:(id)object {
    BOOL retVal = [object class] == [self class];
    if (retVal) {
        OLPrintPhoto *other = object;
        retVal &= (other.type == self.type);
        retVal &= ([other.asset isEqual:self.asset]);
    }
    
    return retVal;
}

- (void)downloadFullImageWithProgress:(OLImageEditorImageGetImageProgressHandler)progressHandler completion:(OLImageEditorImageGetImageCompletionHandler)completionHandler {
    if (progressHandler) progressHandler(0.05f); // small bit of fake inital progress to get progress bars displaying
    [[SDWebImageManager sharedManager] downloadWithURL:[self.asset fullURL]
                                               options:0
                                              progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      if (progressHandler) {
                                                          progressHandler(MAX(0.05f, receivedSize / (float) expectedSize));
                                                      }
                                                  });
                                              }
                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     if (finished) {
                                                         if (completionHandler) completionHandler(image);
                                                     }
                                                 });
                                             }];
}

#pragma mark - OLImageEditorImage protocol methods

- (void)getImageWithProgress:(OLImageEditorImageGetImageProgressHandler)progressHandler completion:(OLImageEditorImageGetImageCompletionHandler)completionHandler {
    if (self.type == kPrintPhotoAssetTypeALAsset) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_async(queue, ^(void){
            UIImage* image = [UIImage imageWithCGImage:[[self.asset defaultRepresentation] fullScreenImage]];
            completionHandler(image);
        });
    } else if (self.type == kPrintPhotoAssetTypeOLFacebookPhoto || self.type == kPrintPhotoAssetTypeOLInstagramPhoto) {
        [self downloadFullImageWithProgress:progressHandler completion:completionHandler];
    }
}

- (void)unloadImage {
    self.cachedCroppedThumbnailImage = nil; // we can always recreate this
}

- (CGRect)cropRect {
    NSAssert(NO, @"Oops");
    return CGRectZero;
}

- (void)setCropRect:(CGRect)cropRect {
    NSAssert(NO, @"Oops");
}


#pragma mark - OLAssetDataSource protocol methods

- (NSString *)mimeType {
    return kOLMimeTypeJPEG;
}

- (void)dataLengthWithCompletionHandler:(GetDataLengthHandler)handler {
    if (self.type == kPrintPhotoAssetTypeALAsset) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler([self.asset defaultRepresentation].size, nil);
        });
    } else if (self.type == kPrintPhotoAssetTypeOLFacebookPhoto || self.type == kPrintPhotoAssetTypeOLInstagramPhoto) {
        [[SDWebImageManager sharedManager] downloadWithURL:[self.asset fullURL]
                                                   options:0
                                                  progress:nil
                                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                                     if (finished) {
                                                         NSUInteger length = UIImageJPEGRepresentation([OLImageEditorImage croppedImageWithImage:image transform:self.transform size:self.serverImageSize], 0.7).length;
                                                         handler(length, error);
                                                     }
                                                 }];
    }
}

- (void)dataWithCompletionHandler:(GetDataHandler)handler {
    if (self.type == kPrintPhotoAssetTypeALAsset) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ALAssetRepresentation *rep = [self.asset defaultRepresentation];
            
            UIImageOrientation orientation = UIImageOrientationUp;
            NSNumber* orientationValue = [self.asset valueForProperty:@"ALAssetPropertyOrientation"];
            if (orientationValue != nil) {
                orientation = [orientationValue intValue];
            }

            UIImage *image = [UIImage imageWithCGImage:[rep fullResolutionImage] scale:rep.scale orientation:orientation];
            handler(UIImageJPEGRepresentation([OLImageEditorImage croppedImageWithImage:image transform:self.transform size:self.serverImageSize], 0.7), nil);
        });
    } else if (self.type == kPrintPhotoAssetTypeOLFacebookPhoto || self.type == kPrintPhotoAssetTypeOLInstagramPhoto) {
        [[SDWebImageManager sharedManager] downloadWithURL:[self.asset fullURL]
                                                   options:0
                                                  progress:nil
                                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                                         if (finished) {
                                                             if (error) {
                                                                 handler(nil, error);
                                                             } else {
                                                                 NSData *data = UIImageJPEGRepresentation([OLImageEditorImage croppedImageWithImage:image transform:self.transform size:self.serverImageSize], 0.7);
                                                                 handler(data, error);
                                                             }
                                                         }
                                                 }];
    }
}

#pragma mark - NSCoding protocol methods

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _type = [aDecoder decodeIntForKey:kKeyType];
        if (self.type == kPrintPhotoAssetTypeALAsset) {
            // This next bit of code is very broken as there is no guarantee we will actually be able to get the asset e.g. the user could
            // have long since denied us access to their library, etc. :( TODO: handle correctly
            NSURL *assetURL = [aDecoder decodeObjectForKey:kKeyAsset];
            ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
            [assetLibrary assetForURL:assetURL
                          resultBlock:^(ALAsset *asset) {
                              NSAssert([NSThread isMainThread], @"oops wrong assumption about main thread callback");
                              self.assetsLibrary = assetLibrary;
                              self.asset = asset;
                          }
                         failureBlock:^(NSError *err) {
                             NSAssert([NSThread isMainThread], @"oops wrong assumption about main thread callback");
                             NSLog(@"boo, there will likely be a crash at some point in the future...");
                         }];
        } else {
            self.asset = [aDecoder decodeObjectForKey:kKeyAsset];
        }
        self.cropTransform = [aDecoder decodeCGAffineTransformForKey:kKeyCropTransform];
        self.serverImageSize = [aDecoder decodeCGSizeForKey:kKeyServerImageSize];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.type forKey:kKeyType];
    [aCoder encodeCGAffineTransform:self.cropTransform forKey:kKeyCropTransform];
    [aCoder encodeCGSize:self.serverImageSize forKey:kKeyServerImageSize];
    if (self.type == kPrintPhotoAssetTypeALAsset) {
        [aCoder encodeObject:[self.asset valueForProperty:ALAssetPropertyAssetURL] forKey:kKeyAsset];
    } else {
        [aCoder encodeObject:self.asset forKey:kKeyAsset];
    }
}

@end
