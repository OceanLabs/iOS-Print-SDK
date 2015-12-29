//
//  PrintPhoto.m
//  Print Studio
//
//  Created by Elliott Minns on 16/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#ifdef COCOAPODS
#import <SDWebImage/SDWebImageManager.h>
#else
#import "SDWebImageManager.h"
#endif

#import "OLPrintPhoto.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "RMImageCropper.h"
#import "ALAssetsLibrary+Singleton.h"
#import "OLKiteUtils.h"
#ifdef OL_KITE_OFFER_INSTAGRAM
#import <InstagramImagePicker/OLInstagramImage.h>
#endif
#import "OLAsset+Private.h"
#import "UIImageView+FadeIn.h"

#ifdef OL_KITE_OFFER_FACEBOOK
#import <FacebookImagePicker/OLFacebookImage.h>
#endif

static NSString *const kKeyType = @"co.oceanlabs.psprintstudio.kKeyType";
static NSString *const kKeyAsset = @"co.oceanlabs.psprintstudio.kKeyAsset";
static NSString *const kKeyEdits = @"co.oceanlabs.psprintstudio.kKeyEdits";

static NSString *const kKeyExtraCopies = @"co.oceanlabs.psprintstudio.kKeyExtraCopies";

static CGFloat screenScale = 2.0;

static NSOperationQueue *imageOperationQueue;

@import Photos;

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
@property (nonatomic, strong) UIImage *cachedCroppedThumbnailImage;
@end

@implementation OLPrintPhoto

+(NSOperationQueue *) imageOperationQueue{
    if (!imageOperationQueue){
        imageOperationQueue = [[NSOperationQueue alloc] init];
        imageOperationQueue.maxConcurrentOperationCount = 1;
    }
    return imageOperationQueue;
}

- (id)init {
    if (self = [super init]) {
    }
    
    return self;
}

-(OLPhotoEdits *) edits{
    if (!_edits){
        _edits = [[OLPhotoEdits alloc] init];
    }
    return _edits;
}

- (void)setAsset:(id)asset {
    _asset = asset;
    if ([asset isKindOfClass:[ALAsset class]]) {
        _type = kPrintPhotoAssetTypeALAsset;
    }
    else if ([asset isKindOfClass:[PHAsset class]]) {
        _type = kPrintPhotoAssetTypePHAsset;
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

+ (void)calcScreenScaleForTraitCollection:(UITraitCollection *)traitCollection{
    //Should be [UIScreen mainScreen].scale but the 6 Plus with its 1GB RAM chokes on 3x images.
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale == 2.0 || scale == 1.0){
        screenScale = scale;
    }
    else if (!traitCollection){
        scale = 2.0;
    }
    else{
        UIImage *ram1GbImage = [UIImage imageNamed:@"ram-1" inBundle:[OLKiteUtils kiteBundle] compatibleWithTraitCollection:traitCollection];
        UIImage *ramThisDeviceImage = [UIImage imageNamed:@"ram" inBundle:[OLKiteUtils kiteBundle] compatibleWithTraitCollection:traitCollection];
        NSData *ram1Gb = UIImagePNGRepresentation(ram1GbImage);
        NSData *ramThisDevice = UIImagePNGRepresentation(ramThisDeviceImage);
        if ([ram1Gb isEqualToData:ramThisDevice]){
            screenScale = 2.0;
        }
        else{
            screenScale = scale;
        }
    }
}

- (void)setImageSize:(CGSize)destSize cropped:(BOOL)cropped progress:(OLImageEditorImageGetImageProgressHandler)progressHandler completionHandler:(void(^)(UIImage *image))handler{
    if (self.cachedCroppedThumbnailImage) {
        if ((MAX(destSize.height, destSize.width) * screenScale <= MIN(self.cachedCroppedThumbnailImage.size.width, self.cachedCroppedThumbnailImage.size.height))){
            handler(self.cachedCroppedThumbnailImage);
            return;
        }
    }
    
    NSBlockOperation *blockOperation = [[NSBlockOperation alloc] init];
    
    [blockOperation addExecutionBlock:^{
        if (self.type == kPrintPhotoAssetTypeALAsset || self.type == kPrintPhotoAssetTypePHAsset) {
            [OLPrintPhoto resizedImageWithPrintPhoto:self size:destSize cropped:cropped progress:progressHandler completion:^(UIImage *image) {
                self.cachedCroppedThumbnailImage = image;
                handler(image);
                
            }];
        }
        else {
            if (self.type == kPrintPhotoAssetTypeOLAsset){
                OLAsset *asset = (OLAsset *)self.asset;
                
                if (asset.assetType == kOLAssetTypeRemoteImageURL){
                    if (![self isEdited]){
                        [self getImageWithSize:CGSizeZero progress:progressHandler completion:^(UIImage *image){
                            self.cachedCroppedThumbnailImage = image;
                            handler(image);
                        }];
                    }
                    else{
                        [OLPrintPhoto resizedImageWithPrintPhoto:self size:destSize cropped:cropped progress:progressHandler completion:^(UIImage *image) {
                            self.cachedCroppedThumbnailImage = image;
                            handler(image);
                        }];
                    }
                }
                else if (asset.assetType == kOLAssetTypePHAsset){
                    PHAsset *asset = [self.asset loadPHAsset];
                    self.asset = asset;
                    [OLPrintPhoto resizedImageWithPrintPhoto:self size:destSize cropped:cropped progress:progressHandler completion:^(UIImage *image) {
                        self.cachedCroppedThumbnailImage = image;
                        handler(image);
                    }];
                }
                else if (asset.assetType == kOLAssetTypeALAsset){
                    [asset loadALAssetWithCompletionHandler:^(ALAsset *asset, NSError *error){
                        NSBlockOperation *block = [NSBlockOperation blockOperationWithBlock:^{
                            self.asset = asset;
                            [OLPrintPhoto resizedImageWithPrintPhoto:self size:destSize cropped:cropped progress:progressHandler completion:^(UIImage *image) {
                                self.cachedCroppedThumbnailImage = image;
                                handler(image);
                            }];
                        }];
                        block.queuePriority = NSOperationQueuePriorityHigh;
                        [[OLPrintPhoto imageOperationQueue] addOperation:block];
                    }];
                }
                else{
                    [asset dataWithCompletionHandler:^(NSData *data, NSError *error){
                        NSBlockOperation *block = [NSBlockOperation blockOperationWithBlock:^{
                            [OLPrintPhoto resizedImageWithPrintPhoto:self size:destSize cropped:cropped progress:progressHandler completion:^(UIImage *image) {
                                self.cachedCroppedThumbnailImage = image;
                                handler(image);
                            }];
                        }];
                        block.queuePriority = NSOperationQueuePriorityHigh;
                        [[OLPrintPhoto imageOperationQueue] addOperation:block];
                    }];
                }
            }
#ifdef OL_KITE_OFFER_INSTAGRAM
            else if (self.type == kPrintPhotoAssetTypeInstagramPhoto) {
                if (![self isEdited]){
                    [self getImageWithSize:CGSizeZero progress:progressHandler completion:^(UIImage *image){
                        self.cachedCroppedThumbnailImage = image;
                        if (progressHandler){
                            progressHandler(1);
                        }
                        handler(image);
                    }];
                }
                else{
                    [OLPrintPhoto resizedImageWithPrintPhoto:self size:destSize cropped:cropped progress:progressHandler completion:^(UIImage *image) {
                        self.cachedCroppedThumbnailImage = image;
                        if (progressHandler){
                            progressHandler(1);
                        }
                        handler(image);
                    }];
                }
            }
#endif
#ifdef OL_KITE_OFFER_FACEBOOK
            else if (self.type == kPrintPhotoAssetTypeFacebookPhoto){
                if (![self isEdited]){
                    [self getImageWithSize:CGSizeZero progress:progressHandler completion:^(UIImage *image){
                        self.cachedCroppedThumbnailImage = image;
                        if (progressHandler){
                            progressHandler(1);
                        }
                        handler(image);
                    }];
                }
                else{
                    [OLPrintPhoto resizedImageWithPrintPhoto:self size:destSize cropped:cropped progress:progressHandler completion:^(UIImage *image) {
                        self.cachedCroppedThumbnailImage = image;
                        if (progressHandler){
                            progressHandler(1);
                        }
                        handler(image);
                    }];
                }
            }
#endif
        }
    }];
    [[OLPrintPhoto imageOperationQueue] addOperation:blockOperation];
}

- (BOOL)isEqual:(id)object {
    BOOL retVal = [object class] == [self class];
    if (retVal) {
        OLPrintPhoto *other = object;
        retVal &= (other.type == self.type);
        retVal &= ([other.asset isEqual:self.asset]);
        retVal &= [self.edits isEqual: other.edits];
    }
    
    return retVal;
}

#if defined(OL_KITE_OFFER_INSTAGRAM) || defined(OL_KITE_OFFER_FACEBOOK)
- (void)downloadFullImageWithProgress:(OLImageEditorImageGetImageProgressHandler)progressHandler completion:(OLImageEditorImageGetImageCompletionHandler)completionHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (progressHandler){
            progressHandler(0.05f); // small bit of fake inital progress to get progress bars displaying
        }
    });
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
    [self getImageWithSize:CGSizeZero progress:progressHandler completion:completionHandler];
}

- (void)getImageWithSize:(CGSize)size progress:(OLImageEditorImageGetImageProgressHandler)progressHandler completion:(OLImageEditorImageGetImageCompletionHandler)completionHandler {
    BOOL fullResolution = CGSizeEqualToSize(size, CGSizeZero);
    if (self.type == kPrintPhotoAssetTypeALAsset) {
        UIImage* image;
        if (fullResolution){
            image = [UIImage imageWithCGImage:[[self.asset defaultRepresentation] fullResolutionImage] scale:1 orientation:[[self.asset valueForProperty:ALAssetPropertyOrientation] integerValue]];
        }
        else{
            image = [UIImage imageWithCGImage:[[self.asset defaultRepresentation] fullScreenImage]];
        }
        completionHandler(image);
    }
    else if (self.type == kPrintPhotoAssetTypePHAsset){
        PHImageManager *imageManager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = YES;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.networkAccessAllowed = YES;
        options.progressHandler = ^(double progress, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info){
            if (progressHandler){
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressHandler(progress);
                });
            }
        };
        CGSize requestSize = fullResolution ? PHImageManagerMaximumSize : CGSizeMake(size.width * screenScale, size.height * screenScale);
        [imageManager requestImageForAsset:(PHAsset *)self.asset targetSize:requestSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *image, NSDictionary *info){
            completionHandler(image);
        }];
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

- (BOOL)isEdited{
    return !CGRectIsEmpty(self.edits.cropImageFrame) || !CGRectIsEmpty(self.edits.cropImageRect) || !CGSizeEqualToSize(self.edits.cropImageSize, CGSizeZero) || self.edits.counterClockwiseRotations > 0 || self.edits.flipHorizontal || self.edits.flipVertical;
}

+ (void)resizedImageWithPrintPhoto:(OLPrintPhoto *)printPhoto size:(CGSize)destSize cropped:(BOOL)cropped progress:(OLImageEditorImageGetImageProgressHandler)progressHandler completion:(OLImageEditorImageGetImageCompletionHandler)completionHandler {
    
    
    [printPhoto getImageWithSize:destSize progress:progressHandler completion:^(UIImage *image) {
        __block UIImage *blockImage = image;
        void (^localBlock)() = ^{
            if (printPhoto.edits.counterClockwiseRotations > 0 || printPhoto.edits.flipHorizontal || printPhoto.edits.flipVertical){
                blockImage = [UIImage imageWithCGImage:blockImage.CGImage scale:blockImage.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:printPhoto.edits.counterClockwiseRotations andInitialOrientation:blockImage.imageOrientation horizontalFlip:printPhoto.edits.flipHorizontal verticalFlip:printPhoto.edits.flipVertical]];
            }
            
            if (destSize.height != 0 && destSize.width != 0){
                blockImage = [OLPrintPhoto imageWithImage:blockImage scaledToSize:destSize];
            }
            
            if (![printPhoto isEdited] || !cropped){
                completionHandler(blockImage);
                return;
            }
            
            blockImage = [RMImageCropper editedImageFromImage:blockImage andFrame:printPhoto.edits.cropImageFrame andImageRect:printPhoto.edits.cropImageRect andImageViewWidth:printPhoto.edits.cropImageSize.width andImageViewHeight:printPhoto.edits.cropImageSize.height];
            
            completionHandler(blockImage);
        };
        if ([NSThread isMainThread]){
            NSBlockOperation *block = [NSBlockOperation blockOperationWithBlock:localBlock];
            block.queuePriority = NSOperationQueuePriorityHigh;
            [[OLPrintPhoto imageOperationQueue] addOperation:block];
        }
        else{
            localBlock();
        }
    }];
    
}

+(UIImage*)imageWithImage:(UIImage*) sourceImage scaledToSize:(CGSize) i_size
{
    
    CGFloat scaleFactor = (MAX(i_size.width, i_size.height) * screenScale) / MIN(sourceImage.size.height, sourceImage.size.width);
    
    CGFloat newHeight = sourceImage.size.height * scaleFactor;
    CGFloat newWidth = sourceImage.size.width * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


#pragma mark - OLAssetDataSource protocol methods

- (NSString *)mimeType {
    return kOLMimeTypeJPEG;
}

- (void)dataLengthWithCompletionHandler:(GetDataLengthHandler)handler {
    [self dataWithCompletionHandler:^(NSData *data, NSError *error){
        handler(data.length, error);
    }];
}

- (void)dataWithCompletionHandler:(GetDataHandler)handler {
    if (self.type == kPrintPhotoAssetTypeALAsset) {
        ALAssetRepresentation *rep = [self.asset defaultRepresentation];
        if (rep) {
            UIImageOrientation orientation = UIImageOrientationUp;
            NSNumber* orientationValue = [self.asset valueForProperty:@"ALAssetPropertyOrientation"];
            if (orientationValue != nil) {
                orientation = [orientationValue intValue];
            }
            
            UIImage *image = [UIImage imageWithCGImage:[rep fullResolutionImage] scale:rep.scale orientation:orientation];
            [self dataWithImage:image withCompletionHandler:handler];
        } else {
            NSData *data = [NSData dataWithContentsOfFile:[[OLKiteUtils kiteBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
            handler(data, nil);
        }
    }
    else if (self.type == kPrintPhotoAssetTypePHAsset){
        NSBlockOperation *block = [[NSBlockOperation alloc] init];
        [block addExecutionBlock:^{
            PHImageManager *imageManager = [PHImageManager defaultManager];
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.synchronous = YES;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.networkAccessAllowed = YES;
            
            [imageManager requestImageForAsset:self.asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info){
                if (result){
                    [self dataWithImage:result withCompletionHandler:^(NSData *data, NSError *error){
                        if (!error){
                            dispatch_async(dispatch_get_main_queue(), ^{
                                handler(data, nil);
                            });
                        }
                        else{
                            NSData *data = [NSData dataWithContentsOfFile:[[OLKiteUtils kiteBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                handler(data, nil);
                            });
                        }
                    }];
                }
                else{
                    NSData *data = [NSData dataWithContentsOfFile:[[OLKiteUtils kiteBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler(data, nil);
                    });
                }
            }];
        }];
        [[OLPrintPhoto imageOperationQueue] addOperation:block];
    }
#if defined(OL_KITE_OFFER_INSTAGRAM) || defined(OL_KITE_OFFER_FACEBOOK)
    else if (self.type == kPrintPhotoAssetTypeFacebookPhoto || self.type == kPrintPhotoAssetTypeInstagramPhoto){
        [[SDWebImageManager sharedManager] downloadImageWithURL:[self.asset fullURL] options:0 progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (finished) {
                if (error) {
                    handler(nil, error);
                } else {
                    [self dataWithImage:image withCompletionHandler:handler];
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
                                                                      [self dataWithImage:image withCompletionHandler:handler];
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
                    [self dataWithImage:[UIImage imageWithData:data] withCompletionHandler:handler];
                }
            }];
        }
    }
}

- (void)dataWithImage:(UIImage *)image withCompletionHandler:(GetDataHandler)handler{
    OLPrintPhoto *photo = [[OLPrintPhoto alloc] init];
    photo.asset = [OLAsset assetWithImageAsJPEG:image];
    photo.edits = self.edits;
    
    [OLPrintPhoto resizedImageWithPrintPhoto:photo size:CGSizeZero cropped:YES progress:NULL completion:^(UIImage *image){
        handler(UIImageJPEGRepresentation(image, 0.7), nil);
    }];
    
}

#pragma mark - NSCoding protocol methods

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _type = [aDecoder decodeIntForKey:kKeyType];
        _extraCopies = [aDecoder decodeIntForKey:kKeyExtraCopies];
        _edits = [aDecoder decodeObjectForKey:kKeyEdits];
        if (self.type == kPrintPhotoAssetTypeALAsset) {
            NSURL *assetURL = [aDecoder decodeObjectForKey:kKeyAsset];
            [[ALAssetsLibrary defaultAssetsLibrary] assetForURL:assetURL
                                                    resultBlock:^(ALAsset *asset) {
                                                        NSAssert([NSThread isMainThread], @"oops wrong assumption about main thread callback");
                                                        if (asset == nil) {
                                                            // corrupt asset, user has probably deleted the photo from their device
                                                            _type = kPrintPhotoAssetTypeOLAsset;
                                                            NSData *data = [NSData dataWithContentsOfFile:[[OLKiteUtils kiteBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
                                                            self.asset = [OLAsset assetWithDataAsJPEG:data];
                                                        } else {
                                                            self.asset = asset;
                                                        }
                                                    }
                                                   failureBlock:^(NSError *err) {
                                                       NSAssert([NSThread isMainThread], @"oops wrong assumption about main thread callback");
                                                       _type = kPrintPhotoAssetTypeOLAsset;
                                                       NSData *data = [NSData dataWithContentsOfFile:[[OLKiteUtils kiteBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
                                                       self.asset = [OLAsset assetWithDataAsJPEG:data];
                                                   }];
        }
        else if (self.type == kPrintPhotoAssetTypePHAsset){
            NSString *localId = [aDecoder decodeObjectForKey:kKeyAsset];
            PHAsset *asset = localId ? [[PHAsset fetchAssetsWithLocalIdentifiers:@[localId] options:nil] firstObject] : nil;
            if (!asset){
                // corrupt asset, user has probably deleted the photo from their device
                _type = kPrintPhotoAssetTypeOLAsset;
                NSData *data = [NSData dataWithContentsOfFile:[[OLKiteUtils kiteBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
                self.asset = [OLAsset assetWithDataAsJPEG:data];
            }
            else {
                self.asset = asset;
            }
            
        }
        else {
            self.asset = [aDecoder decodeObjectForKey:kKeyAsset];
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.type forKey:kKeyType];
    [aCoder encodeInteger:self.extraCopies forKey:kKeyExtraCopies];
    [aCoder encodeObject:self.edits forKey:kKeyEdits];
    if (self.type == kPrintPhotoAssetTypeALAsset) {
        [aCoder encodeObject:[self.asset valueForProperty:ALAssetPropertyAssetURL] forKey:kKeyAsset];
    }
    else if (self.type == kPrintPhotoAssetTypePHAsset){
        [aCoder encodeObject:[self.asset localIdentifier] forKey:kKeyAsset];
    }
    else {
        [aCoder encodeObject:self.asset forKey:kKeyAsset];
    }
}

@end
