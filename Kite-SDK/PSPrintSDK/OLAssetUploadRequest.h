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

/**
 *  Implement this delegate protocol to be notified of progress and completion status of the uploads.
 */
@protocol OLAssetUploadRequestDelegate <NSObject>

/**
 *  Notifies the delegate that the upload has progressed.
 *
 *  @param req                            The request
 *  @param totalAssetsUploaded            The number of assets uploaded
 *  @param totalAssetsToUpload            The number of assets to be uploaded
 *  @param bytesWritten                   The number of bytes uploaded
 *  @param totalAssetBytesWritten         The total number of asset bytes uploaded
 *  @param totalAssetBytesExpectedToWrite The total number of asset bytes expected to be uploaded
 */
- (void)assetUploadRequest:(OLAssetUploadRequest *)req didProgressWithTotalAssetsUploaded:(NSUInteger)totalAssetsUploaded totalAssetsToUpload:(NSUInteger)totalAssetsToUpload bytesWritten:(long long)bytesWritten totalAssetBytesWritten:(long long)totalAssetBytesWritten totalAssetBytesExpectedToWrite:(long long)totalAssetBytesExpectedToWrite;

/**
 *  Notifies the delegate that the upload has finished successfully.
 *
 *  @param req    The request
 *  @param assets The assets uploaded
 */
- (void)assetUploadRequest:(OLAssetUploadRequest *)req didSucceedWithAssets:(NSArray<OLAsset *> *)assets;

/**
 *  Notifies the delegate that the upload has failed
 *
 *  @param req   The request
 *  @param error The error
 */
- (void)assetUploadRequest:(OLAssetUploadRequest *)req didFailWithError:(NSError *)error;
@end

/**
 *  Class that handles the asset upload requests
 */
@interface OLAssetUploadRequest : NSObject

/**
 *  Cancel the upload
 */
- (void)cancelUpload;

/**
 *  Upload a jpeg image
 *
 *  @param image The image
 */
- (void)uploadImageAsJPEG:(UIImage *)image;

/**
 *  Upload a png image
 *
 *  @param image The image
 */
- (void)uploadImageAsPNG:(UIImage *)image;

/**
 *  Upload an OLAsset
 *
 *  @param asset The asset
 */
- (void)uploadOLAsset:(OLAsset *)asset;

/**
 *  Upload an array of OLAssets
 *
 *  @param assets The array of OLAssets
 */
- (void)uploadOLAssets:(NSArray<OLAsset *> *)assets;

/**
 *  Delegate object
 */
@property (nonatomic, weak) id<OLAssetUploadRequestDelegate> delegate;

@end
