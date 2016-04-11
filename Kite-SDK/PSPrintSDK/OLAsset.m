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
#import <AssetsLibrary/AssetsLibrary.h>
#import "OLURLDataSource.h"
#import "OLAsset+Private.h"
#import "OLPrintPhoto.h"
#import "ALAssetsLibrary+Singleton.h"
#import "OLKiteUtils.h"
#import "OLConstants.h"

#ifdef OL_KITE_OFFER_INSTAGRAM
#import <InstagramImagePicker/OLInstagramImage.h>
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#import <FacebookImagePicker/OLFacebookImage.h>
#endif

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

@interface OLAsset ()
@property (nonatomic, strong) NSString *imageFilePath;
@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, strong) NSURL *alAssetURL;
@property (nonatomic, strong) NSString *phAssetLocalId;
@property (nonatomic, strong) ALAsset *alAsset;
@property (nonatomic, strong) id<OLAssetDataSource> dataSource;
@property (nonatomic, strong) NSURL *imageURL;
@property (assign, nonatomic) BOOL corrupt;
@end

@implementation OLAsset

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

- (instancetype)initWithALAsset:(ALAsset *)asset {
    if (self = [super init]) {
        NSString *fileName = [[[asset defaultRepresentation] filename] lowercaseString];
        if ([fileName hasSuffix:@".jpg"] || [fileName hasSuffix:@".jpeg"]) {
            _mimeType = kOLMimeTypeJPEG;
        } else if ([fileName hasSuffix:@".png"]) {
            _mimeType = kOLMimeTypePNG;
        } else if ([fileName hasSuffix:@".tif"] || [fileName hasSuffix:@".tiff"]) {
            _mimeType = kOLMimeTypeTIFF;
        } else {
            NSAssert(NO, @"Only JPEG, PNG & TIFF images are supported");
        }
        
        self.alAssetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
        
    }
    
    return self;
}

- (instancetype)initWithPHAsset:(PHAsset *)asset {
    if (self = [super init]) {
        _mimeType = kOLMimeTypeJPEG;
        self.phAssetLocalId = [asset localIdentifier];
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
    } else if (self.imageURL) {
        return kOLAssetTypeRemoteImageURL;
    } else if (self.imageFilePath) {
        return kOLAssetTypeImageFilePath;
    } else if (self.alAssetURL) {
        return kOLAssetTypeALAsset;
    } else if (self.dataSource) {
        return kOLAssetTypeDataSource;
    } else if (self.phAssetLocalId){
        return kOLAssetTypePHAsset;
    } else {
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

+ (OLAsset *)assetWithALAsset:(ALAsset *)asset {
    return [[OLAsset alloc] initWithALAsset:asset];
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
        // Worst case scenario where we will need to download the entire image first and just assume it's a JPEG.
        return [OLAsset assetWithDataSource:[[OLURLDataSource alloc] initWithURLString:urlStr]];
    }

    return nil;
}

+ (OLAsset *)assetWithPrintPhoto:(OLPrintPhoto *)printPhoto{
    if ([[printPhoto asset] isKindOfClass: [ALAsset class]]){
        return [OLAsset assetWithALAsset:[printPhoto asset]];
    }
    else if ([[printPhoto asset] isKindOfClass: [PHAsset class]]){
        return [OLAsset assetWithPHAsset:[printPhoto asset]];
    }
#ifdef OL_KITE_OFFER_INSTAGRAM
    else if ([[printPhoto asset] isKindOfClass: [OLInstagramImage class]]){
        return [OLAsset assetWithURL:[[printPhoto asset] fullURL]];
    }
#endif
#ifdef OL_KITE_OFFER_FACEBOOK
    else if ([[printPhoto asset] isKindOfClass: [OLFacebookImage class]]){
        return [OLAsset assetWithURL:[[printPhoto asset] fullURL]];
    }
#endif
    else if ([[printPhoto asset] isKindOfClass:[OLAsset class]]){
        return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:[printPhoto asset]]];
    }
    
    else if ([[printPhoto asset] isKindOfClass:[ALAsset class]]){
        return [OLAsset assetWithALAsset:[printPhoto asset]];
    }
    
    return nil;
}

- (void)setUploadedWithAssetId:(long long)assetId previewURL:(NSURL *)previewURL {
    _assetId = assetId;
    _previewURL = previewURL;
    _uploaded = YES;
}

- (PHAsset *)loadPHAsset{
    return [[PHAsset fetchAssetsWithLocalIdentifiers:@[self.phAssetLocalId] options:nil] firstObject];
}

- (void)loadALAssetWithCompletionHandler:(LoadAssetCompletionHandler)handler {
    if (self.alAsset) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(self.alAsset, nil);
        });
    } else {
        [[ALAssetsLibrary defaultAssetsLibrary] assetForURL:self.alAssetURL
                      resultBlock:^(ALAsset *asset) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              NSAssert([NSThread isMainThread], @"oops wrong assumption about main thread callback");
                              self.alAsset = asset;
                              handler(self.alAsset, nil);
                          });
                      }
                     failureBlock:^(NSError *err) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             NSAssert([NSThread isMainThread], @"oops wrong assumption about main thread callback");
                             handler(nil, err);
                         });
                     }];
    }
}

- (void)dataLengthWithCompletionHandler:(GetDataLengthHandler)handler {
    switch (self.assetType) {
        case kOLAssetTypeALAsset: {
            [self loadALAssetWithCompletionHandler:^(ALAsset *asset, NSError *error) {
                if (asset && !error) {
                    ALAssetRepresentation *rep = asset.defaultRepresentation;
                    uint8_t *buffer = (uint8_t *) malloc((unsigned long) rep.size);
                    NSError *error = nil;
                    NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:(NSInteger) rep.size error:&error];
                    if (error) {
                        handler(0, error);
                    } else {
                        NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                        handler(data.length, nil);
                    }
                } else {
                    handler(0, error);
                }
            }];
            break;
        }
        case kOLAssetTypePHAsset:{
            PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[self.phAssetLocalId] options:nil] firstObject];
            if (!asset){
                self.corrupt = YES;
                NSData *data = [NSData dataWithContentsOfFile:[[OLKiteUtils kiteBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
                handler(data.length, nil);
                return;
            }
            PHImageManager *imageManager = [PHImageManager defaultManager];
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.synchronous = NO;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.networkAccessAllowed = YES;
            [imageManager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info){
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
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(0, nil);
            });
            break;
        }
    }
    
}

- (void)dataWithCompletionHandler:(GetDataHandler)handler {
    switch (self.assetType) {
        case kOLAssetTypeALAsset: {
            [self loadALAssetWithCompletionHandler:^(ALAsset *asset, NSError *error) {
                if (asset && !error) {
                    ALAssetRepresentation *rep = asset.defaultRepresentation;
                    uint8_t *buffer = (uint8_t *) malloc((unsigned long) rep.size);
                    NSError *error = nil;
                    NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:(NSInteger) rep.size error:&error];
                    if (error) {
                        handler(nil, error);
                    } else {
                        NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                        handler(data, nil);
                    }
                } else {
                    handler(nil, error);
                }
            }];
            break;
        }
        case kOLAssetTypePHAsset:{
            PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[self.phAssetLocalId] options:nil] firstObject];
            if (!asset){
                self.corrupt = YES;
                NSData *data = [NSData dataWithContentsOfFile:[[OLKiteUtils kiteBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
                handler(data, nil);
                return;
            }
            PHImageManager *imageManager = [PHImageManager defaultManager];
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.synchronous = NO;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.networkAccessAllowed = YES;
            [imageManager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info){
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
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = nil;
                NSData *data = [NSData dataWithContentsOfFile:self.imageFilePath options:0 error:&error];
                handler(data, error);
            });
            break;
        }
        case kOLAssetTypeRemoteImageURL: {
            NSAssert(NO, @"don't be calling dataWithCompletionHandler on an image URL OLAsset as it has no meaning");
            break;
        }
    }
}

- (NSUInteger)hash {
    return 31 * (31 * (31 * (31 * (self.mimeType.hash * 31 + self.imageData.hash) + self.imageFilePath.hash) + self.alAssetURL.hash) + self.dataSource.hash) + self.imageURL.hash;
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
        case kOLAssetTypeALAsset: {
            return [self.alAssetURL isEqual:[object alAssetURL]];
        }
        case kOLAssetTypePHAsset: {
            return [self.phAssetLocalId isEqualToString:[object phAssetLocalId]];
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
    }
}

#pragma mark - NSCoding methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.mimeType forKey:kKeyMimeType];
    [aCoder encodeObject:self.imageFilePath forKey:kKeyImageFilePath];
    [aCoder encodeObject:self.imageData forKey:kKeyImageData];
    [aCoder encodeObject:self.alAssetURL forKey:kKeyALAssetURL];
    [aCoder encodeObject:self.dataSource forKey:kKeyDataSource];
    [aCoder encodeObject:self.imageURL forKey:kKeyImageURL];
    [aCoder encodeObject:self.phAssetLocalId forKey:kKeyPHAssetLocalId];
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
        self.alAssetURL = [aDecoder decodeObjectForKey:kKeyALAssetURL];
        self.dataSource = [aDecoder decodeObjectForKey:kKeyDataSource];
        self.imageURL = [aDecoder decodeObjectForKey:kKeyImageURL];
        self.phAssetLocalId = [aDecoder decodeObjectForKey:kKeyPHAssetLocalId];
    }
    
    return self;
}

//If we ever need to enable this again, make sure we only delete our own asset, eg prefix them with OL or something
- (void)deleteFromDisk{
    
//    if (self.dataSource && [self.dataSource respondsToSelector:@selector(deleteFromDisk)]){
//        [self.dataSource deleteFromDisk];
//    }
//    else if(self.imageFilePath){
//        NSFileManager *fileManager = [NSFileManager defaultManager];
//        NSError *error;
//        BOOL fileExists = [fileManager fileExistsAtPath:self.imageFilePath];
//        if (fileExists)
//        {
//            BOOL success = [fileManager removeItemAtPath:self.imageFilePath error:&error];
//            if (!success) {
//#ifdef OL_VERBOSE
//                NSLog(@"Error: %@", [error localizedDescription]);
//#endif
//            }
//        }
//    }
}

@end
