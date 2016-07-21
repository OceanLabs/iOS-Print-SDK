//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "OLImageDownloader.h"
#import "OLPrintPhoto.h"
#import "RMImageCropper.h"
#import "OLKiteUtils.h"
#import "OLConstants.h"
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
static NSString *const kKeyUUID = @"co.oceanlabs.psprintstudio.kKeyUUID";

static NSString *const kKeyExtraCopies = @"co.oceanlabs.psprintstudio.kKeyExtraCopies";

static CGFloat screenScale = 2.0;

CGSize const OLAssetMaximumSize = {-1, -1};

static NSOperationQueue *imageOperationQueue;

@import Photos;

@implementation PHAsset (isEqual)

- (BOOL)isEqual:(id)object{
    if(![object isKindOfClass:[PHAsset class]])
        return NO;
    
    return [self.localIdentifier isEqualToString:[object localIdentifier]];
}

@end

@interface OLPrintPhoto ()
@property (nonatomic, strong) UIImage *cachedEditedImage;
@property (assign, nonatomic) BOOL thumbnailIsMaxSize;
@property (nonatomic, assign, readwrite) PrintPhotoAssetType type;
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
        self.uuid = [[NSUUID UUID] UUIDString];
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
    if ([asset isKindOfClass:[PHAsset class]]) {
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
    else if (_type == kPrintPhotoAssetTypeCorrupt){
        //Loaded asset is corrupt
    }
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

- (void)imageWithSize:(CGSize)size applyEdits:(BOOL)applyEdits cacheResult:(BOOL)cacheResult progress:(void(^)(float progress))progress completion:(void(^)(UIImage *image))handler{
    if (!handler){
        //Nothing to do really
        return;
    }
    if (!cacheResult){
        self.cachedEditedImage = nil;
    }
    if (self.cachedEditedImage) {
        if ((MAX(size.height, size.width) * screenScale <= MIN(self.cachedEditedImage.size.width, self.cachedEditedImage.size.height)) || self.thumbnailIsMaxSize){
            handler(self.cachedEditedImage);
            return;
        }
    }
    self.thumbnailIsMaxSize = NO;
    BOOL fullResolution = CGSizeEqualToSize(size, OLAssetMaximumSize);
    
    NSBlockOperation *blockOperation = [[NSBlockOperation alloc] init];
    
    [blockOperation addExecutionBlock:^{
        if (self.type == kPrintPhotoAssetTypePHAsset) {
            PHImageManager *imageManager = [PHImageManager defaultManager];
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.synchronous = NO;
            options.deliveryMode = fullResolution ? PHImageRequestOptionsDeliveryModeHighQualityFormat : PHImageRequestOptionsDeliveryModeFastFormat;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            options.networkAccessAllowed = YES;
            options.progressHandler = ^(double progressAmount, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info){
                if (progress){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progress(progressAmount);
                    });
                }
            };
            
            //Don't request less than a 400x400 image, otherwise the Photos Framework tries to be useful and returns a low-res, prerendered image which loses the rotation metadata (but is rotated correctly). This messes up the rotation from our editor.
            CGSize requestSize = fullResolution ? PHImageManagerMaximumSize : CGSizeMake(MAX(size.width * screenScale, 400), MAX(size.height * screenScale, 400));
            [imageManager requestImageForAsset:(PHAsset *)self.asset targetSize:requestSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *image, NSDictionary *info){
                if (applyEdits){
                    [self resizeImage:image size:size applyEdits:YES completion:^(UIImage *image){
                        self.cachedEditedImage = cacheResult ? image : nil;
                        handler(image);
                    }];
                }
                else{ //Image is already resized, no need to do it again
                    self.cachedEditedImage = cacheResult ? image : nil;
                    handler(image);
                }
            }];
        }
#if defined(OL_KITE_OFFER_INSTAGRAM) || defined(OL_KITE_OFFER_FACEBOOK)
        if (self.type == kPrintPhotoAssetTypeFacebookPhoto || self.type == kPrintPhotoAssetTypeInstagramPhoto) {
            [self downloadFullImageWithProgress:progress completion:^(UIImage *image){
                [self resizeImage:image size:size applyEdits:YES completion:^(UIImage *image){
                    self.thumbnailIsMaxSize = YES;
                    self.cachedEditedImage = cacheResult ? image : nil;
                    if (progress){
                        progress(1);
                    }
                    handler(image);
                }];
            }];
        }
#endif
        else if (self.type == kPrintPhotoAssetTypeCorrupt){
            NSData *data = [NSData dataWithContentsOfFile:[[OLKiteUtils kiteBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
            handler([UIImage imageWithData:data]);
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
- (void)downloadFullImageWithProgress:(void(^)(float progress))progressHandler completion:(void (^)(UIImage *image))completionHandler {
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[self.asset fullURL]];
    
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    if (cachedResponse.data){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressHandler){
                progressHandler(0.05f); // small bit of fake inital progress to get progress bars displaying
            }
        });
    }
    [[OLImageDownloader sharedInstance] downloadImageAtURL:[self.asset fullURL] progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressHandler) {
                progressHandler(MAX(0.05f, receivedSize / (float) expectedSize));
            }
        });
    } withCompletionHandler:^(UIImage *image, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                if (completionHandler) completionHandler(image);
            }
        });
    }];
}
#endif

- (void)getImageWithSize:(CGSize)size progress:(void(^)(float progress))progressHandler completion:(void (^)(UIImage *image))completionHandler {
#if defined(OL_KITE_OFFER_INSTAGRAM) || defined(OL_KITE_OFFER_FACEBOOK)
    if (self.type == kPrintPhotoAssetTypeFacebookPhoto || self.type == kPrintPhotoAssetTypeInstagramPhoto) {
        [self downloadFullImageWithProgress:progressHandler completion:completionHandler];
    }
#endif
    else if (self.type == kPrintPhotoAssetTypeOLAsset){
        OLAsset *asset = (OLAsset *)self.asset;
        
        if (asset.assetType == kOLAssetTypeRemoteImageURL){
            [[OLImageDownloader sharedInstance] downloadImageAtURL:[(OLAsset *)self.asset imageURL] progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (progressHandler) {
                        progressHandler(MAX(0.05f, receivedSize / (float) expectedSize));
                    }
                });
            } withCompletionHandler:^(UIImage *image, NSError *error){
                completionHandler(image);
            }];
        }
        else{
            [asset dataWithCompletionHandler:^(NSData *data, NSError *error){
                completionHandler([UIImage imageWithData:data]);
            }];
        }
    }
    else if ([self.asset respondsToSelector:@selector(dataWithCompletionHandler:)]){
        [self.asset dataWithCompletionHandler:^(NSData *data, NSError *error){
            completionHandler([UIImage imageWithData:data]);
        }];
    }
    else if (self.type == kPrintPhotoAssetTypeCorrupt){
        NSData *data = [NSData dataWithContentsOfFile:[[OLKiteUtils kiteBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
        completionHandler([UIImage imageWithData:data]);
    }
}

- (void)unloadImage {
    self.cachedEditedImage = nil; // we can always recreate this
}

- (BOOL)isEdited{
    return !CGRectIsEmpty(self.edits.cropImageFrame) || !CGRectIsEmpty(self.edits.cropImageRect) || !CGSizeEqualToSize(self.edits.cropImageSize, CGSizeZero) || self.edits.counterClockwiseRotations > 0 || self.edits.flipHorizontal || self.edits.flipVertical;
}

- (void)resizeImage:(UIImage *)image size:(CGSize)size applyEdits:(BOOL)applyEdits completion:(void(^)(UIImage *image))handler{
    __block UIImage *blockImage = image;
    void (^localBlock)() = ^{
        if (self.edits.counterClockwiseRotations > 0 || self.edits.flipHorizontal || self.edits.flipVertical){
            blockImage = [UIImage imageWithCGImage:blockImage.CGImage scale:blockImage.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.edits.counterClockwiseRotations andInitialOrientation:blockImage.imageOrientation horizontalFlip:self.edits.flipHorizontal verticalFlip:self.edits.flipVertical]];
        }
        
        if (!CGSizeEqualToSize(size, CGSizeZero) && !CGSizeEqualToSize(size, OLAssetMaximumSize)){
            blockImage = [OLPrintPhoto imageWithImage:blockImage scaledToSize:size];
        }
        
        if (![self isEdited] || !applyEdits){
            self.thumbnailIsMaxSize = CGSizeEqualToSize(blockImage.size, image.size);
            handler(blockImage);
            return;
        }
        
        blockImage = [RMImageCropper editedImageFromImage:blockImage andFrame:self.edits.cropImageFrame andImageRect:self.edits.cropImageRect andImageViewWidth:self.edits.cropImageSize.width andImageViewHeight:self.edits.cropImageSize.height];
        
        self.thumbnailIsMaxSize = CGSizeEqualToSize(blockImage.size, image.size);
        
        
        for (OLTextOnPhoto *textOnPhoto in self.edits.textsOnPhoto){
            CGFloat scaling = MIN(blockImage.size.width, blockImage.size.height) / MIN(self.edits.cropImageFrame.size.width, self.edits.cropImageFrame.size.height);
            UIFont *font = [OLKiteUtils fontWithName:textOnPhoto.fontName size:textOnPhoto.fontSize * scaling];
            
            CGRect textRect;
            textRect.origin.x = textOnPhoto.frame.origin.x * scaling;
            textRect.origin.y = textOnPhoto.frame.origin.y * scaling + 4;
            textRect.size.width = textOnPhoto.frame.size.width * scaling;
            textRect.size.height = textOnPhoto.frame.size.height * scaling;
            
            UIGraphicsBeginImageContext(CGSizeMake(textRect.size.width, textRect.size.height));
            
            NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            style.alignment = NSTextAlignmentCenter;
            
            NSMutableDictionary *attributes = [@{NSFontAttributeName : font, NSForegroundColorAttributeName: [UIColor whiteColor], NSParagraphStyleAttributeName : style} mutableCopy];
            if (textOnPhoto.color){
                attributes[NSForegroundColorAttributeName] = textOnPhoto.color;
            }
            
            CGSize  textSize = [textOnPhoto.text sizeWithAttributes:attributes];
            
            CGContextRef    context =   UIGraphicsGetCurrentContext();
            CGAffineTransform   t   =   CGAffineTransformMakeTranslation(textRect.size.width / 2, textRect.size.height / 2);
            CGAffineTransform   r   =   CGAffineTransformMakeRotation(atan2(textOnPhoto.transform.b, textOnPhoto.transform.a));
            
            
            CGContextConcatCTM(context, t);
            CGContextConcatCTM(context, r);
            
            [textOnPhoto.text   drawAtPoint:CGPointMake(-1 * textSize.width / 2, -1 * textSize.height / 2)
                             withAttributes:attributes];
            
            CGContextConcatCTM(context, CGAffineTransformInvert(r));
            CGContextConcatCTM(context, CGAffineTransformInvert(t));
            
            
            UIImage *textImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            UIGraphicsBeginImageContext(CGSizeMake(blockImage.size.width, blockImage.size.height));
            [blockImage drawInRect:CGRectMake(0,0,blockImage.size.width,blockImage.size.height)];
            [textImage drawInRect:textRect];
            blockImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        
        handler(blockImage);
    };
    if ([NSThread isMainThread]){
        NSBlockOperation *block = [NSBlockOperation blockOperationWithBlock:localBlock];
        block.queuePriority = NSOperationQueuePriorityHigh;
        [[OLPrintPhoto imageOperationQueue] addOperation:block];
    }
    else{
        localBlock();
    }
}

+(UIImage*)imageWithImage:(UIImage*) sourceImage scaledToSize:(CGSize) i_size
{
    
    CGFloat scaleFactor = (MAX(i_size.width, i_size.height) * screenScale) / MIN(sourceImage.size.height, sourceImage.size.width);
    
    if (scaleFactor >= 1){
        return sourceImage;
    }
    
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
    if (self.type == kPrintPhotoAssetTypePHAsset){
        NSBlockOperation *block = [[NSBlockOperation alloc] init];
        [block addExecutionBlock:^{
            PHImageManager *imageManager = [PHImageManager defaultManager];
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.synchronous = YES;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.networkAccessAllowed = YES;
            
            [imageManager requestImageForAsset:self.asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info){
                if (result){
                    [self dataWithImage:result withCompletionHandler:^(NSData *data){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            handler(data, nil);
                        });
                    }];
                }
                else{
                    _type = kPrintPhotoAssetTypeCorrupt;
                    handler(nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeImagesCorrupt userInfo:@{NSLocalizedDescriptionKey : info[PHImageErrorKey] ? info[PHImageErrorKey] : NSLocalizedString(@"There was an error getting one of your photos. Please remove or replace it.", @""), @"asset" : self}]);
                }
            }];
        }];
        [[OLPrintPhoto imageOperationQueue] addOperation:block];
    }
#if defined(OL_KITE_OFFER_INSTAGRAM) || defined(OL_KITE_OFFER_FACEBOOK)
    else if (self.type == kPrintPhotoAssetTypeFacebookPhoto || self.type == kPrintPhotoAssetTypeInstagramPhoto){
        [[OLImageDownloader sharedInstance] downloadImageAtURL:[self.asset fullURL] withCompletionHandler:^(UIImage *image, NSError *error) {
            if (error) {
                handler(nil, error);
            } else {
                [self dataWithImage:image withCompletionHandler:^(NSData *data){
                    handler(data, nil);
                }];
            }
        }];
    }
#endif
    else if (self.type == kPrintPhotoAssetTypeOLAsset){
        OLAsset *asset = self.asset;
        if (asset.assetType == kOLAssetTypeRemoteImageURL){
            [[OLImageDownloader sharedInstance] downloadImageAtURL:[asset imageURL] withCompletionHandler:^(UIImage *image, NSError *error) {
                if (error) {
                    handler(nil, error);
                } else {
                    [self dataWithImage:image withCompletionHandler:^(NSData *data){
                        handler(data, nil);
                    }];
                }
            }];
        }
        else{
            [asset dataWithCompletionHandler:^(NSData *data, NSError *error){
                if (error){
                    handler(nil,error);
                }
                else{
                    [self dataWithImage:[UIImage imageWithData:data] withCompletionHandler:^(NSData *data){
                        handler(data, nil);
                    }];
                }
            }];
        }
    }
    else if([self.asset respondsToSelector:@selector(dataWithCompletionHandler:)]){
        [self.asset dataWithCompletionHandler:^(NSData *data, NSError *error){
            if (error){
                handler(nil,error);
            }
            else{
                [self dataWithImage:[UIImage imageWithData:data] withCompletionHandler:^(NSData *data){
                    handler(data, nil);
                }];
            }
        }];
    }
    else if (self.type == kPrintPhotoAssetTypeCorrupt){
        handler(0, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeImagesCorrupt userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"There was an error getting one of your photos. It may have been deleted before we could upload it. Please remove or replace it.", @""), @"asset" : self}]);
    }
}

- (void)dataWithImage:(UIImage *)image withCompletionHandler:(void(^)(NSData *data))handler{
    OLPrintPhoto *photo = [[OLPrintPhoto alloc] init];
    photo.asset = [OLAsset assetWithImageAsJPEG:image];
    photo.edits = self.edits;
    
    [self resizeImage:image size:OLAssetMaximumSize applyEdits:YES completion:^(UIImage *image){
        handler(UIImageJPEGRepresentation(image, 0.7));
    }];
    
}

#pragma mark - NSCoding protocol methods

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _type = [aDecoder decodeIntForKey:kKeyType];
        _extraCopies = [aDecoder decodeIntForKey:kKeyExtraCopies];
        _edits = [aDecoder decodeObjectForKey:kKeyEdits];
        _uuid = [aDecoder decodeObjectForKey:kKeyUUID];
        if (self.type == kPrintPhotoAssetTypePHAsset){
            NSString *localId = [aDecoder decodeObjectForKey:kKeyAsset];
            PHAsset *asset = localId ? [[PHAsset fetchAssetsWithLocalIdentifiers:@[localId] options:nil] firstObject] : nil;
            if (!asset){
                // corrupt asset, user has probably deleted the photo from their device
                _type = kPrintPhotoAssetTypeCorrupt;
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
    [aCoder encodeObject:self.uuid forKey:kKeyUUID];
    if (self.type == kPrintPhotoAssetTypePHAsset){
        [aCoder encodeObject:[self.asset localIdentifier] forKey:kKeyAsset];
    }
    else if (self.type != kPrintPhotoAssetTypeCorrupt){
        [aCoder encodeObject:self.asset forKey:kKeyAsset];
    }
}

- (id)copyWithZone:(NSZone *)zone{
    OLPrintPhoto *copy = [[OLPrintPhoto alloc] init];
    copy.type = self.type;
    copy.extraCopies = self.extraCopies;
    copy.edits = [self.edits copyWithZone:zone];
    copy.uuid = self.uuid;
    copy.asset = self.asset;
    
    return copy;
}

@end
