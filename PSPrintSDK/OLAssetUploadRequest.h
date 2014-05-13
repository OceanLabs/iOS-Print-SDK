//
//  OLAssetUploadRequest.h
//  Kite SDK
//
//  Created by Deon Botha on 26/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLAsset;
@class OLAssetUploadRequest;

@protocol OLAssetUploadRequestDelegate <NSObject>
- (void)assetUploadRequest:(OLAssetUploadRequest *)req didProgressWithTotalAssetsUploaded:(NSUInteger)totalAssetsUploaded totalAssetsToUpload:(NSUInteger)totalAssetsToUpload bytesWritten:(long long)bytesWritten totalAssetBytesWritten:(long long)totalAssetBytesWritten totalAssetBytesExpectedToWrite:(long long)totalAssetBytesExpectedToWrite;
- (void)assetUploadRequest:(OLAssetUploadRequest *)req didSucceedWithAssets:(NSArray/*<OLAsset>*/ *)assets;
- (void)assetUploadRequest:(OLAssetUploadRequest *)req didFailWithError:(NSError *)error;
@end

@interface OLAssetUploadRequest : NSObject

- (void)cancelUpload;

- (void)uploadImageAsJPEG:(UIImage *)image;
- (void)uploadImageAsPNG:(UIImage *)image;
- (void)uploadOLAsset:(OLAsset *)asset;
- (void)uploadOLAssets:(NSArray/*<OLAssets>*/ *)assets;

@property (nonatomic, weak) id<OLAssetUploadRequestDelegate> delegate;

@end
