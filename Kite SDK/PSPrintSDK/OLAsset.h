//
//  OLAsset.h
//  Kite SDK
//
//  Created by Deon Botha on 27/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALAsset;

typedef void (^GetDataLengthHandler)(long long dataLength, NSError *error);
typedef void (^GetDataHandler)(NSData *data, NSError *error);
typedef void (^LoadAssetCompletionHandler)(ALAsset *asset, NSError *error);

static NSString *const kOLMimeTypeJPEG = @"image/jpeg";
static NSString *const kOLMimeTypePNG  = @"image/png";

@protocol OLAssetDataSource <NSObject, NSCoding>
- (NSString *)mimeType;
- (void)dataLengthWithCompletionHandler:(GetDataLengthHandler)handler;
- (void)dataWithCompletionHandler:(GetDataHandler)handler;
@optional
- (void)cancelAnyLoadingOfData;
@end

@interface OLAsset : NSObject <NSCoding>

+ (OLAsset *)assetWithImageAsJPEG:(UIImage *)image;
+ (OLAsset *)assetWithImageAsPNG:(UIImage *)image;
+ (OLAsset *)assetWithDataAsJPEG:(NSData *)data;
+ (OLAsset *)assetWithDataAsPNG:(NSData *)data;
+ (OLAsset *)assetWithFilePath:(NSString *)path;
+ (OLAsset *)assetWithALAsset:(ALAsset *)asset;
+ (OLAsset *)assetWithDataSource:(id<OLAssetDataSource>)dataSource;
+ (OLAsset *)assetWithURL:(NSURL *)url;

@property (nonatomic, readonly) NSString *mimeType;

@property (nonatomic, readonly, getter = isUploaded) BOOL uploaded;

/*
 * The next two variables will only be valid upon sucessfully uploading this asset to the server i.e. OLAsset.isUploaded == YES
 */
@property (nonatomic, readonly) long long assetId;
@property (nonatomic, readonly) NSURL *previewURL;
@property(nonatomic, assign)CGRect cropBox;

@property (nonatomic, readonly, getter = isCropBoxSet) BOOL cropboxSet;

- (void)loadALAssetWithCompletionHandler:(LoadAssetCompletionHandler)handler;

@end
