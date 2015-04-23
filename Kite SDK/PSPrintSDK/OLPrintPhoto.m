//
//  PrintPhoto.m
//  Print Studio
//
//  Created by Elliott Minns on 16/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import "OLPrintPhoto.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <SDWebImageManager.h>
#ifdef OL_KITE_OFFER_INSTAGRAM
#import <OLInstagramImage.h>
#endif
#import "OLAsset+Private.h"
#import "UIImageView+FadeIn.h"

#ifdef OL_KITE_OFFER_FACEBOOK
#import <OLFacebookImage.h>
#endif

static NSString *const kKeyType = @"co.oceanlabs.psprintstudio.kKeyType";
static NSString *const kKeyAsset = @"co.oceanlabs.psprintstudio.kKeyAsset";
static NSString *const kKeyCropTransform = @"co.oceanlabs.psprintstudio.kKeyCropTransform";

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
@property (nonatomic, strong) UIImage *cachedCroppedThumbnailImage;
@end

@implementation OLPrintPhoto

- (id)init {
    if (self = [super init]) {
    }
    
    return self;
}

- (void)setAsset:(id)asset {
    _asset = asset;
    if ([asset isKindOfClass:[ALAsset class]]) {
        _type = kPrintPhotoAssetTypeALAsset;
    }
    else if ([asset isKindOfClass:[OLAsset class]]){
        _type = kPrintPhotoAssetTypeOLAsset;
    }
#ifdef OL_KITE_OFFER_INSTAGRAM
    else if ([asset isKindOfClass:[OLInstagramImage class]]){
        _type = kPrintPhotoAssetTypeInstagramPhoto;
    }
#endif
#ifdef OL_KITE_OFFER_FACEBOOK
    else if ([asset isKindOfClass:[OLFacebookImage class]]){
        _type = kPrintPhotoAssetTypeFacebookPhoto;
    }
#endif
    else {
        NSAssert(NO, @"Unknown asset type of class: %@", [asset class]);
    }
}

- (void) setImageSize:(CGSize)destSize ForImageView:(UIImageView *)imageView{
    if (self.cachedCroppedThumbnailImage) {
        if (!(fmax(imageView.frame.size.width, imageView.frame.size.height) * [UIScreen mainScreen].scale > fmax(self.cachedCroppedThumbnailImage.size.width, self.cachedCroppedThumbnailImage.size.height))){
            imageView.image = self.cachedCroppedThumbnailImage;
            return;
        }
    }
    if (self.type == kPrintPhotoAssetTypeALAsset) {
        [OLPrintPhoto resizedImageWithEditorImage:self size:destSize progress:nil completion:^(UIImage *image) {
            self.cachedCroppedThumbnailImage = image;
            dispatch_async(dispatch_get_main_queue(), ^(void){
                imageView.image = image;
            });
            
        }];
    }
    else {
        if (self.type == kPrintPhotoAssetTypeOLAsset){
            OLAsset *asset = (OLAsset *)self.asset;
            
            if (asset.assetType == kOLAssetTypeRemoteImageURL){
                [imageView setAndFadeInImageWithURL:[self.asset imageURL]];
            }
            else if (asset.assetType == kOLAssetTypeALAsset){
                [asset loadALAssetWithCompletionHandler:^(ALAsset *asset, NSError *error){
                    OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
                    printPhoto.asset = asset;
                    [OLPrintPhoto resizedImageWithEditorImage:printPhoto size:destSize progress:nil completion:^(UIImage *image) {
                        self.cachedCroppedThumbnailImage = image;
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            imageView.image = image;
                        });
                        
                    }];
                }];
            }
            else{
                [asset dataWithCompletionHandler:^(NSData *data, NSError *error){
                    OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
                    printPhoto.asset = [OLAsset assetWithImageAsJPEG:[UIImage imageWithData:data]];
                    [OLPrintPhoto resizedImageWithEditorImage:printPhoto size:destSize progress:nil completion:^(UIImage *image) {
                        self.cachedCroppedThumbnailImage = image;
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            imageView.image = image;
                        });
                    }];
                    
                }];
            }
        }
#ifdef OL_KITE_OFFER_INSTAGRAM
        else if (self.type == kPrintPhotoAssetTypeInstagramPhoto) {
            [imageView setAndFadeInImageWithURL:[self.asset fullURL]];
        }
#endif
#ifdef OL_KITE_OFFER_FACEBOOK
        else if (self.type == kPrintPhotoAssetTypeFacebookPhoto){
            OLFacebookImage *fbImage = self.asset;
            [imageView setAndFadeInImageWithURL:[fbImage bestURLForSize:destSize]];
        }
#endif
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

#if defined(OL_KITE_OFFER_INSTAGRAM) || defined(OL_KITE_OFFER_FACEBOOK)
- (void)downloadFullImageWithProgress:(OLImageEditorImageGetImageProgressHandler)progressHandler completion:(OLImageEditorImageGetImageCompletionHandler)completionHandler {
    if (progressHandler) progressHandler(0.05f); // small bit of fake inital progress to get progress bars displaying
    [[SDWebImageManager sharedManager] downloadImageWithURL:[self.asset fullURL] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressHandler) {
                progressHandler(MAX(0.05f, receivedSize / (float) expectedSize));
            }
        });
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (finished) {
                if (completionHandler) completionHandler(image);
            }
        });
    }];
}
#endif

- (void)getImageWithProgress:(OLImageEditorImageGetImageProgressHandler)progressHandler completion:(OLImageEditorImageGetImageCompletionHandler)completionHandler {
    if (self.type == kPrintPhotoAssetTypeALAsset) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_async(queue, ^(void){
            UIImage* image = [UIImage imageWithCGImage:[[self.asset defaultRepresentation] fullScreenImage]];
            completionHandler(image);
        });
    }
#if defined(OL_KITE_OFFER_INSTAGRAM) || defined(OL_KITE_OFFER_FACEBOOK)
    else if (self.type == kPrintPhotoAssetTypeFacebookPhoto || self.type == kPrintPhotoAssetTypeInstagramPhoto) {
        [self downloadFullImageWithProgress:progressHandler completion:completionHandler];
    }
#endif
    else if (self.type == kPrintPhotoAssetTypeOLAsset){
        OLAsset *asset = (OLAsset *)self.asset;
        
        if (asset.assetType == kOLAssetTypeRemoteImageURL){
            [[SDWebImageManager sharedManager] downloadImageWithURL:[(OLAsset *)self.asset imageURL]  options:0 progress:nil completed:
             ^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
                 completionHandler(image);
             }];
        }
        else{
            [asset dataWithCompletionHandler:^(NSData *data, NSError *error){
                completionHandler([UIImage imageWithData:data]);
            }];
        }
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

+ (void)transform:(CGAffineTransform *)transform andSize:(CGSize *)size forOrientation:(UIImageOrientation)orientation {
    *transform = CGAffineTransformIdentity;
    BOOL transpose = NO;
    
    switch(orientation)
    {
        case UIImageOrientationUp:// EXIF 1
        case UIImageOrientationUpMirrored:{ // EXIF 2
        } break;
        case UIImageOrientationDown: // EXIF 3
        case UIImageOrientationDownMirrored: { // EXIF 4
            *transform = CGAffineTransformMakeRotation(M_PI);
        } break;
        case UIImageOrientationLeftMirrored: // EXIF 5
        case UIImageOrientationLeft: {// EXIF 6
            *transform = CGAffineTransformMakeRotation(M_PI_2);
            transpose = YES;
        } break;
        case UIImageOrientationRightMirrored: // EXIF 7
        case UIImageOrientationRight: { // EXIF 8
            *transform = CGAffineTransformMakeRotation(-M_PI_2);
            transpose = YES;
        } break;
        default:
            break;
    }
    
    if(orientation == UIImageOrientationUpMirrored || orientation == UIImageOrientationDownMirrored ||
       orientation == UIImageOrientationLeftMirrored || orientation == UIImageOrientationRightMirrored) {
        *transform = CGAffineTransformScale(*transform, -1, 1);
    }
    
    if(transpose) {
        *size = CGSizeMake(size->height, size->width);
    }
}

+ (void)resizedImageWithEditorImage:(OLPrintPhoto *)editorImage size:(CGSize)destSize progress:(OLImageEditorImageGetImageProgressHandler)progressHandler completion:(OLImageEditorImageGetImageCompletionHandler)completionHandler {
    
    [editorImage getImageWithProgress:progressHandler completion:^(UIImage *image) {
        CGFloat factor = fmax(destSize.height, destSize.width) / fmin(image.size.width,image.size.height);
        factor *= [UIScreen mainScreen].scale;
        
        UIImage *croppedImage = [self resizedImageWithImage:image size:CGSizeMake(image.size.width * factor, image.size.height * factor)];
        completionHandler(croppedImage);
    }];
}

+ (UIImage *)resizedImageWithImage:(UIImage *)image size:(CGSize)destSize {
    UIGraphicsBeginImageContext(destSize);
    [image drawInRect:CGRectMake(0, 0, destSize.width, destSize.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
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
    }
#if defined(OL_KITE_OFFER_INSTAGRAM) || defined(OL_KITE_OFFER_FACEBOOK)
    else if (self.type == kPrintPhotoAssetTypeInstagramPhoto || self.type == kPrintPhotoAssetTypeFacebookPhoto){
        [[SDWebImageManager sharedManager] downloadImageWithURL:[self.asset fullURL] options:0 progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (finished) {
                NSUInteger length = UIImageJPEGRepresentation(image, 0.7).length;
                handler(length, error);
            }
        }];
    }
#endif
    else if (self.type == kPrintPhotoAssetTypeOLAsset){
        [(OLAsset *)self.asset dataLengthWithCompletionHandler:handler];
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
            handler(UIImageJPEGRepresentation(image, 0.7), nil);
        });
    }
#if defined(OL_KITE_OFFER_INSTAGRAM) || defined(OL_KITE_OFFER_FACEBOOK)
    else if (self.type == kPrintPhotoAssetTypeFacebookPhoto || self.type == kPrintPhotoAssetTypeInstagramPhoto){
        [[SDWebImageManager sharedManager] downloadImageWithURL:[self.asset fullURL] options:0 progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (finished) {
                if (error) {
                    handler(nil, error);
                } else {
                    NSData *data = UIImageJPEGRepresentation(image, 0.7);
                    handler(data, error);
                }
            }
        }];
    }
#endif
    else if (self.type == kPrintPhotoAssetTypeOLAsset){
        OLAsset *asset = self.asset;
        if (asset.assetType == kOLAssetTypeRemoteImageURL){
            [[SDWebImageManager sharedManager] downloadImageWithURL:[asset imageURL]
                                                            options:0
                                                           progress:nil
                                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *url) {
                                                              if (finished) {
                                                                  if (error) {
                                                                      handler(nil, error);
                                                                  } else {
                                                                      handler(UIImageJPEGRepresentation(image, 0.7), error);
                                                                  }
                                                              }
                                                          }];
        }
        else{
            [asset dataWithCompletionHandler:^(NSData *data, NSError *error){
                if (error){
                    handler(nil,error);
                }
                else{
                    handler(data, error);
                }
            }];
        }
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
                         }];
        } else {
            self.asset = [aDecoder decodeObjectForKey:kKeyAsset];
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.type forKey:kKeyType];
    if (self.type == kPrintPhotoAssetTypeALAsset) {
        [aCoder encodeObject:[self.asset valueForProperty:ALAssetPropertyAssetURL] forKey:kKeyAsset];
    } else {
        [aCoder encodeObject:self.asset forKey:kKeyAsset];
    }
}

@end
