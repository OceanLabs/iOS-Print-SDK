//
//  OLAsset.m
//  Kite SDK
//
//  Created by Deon Botha on 27/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLAsset.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "OLURLDataSource.h"
#import "OLAsset+Private.h"
#import "OLPrintPhoto.h"

#ifdef OL_KITE_OFFER_INSTAGRAM
#import <OLInstagramImage.h>
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#import <OLFacebookImage.h>
#endif

static NSString *const kKeyMimeType = @"co.oceanlabs.pssdk.kKeyMimeType";
static NSString *const kKeyImageData = @"co.oceanlabs.pssdk.kKeyImageData";
static NSString *const kKeyImageFilePath = @"co.oceanlabs.pssdk.kKeyImageFilePath";
static NSString *const kKeyALAssetURL = @"co.oceanlabs.pssdk.kKeyALAssetURL";
static NSString *const kKeyDataSource = @"co.oceanlabs.pssdk.kKeyDataSource";
static NSString *const kKeyImageURL = @"co.oceanlabs.pssdk.kKeyImageURL";

NSString *const kOLMimeTypeJPEG = @"image/jpeg";
NSString *const kOLMimeTypePNG  = @"image/png";

@interface OLAsset ()
@property (nonatomic, strong) NSString *imageFilePath;
@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, strong) NSURL *alAssetURL;
@property (nonatomic, strong) ALAssetsLibrary *alAssetsLibrary;
@property (nonatomic, strong) ALAsset *alAsset;
@property (nonatomic, strong) id<OLAssetDataSource> dataSource;
@property (nonatomic, strong) NSURL *imageURL;
@end

@implementation OLAsset

- (BOOL)isCropBoxSet {
    return self.cropBox.origin.x != 0 || self.cropBox.origin.y != 0 || self.cropBox.size.width != 0 || self.cropBox.size.height != 0;
}

- (NSData *) cropImageWithData:(NSData *)data{
    if (![self isCropBoxSet]){
        return data;
    }
    
    UIImage *image = [UIImage imageWithData:data];
    
    CGRect absCropBox = CGRectMake(self.cropBox.origin.x * image.size.width, self.cropBox.origin.y * image.size.height, self.cropBox.size.width * image.size.width, self.cropBox.size.height * image.size.height);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], absCropBox);
    UIImage *imgs = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    if (imgs){
        return UIImageJPEGRepresentation(imgs, 0.8);
    }
    else{
        return data;
    }
    
    
    
}

- (id)initWithImageData:(NSData *)data mimeType:(NSString *)mimeType {
    if (self = [super init]) {
        NSAssert(data != nil, @"image data must be non nil");
        NSAssert(mimeType != nil, @"mime type must be non nil");
        self.imageData = data;
        _mimeType = mimeType;
    }
    
    return self;
}

- (id)initWithImageFilePath:(NSString *)imageFilePath {
    if (self = [super init]) {
        self.imageFilePath = imageFilePath;
        if ([imageFilePath hasSuffix:@".jpg"] || [imageFilePath hasSuffix:@".jpeg"]) {
            _mimeType = kOLMimeTypeJPEG;
        } else if ([imageFilePath hasSuffix:@".png"]) {
            _mimeType = kOLMimeTypePNG;
        } else {
            NSAssert(NO, @"Only JPEG & PNG images are supported");
        }
    }
    
    return self;
}

- (id)initWithALAsset:(ALAsset *)asset {
    if (self = [super init]) {
        NSString *fileName = [[[asset defaultRepresentation] filename] lowercaseString];
        if ([fileName hasSuffix:@".jpg"] || [fileName hasSuffix:@".jpeg"]) {
            _mimeType = kOLMimeTypeJPEG;
        } else if ([fileName hasSuffix:@".png"]) {
            _mimeType = kOLMimeTypePNG;
        } else {
            NSAssert(NO, @"Only JPEG & PNG images are supported");
        }
        
        self.alAssetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
        
    }
    
    return self;
}

- (id)initWithImageURL:(NSURL *)url mimeType:(NSString *)mimeType {
    if (self = [super init]) {
        _mimeType = mimeType;
        _imageURL = url;
    }
    
    return self;
}

- (id)initWithDataSource:(id<OLAssetDataSource>)dataSource {
    if (self = [super init]) {
        NSAssert([dataSource conformsToProtocol:@protocol(OLAssetDataSource)], @"Oops your class %@ does not conform to the OLAssetDataSource protocol", [dataSource class]);
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
    } else {
        NSAssert(NO, @"oops added a new type of asset data source without doing all the real work :)");
        return 0;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[AssetID: %lld URL: %@]", self.assetId, self.imageURL];
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

+ (OLAsset *)assetWithFilePath:(NSString *)path {
    return [[OLAsset alloc] initWithImageFilePath:path];
}

+ (OLAsset *)assetWithALAsset:(ALAsset *)asset {
    return [[OLAsset alloc] initWithALAsset:asset];
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

- (void)loadALAssetWithCompletionHandler:(LoadAssetCompletionHandler)handler {
    if (self.alAsset) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(self.alAsset, nil);
        });
    } else {
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        [assetLibrary assetForURL:self.alAssetURL
                      resultBlock:^(ALAsset *asset) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              NSAssert([NSThread isMainThread], @"oops wrong assumption about main thread callback");
                              self.alAssetsLibrary = assetLibrary;
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
                        handler([self cropImageWithData:data].length, nil);
                    }
                } else {
                    handler(0, error);
                }
            }];
            break;
        }
        case kOLAssetTypeDataSource: {
            NSAssert(self.dataSource, @"oops somehow instantiated a OLAsset in non consistent state");
            [self.dataSource dataLengthWithCompletionHandler:^(long long dataLength, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(dataLength, error);
                });
            }];
            break;
        }
        case kOLAssetTypeImageData: {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler([self cropImageWithData:self.imageData].length, nil);
            });
            break;
        }
        case kOLAssetTypeImageFilePath: {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *attributesError = nil;
                if ([self isCropBoxSet]){
                    handler([NSData dataWithContentsOfFile:self.imageFilePath options:0 error:&attributesError].length, attributesError);
                }
                else{
                    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.imageFilePath error:&attributesError];
                    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
                    handler([fileSizeNumber longLongValue], attributesError);
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
                        handler([self cropImageWithData:data], nil);
                    }
                } else {
                    handler(nil, error);
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
                handler([self cropImageWithData:self.imageData], nil);
            });
            break;
        }
        case kOLAssetTypeImageFilePath: {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = nil;
                NSData *data = [NSData dataWithContentsOfFile:self.imageFilePath options:0 error:&error];
                handler([self cropImageWithData:data], error);
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
    // TODO: encode uploaded including asset id & preview url?!
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSString *mimeType = [aDecoder decodeObjectForKey:kKeyMimeType];
        _mimeType = [kOLMimeTypeJPEG isEqualToString:mimeType] ? kOLMimeTypeJPEG : kOLMimeTypePNG;
        self.imageFilePath = [aDecoder decodeObjectForKey:kKeyImageFilePath];
        self.imageData = [aDecoder decodeObjectForKey:kKeyImageData];
        self.alAssetURL = [aDecoder decodeObjectForKey:kKeyALAssetURL];
        self.dataSource = [aDecoder decodeObjectForKey:kKeyDataSource];
        self.imageURL = [aDecoder decodeObjectForKey:kKeyImageURL];
    }
    
    return self;
}

@end
