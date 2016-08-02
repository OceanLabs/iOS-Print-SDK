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

@import Photos;

#import "OLAsset.h"
#import "OLAsset+Private.h"
#import "OLKiteUtils.h"
#import "OLConstants.h"
#import "OLUserSession.h"
#import "UIImage+OLUtils.h"
#import "RMImageCropper.h"
#import "OLImageDownloader.h"
//#import "OLInstagramImage.h"
//#import "OLFacebookImage.h"

static NSString *const kKeyMimeType = @"co.oceanlabs.pssdk.kKeyMimeType";
static NSString *const kKeyImageData = @"co.oceanlabs.pssdk.kKeyImageData";
static NSString *const kKeyImageFilePath = @"co.oceanlabs.pssdk.kKeyImageFilePath";
static NSString *const kKeyALAssetURL = @"co.oceanlabs.pssdk.kKeyALAssetURL";
static NSString *const kKeyDataSource = @"co.oceanlabs.pssdk.kKeyDataSource";
static NSString *const kKeyImageURL = @"co.oceanlabs.pssdk.kKeyImageURL";
static NSString *const kKeyPHAssetLocalId = @"co.oceanlabs.pssdk.kKeyPHAssetLocalId";

NSString *const kOLMimeTypeJPEG = @"image/jpeg";
NSString *const kOLMimeTypePNG  = @"image/png";
NSString *const kOLMimeTypeTIFF = @"image/tiff";
NSString *const kOLMimeTypePDF = @"application/pdf";

CGSize const OLAssetMaximumSize = {-1, -1};

static NSOperationQueue *imageOperationQueue;

@interface OLAsset ()
@property (nonatomic, strong) NSString *imageFilePath;
@property (nonatomic, strong) NSData *imageData;
@property (strong, nonatomic) PHAsset *phAsset;
//@property (strong, nonatomic) OLFacebookImage *facebookImage;
//@property (strong, nonatomic) OLInstagramImage *instagramImage;
@property (nonatomic, strong) id<OLAssetDataSource> dataSource;
@property (nonatomic, strong) NSURL *imageURL;
@property (assign, nonatomic) BOOL corrupt;
@property (nonatomic, strong) UIImage *cachedEditedImage;
@property (assign, nonatomic) NSInteger extraCopies;
@property (strong, nonatomic) OLPhotoEdits *edits;
@property (strong, nonatomic) NSString *uuid;

@property (nonatomic, readwrite) NSString *mimeType;
@property (nonatomic, readwrite) long long assetId;
@property (nonatomic, readwrite) NSURL *previewURL;
@end

@implementation OLAsset

-(OLPhotoEdits *) edits{
    if (!_edits){
        _edits = [[OLPhotoEdits alloc] init];
    }
    return _edits;
}

-(NSString *) uuid{
    if (!_uuid){
        _uuid = [[NSUUID UUID] UUIDString];
    }
    return _uuid;
}

+(NSOperationQueue *) imageOperationQueue{
    if (!imageOperationQueue){
        imageOperationQueue = [[NSOperationQueue alloc] init];
        imageOperationQueue.maxConcurrentOperationCount = 1;
    }
    return imageOperationQueue;
}

- (NSURL *)imageURL{
//    if (self.instagramImage){
//        return [self.instagramImage fullURL];
//    }
//    else if (self.facebookImage){
//        return [self.facebookImage fullURL];
//    }
//    else{
        return _imageURL;
//    }
}

- (instancetype)initWithImageData:(NSData *)data mimeType:(NSString *)mimeType {
    if (self = [super init]) {
        NSAssert(data != nil, @"image data must be non nil");
        NSAssert(mimeType != nil, @"mime type must be non nil");
        self.imageData = data;
        _mimeType = mimeType;
    }
    
    return self;
}

- (instancetype)initWithImageFilePath:(NSString *)imageFilePath {
    if (self = [super init]) {
        self.imageFilePath = imageFilePath;
        NSString *lower = imageFilePath.lowercaseString;
        if ([lower hasSuffix:@".jpg"] || [lower hasSuffix:@".jpeg"]) {
            _mimeType = kOLMimeTypeJPEG;
        } else if ([lower hasSuffix:@".png"]) {
            _mimeType = kOLMimeTypePNG;
        } else if ([lower hasSuffix:@".tif"] || [lower hasSuffix:@".tiff"]) {
            _mimeType = kOLMimeTypeTIFF;
        } else if ([lower hasSuffix:@".pdf"]){
            _mimeType = kOLMimeTypePDF;
        } else {
            NSAssert(NO, @"Only JPEG, PNG & TIFF images and pre-rendered PDF files are supported");
        }
    }
    
    return self;
}

- (instancetype)initWithPHAsset:(PHAsset *)asset {
    if (self = [super init]) {
        _mimeType = kOLMimeTypeJPEG; //Assume JPEG
        self.phAsset = asset;
    }
    return self;
}

- (instancetype)initWithImageURL:(NSURL *)url mimeType:(NSString *)mimeType {
    if (self = [super init]) {
        _mimeType = mimeType;
        _imageURL = url;
    }
    
    return self;
}

- (instancetype)initWithDataSource:(id<OLAssetDataSource>)dataSource {
    if (self = [super init]) {
        NSAssert([dataSource respondsToSelector:@selector(dataWithCompletionHandler:)], @"Oops your class %@ does not conform to the OLAssetDataSource protocol", [dataSource class]);
         NSAssert([dataSource respondsToSelector:@selector(dataLengthWithCompletionHandler:)], @"Oops your class %@ does not conform to the OLAssetDataSource protocol", [dataSource class]);
        _mimeType = dataSource.mimeType;
        self.dataSource = dataSource;
    }
    
    return self;
}

- (OLAssetType)assetType {
    if (self.imageData) {
        return kOLAssetTypeImageData;
    }
//    else if (self.instagramImage){
//        return kOLAssetTypeInstagramPhoto;
//    }
//    else if (self.facebookImage){
//        return kOLAssetTypeFacebookPhoto;
//    }
    else if (self.imageURL) {
        return kOLAssetTypeRemoteImageURL;
    }
    else if (self.imageFilePath) {
        return kOLAssetTypeImageFilePath;
    }
    else if (self.dataSource) {
        return kOLAssetTypeDataSource;
    }
    else if (self.phAsset){
        return kOLAssetTypePHAsset;
    }
    else {
        NSAssert(NO, @"oops added a new type of asset data source without doing all the real work :)");
        return 0;
    }
}

+ (OLAsset *)assetWithImageAsJPEG:(UIImage *)image {
    return [[OLAsset alloc] initWithImageData:UIImageJPEGRepresentation(image, 0.8) mimeType:kOLMimeTypeJPEG];
}

+ (OLAsset *)assetWithImageAsPNG:(UIImage *)image {
    return [[OLAsset alloc] initWithImageData:UIImagePNGRepresentation(image) mimeType:kOLMimeTypePNG];
}

+ (OLAsset *)assetWithDataAsJPEG:(NSData *)data {
    return [[OLAsset alloc] initWithImageData:data mimeType:kOLMimeTypeJPEG];
}

+ (OLAsset *)assetWithDataAsPNG:(NSData *)data {
    return [[OLAsset alloc] initWithImageData:data mimeType:kOLMimeTypePNG];
}

+ (OLAsset *)assetWithDataAsPDF:(NSData *)data {
    return [[OLAsset alloc] initWithImageData:data mimeType:kOLMimeTypePDF];
}

+ (OLAsset *)assetWithFilePath:(NSString *)path {
    return [[OLAsset alloc] initWithImageFilePath:path];
}

+ (OLAsset *)assetWithPHAsset:(PHAsset *)asset {
    return [[OLAsset alloc] initWithPHAsset:asset];
}

+ (OLAsset *)assetWithDataSource:(id<OLAssetDataSource>)dataSource {
    return [[OLAsset alloc] initWithDataSource:dataSource];
}

+ (OLAsset *)assetWithURL:(NSURL *)url {
    NSAssert([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"], @"bad url scheme (%@), only http & https are supported", url.scheme);
    
    NSString *urlStr = url.absoluteString;
    if ([urlStr hasSuffix:@"jpg"] || [urlStr hasSuffix:@"jpeg"]) {
        return [[OLAsset alloc] initWithImageURL:url mimeType:kOLMimeTypeJPEG];
    } else if ([urlStr hasSuffix:@"png"]) {
        return [[OLAsset alloc] initWithImageURL:url mimeType:kOLMimeTypePNG];
    } else if ([urlStr hasSuffix:@"tiff"] || [urlStr hasSuffix:@"tif"]) {
        return [[OLAsset alloc] initWithImageURL:url mimeType:kOLMimeTypeTIFF];
    } else if ([urlStr hasSuffix:@"pdf"]){
        return [[OLAsset alloc] initWithImageURL:url mimeType:kOLMimeTypePDF];
    } else {
        // Worst case scenario just assume it's a JPEG.
        return [[OLAsset alloc] initWithImageURL:url mimeType:kOLMimeTypeJPEG];
    }

    return nil;
}

- (void)setUploadedWithAssetId:(long long)assetId previewURL:(NSURL *)previewURL {
    _assetId = assetId;
    _previewURL = previewURL;
    _uploaded = YES;
}

- (void)dataLengthWithCompletionHandler:(GetDataLengthHandler)handler {
    switch (self.assetType) {
        case kOLAssetTypePHAsset:{
            PHImageManager *imageManager = [PHImageManager defaultManager];
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.synchronous = NO;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.networkAccessAllowed = YES;
            [imageManager requestImageForAsset:self.phAsset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info){
                if (result){
                    handler(UIImageJPEGRepresentation(result, 0.7).length, nil);
                }
                else{
                    self.corrupt = YES;
                    handler(0, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeImagesCorrupt userInfo:@{NSLocalizedDescriptionKey : info[PHImageErrorKey] ? info[PHImageErrorKey] : NSLocalizedString(@"There was an error getting one of your photos. Please remove or replace it.", @""), @"asset" : self}]);
                }
            }];
            break;
        }
        case kOLAssetTypeDataSource: {
            NSAssert(self.dataSource, @"oops somehow instantiated a OLAsset in non consistent state");
            [self.dataSource dataLengthWithCompletionHandler:^(long long dataLength, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (dataLength > 0){
                        handler(dataLength, error);
                    }
                    else{
                        self.corrupt = YES;
                        handler(0, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeImagesCorrupt userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"There was an error getting one of your photos. Please remove or replace it.", @""), @"asset" : self}]);
                    }
                });
            }];
            break;
        }
        case kOLAssetTypeImageData: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.imageData.length > 0){
                    handler(self.imageData.length, nil);
                }
                else{
                    self.corrupt = YES;
                    handler(0, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeImagesCorrupt userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"There was an error getting one of your photos. Please remove or replace it.", @""), @"asset" : self}]);
                }
            });
            break;
        }
        case kOLAssetTypeImageFilePath: {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *attributesError = nil;
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.imageFilePath error:&attributesError];
                NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
                if ([fileSizeNumber longLongValue] > 0){
                    handler([fileSizeNumber longLongValue], attributesError);
                }
                else{
                    self.corrupt = YES;
                    handler(0, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeImagesCorrupt userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"There was an error getting one of your photos. Please remove or replace it.", @""), @"asset" : self}]);
                }
            });
            
            break;
        }
        case kOLAssetTypeRemoteImageURL: {
                handler(0, nil);
            break;
        }
        case kOLAssetTypeCorrupt:
            handler(0, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeImagesCorrupt userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"There was an error getting one of your photos. Please remove or replace it.", @""), @"asset" : self}]);
            break;
    }
    
}

- (void)dataWithCompletionHandler:(GetDataHandler)handler {
    switch (self.assetType) {
        case kOLAssetTypePHAsset:{
            PHImageManager *imageManager = [PHImageManager defaultManager];
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.synchronous = NO;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.networkAccessAllowed = YES;
            [imageManager requestImageForAsset:self.phAsset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info){
                if (result){
                    handler(UIImageJPEGRepresentation(result, 0.7), nil);
                }
                else{
                    self.corrupt = YES;
                    NSData *data = [NSData dataWithContentsOfFile:[[OLKiteUtils kiteBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
                    handler(data, nil);
                }
            }];
            break;
        }
        case kOLAssetTypeDataSource: {
            NSAssert(self.dataSource, @"oops somehow instantiated a OLAsset in non consistent state");
            [self.dataSource dataWithCompletionHandler:^(NSData *data, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(data, error);
                });
            }];
            
            break;
        }
        case kOLAssetTypeImageData: {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(self.imageData, nil);
            });
            break;
        }
        case kOLAssetTypeImageFilePath: {
            NSError *error = nil;
            NSData *data = [NSData dataWithContentsOfFile:self.imageFilePath options:0 error:&error];
            handler(data, error);
            break;
        }
        case kOLAssetTypeRemoteImageURL: {
            //TODO could be edited
//            NSAssert(NO, @"don't be calling dataWithCompletionHandler on an image URL OLAsset as it has no meaning");
            break;
        }
        case kOLAssetTypeCorrupt:
            handler(nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeImagesCorrupt userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"There was an error getting one of your photos. Please remove or replace it.", @""), @"asset" : self}]);
            break;
    }
}

- (void)imageWithSize:(CGSize)size applyEdits:(BOOL)applyEdits progress:(void(^)(float progress))progress completion:(void(^)(UIImage *image))handler{
    if (!handler){
        //Nothing to do really
        return;
    }
    if (self.cachedEditedImage) {
        if (size.height * [OLUserSession currentSession].screenScale <= self.cachedEditedImage.size.height || size.width * [OLUserSession currentSession].screenScale <= self.cachedEditedImage.size.width){
            handler(self.cachedEditedImage);
            return;
        }
    }
    BOOL fullResolution = CGSizeEqualToSize(size, OLAssetMaximumSize);
    
    NSBlockOperation *blockOperation = [[NSBlockOperation alloc] init];
    [blockOperation addExecutionBlock:^{
        if (self.assetType == kOLAssetTypePHAsset) {
            PHImageManager *imageManager = [PHImageManager defaultManager];
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.synchronous = NO;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
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
            CGSize requestSize = fullResolution ? PHImageManagerMaximumSize : CGSizeMake(MAX(size.width * [OLUserSession currentSession].screenScale, 400), MAX(size.height * [OLUserSession currentSession].screenScale, 400));
            [imageManager requestImageForAsset:self.phAsset targetSize:requestSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *image, NSDictionary *info){
                if (applyEdits){
                    [self resizeImage:image size:size applyEdits:YES completion:^(UIImage *image){
                        self.cachedEditedImage = image;
                        handler(image);
                    }];
                }
                else{ //Image is already resized, no need to do it again
                    self.cachedEditedImage = image;
                    handler(image);
                }
            }];
        }
        else if (self.assetType == kOLAssetTypeImageData){
            [self resizeImage:[UIImage imageWithData:self.imageData] size:size applyEdits:YES completion:^(UIImage *image){
                self.cachedEditedImage = image;
                handler(image);
            }];
        }
        else if (self.assetType == kOLAssetTypeImageFilePath){
            NSData *imageData = [NSData dataWithContentsOfFile:self.imageFilePath options:0 error:nil];
            [self resizeImage:[UIImage imageWithData:imageData] size:size applyEdits:YES completion:^(UIImage *image){
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.cachedEditedImage = image;
                    handler(image);
                });
            }];
        }
        else if (/*self.assetType == kOLAssetTypeFacebookPhoto || self.assetType == kOLAssetTypeInstagramPhoto || */self.assetType == kOLAssetTypeRemoteImageURL) {
            [[OLImageDownloader sharedInstance] downloadImageAtURL:self.imageURL progress:^(NSInteger currentProgress, NSInteger total){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (progress) {
                        progress(MAX(0.05f, (float)currentProgress / (float) total));
                    }
                });
            }withCompletionHandler:^(UIImage *image, NSError *error){
                [self resizeImage:image size:size applyEdits:YES completion:^(UIImage *image){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!error) {
                            self.cachedEditedImage = image;
                            if (progress){
                                progress(1);
                            }
                            handler(image);
                        }
                    });
                }];
            }];
        }
        else if (self.assetType == kOLAssetTypeDataSource){
            [self.dataSource dataWithCompletionHandler:^(NSData *data, NSError *error){
                [self resizeImage:[UIImage imageWithData:data] size:size applyEdits:YES completion:^(UIImage *image){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.cachedEditedImage = image;
                        handler(image);
                    });
                }];
            }];
        }
        else if (self.assetType == kOLAssetTypeCorrupt){
            NSData *data = [NSData dataWithContentsOfFile:[[OLKiteUtils kiteBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
            handler([UIImage imageWithData:data]);
        }
        
    }];
    [[OLAsset imageOperationQueue] addOperation:blockOperation];
}

- (void)resizeImage:(UIImage *)image size:(CGSize)size applyEdits:(BOOL)applyEdits completion:(void(^)(UIImage *image))handler{
    __block UIImage *blockImage = image;
    void (^localBlock)() = ^{
        if (self.edits.counterClockwiseRotations > 0 || self.edits.flipHorizontal || self.edits.flipVertical){
            blockImage = [UIImage imageWithCGImage:blockImage.CGImage scale:blockImage.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.edits.counterClockwiseRotations andInitialOrientation:blockImage.imageOrientation horizontalFlip:self.edits.flipHorizontal verticalFlip:self.edits.flipVertical]];
        }
        
        if (!CGSizeEqualToSize(size, CGSizeZero) && !CGSizeEqualToSize(size, OLAssetMaximumSize)){
            blockImage = [blockImage shrinkToSize:size forScreenScale:[OLUserSession currentSession].screenScale];
        }
        
        if (![self isEdited] || !applyEdits){
            handler(blockImage);
            return;
        }
        
        blockImage = [RMImageCropper editedImageFromImage:blockImage andFrame:self.edits.cropImageFrame andImageRect:self.edits.cropImageRect andImageViewWidth:self.edits.cropImageSize.width andImageViewHeight:self.edits.cropImageSize.height];
        
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
        [[OLAsset imageOperationQueue] addOperation:block];
    }
    else{
        localBlock();
    }
}

- (void)unloadImage {
    self.cachedEditedImage = nil; // we can always recreate this
}

- (BOOL)isEdited{
    return !CGRectIsEmpty(self.edits.cropImageFrame) || !CGRectIsEmpty(self.edits.cropImageRect) || !CGSizeEqualToSize(self.edits.cropImageSize, CGSizeZero) || self.edits.counterClockwiseRotations > 0 || self.edits.flipHorizontal || self.edits.flipVertical;
}

- (NSUInteger)hash {
    return 31 * (31 * (31 * (31 * (self.mimeType.hash * 31 + self.imageData.hash) + self.imageFilePath.hash) + [self.phAsset localIdentifier].hash) + self.dataSource.hash) + self.imageURL.hash; //TODO missing
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[OLAsset class]]) {
        return NO;
    }
    
    if (object == self) {
        return YES;
    }
    
    if (![self.mimeType isEqualToString:[object mimeType]]) {
        return NO;
    }
    
    switch (self.assetType) {
        case kOLAssetTypePHAsset: {
            return [[self.phAsset localIdentifier] isEqualToString:[[object phAsset] localIdentifier]];
        }
        case kOLAssetTypeDataSource: {
            NSAssert(self.dataSource, @"oops somehow instantiated a OLAsset in non consistent state");
            return self.dataSource == (id<OLAssetDataSource>) [object dataSource] || [self.dataSource isEqual:[object dataSource]];
        }
        case kOLAssetTypeImageData: {
            return [self.imageData isEqualToData:[object imageData]];
        }
        case kOLAssetTypeImageFilePath: {
            return [self.imageFilePath isEqualToString:[object imageFilePath]];
        }
        case kOLAssetTypeRemoteImageURL: {
            return [self.imageURL isEqual:[object imageURL]];
        }
        default:
            return NO;
    }
}

- (id)copyWithZone:(NSZone *)zone{
    OLAsset *copy = [[OLAsset alloc] init];
    copy.imageFilePath = self.imageFilePath;
    copy.imageData = self.imageData;
    copy.phAsset = self.phAsset;
    copy.dataSource = self.dataSource;
    copy.imageURL = self.imageURL;
    copy.corrupt = self.corrupt;
    copy.extraCopies = self.extraCopies;
    copy.edits = [self.edits copyWithZone:zone];
    copy.uuid = self.uuid;
    copy.mimeType = self.mimeType;
    copy.assetId = self.assetId;
    copy.previewURL = self.previewURL;
    
    return copy;
}

#pragma mark - NSCoding methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.mimeType forKey:kKeyMimeType];
    [aCoder encodeObject:self.imageFilePath forKey:kKeyImageFilePath];
    [aCoder encodeObject:self.imageData forKey:kKeyImageData];
    [aCoder encodeObject:self.dataSource forKey:kKeyDataSource];
    [aCoder encodeObject:self.imageURL forKey:kKeyImageURL];
    [aCoder encodeObject:[self.phAsset localIdentifier] forKey:kKeyPHAssetLocalId];
    // TODO: encode uploaded including asset id & preview url?!
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSString *mimeType = [aDecoder decodeObjectForKey:kKeyMimeType];
        if ([kOLMimeTypeJPEG isEqualToString:mimeType]) {
            _mimeType = kOLMimeTypeJPEG;
        } else if ([kOLMimeTypePNG isEqualToString:mimeType]) {
            _mimeType = kOLMimeTypePNG;
        } else if ([kOLMimeTypeTIFF isEqualToString:mimeType]) {
            _mimeType = kOLMimeTypeTIFF;
        } else {
            _mimeType = kOLMimeTypePNG;
        }
        self.imageFilePath = [aDecoder decodeObjectForKey:kKeyImageFilePath];
        self.imageData = [aDecoder decodeObjectForKey:kKeyImageData];
        self.dataSource = [aDecoder decodeObjectForKey:kKeyDataSource];
        self.imageURL = [aDecoder decodeObjectForKey:kKeyImageURL];
        
        NSString *localId = [aDecoder decodeObjectForKey:kKeyPHAssetLocalId];
        if (localId){
            self.phAsset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localId] options:nil] firstObject];
        }
    }
    
    return self;
}

@end
