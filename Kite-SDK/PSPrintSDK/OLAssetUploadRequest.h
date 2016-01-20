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

#import <Foundation/Foundation.h>

@class OLAsset;
@class OLAssetUploadRequest;

/**
 *  Implement this delegate protocol to be notified of progress and completion status of the uploads.
 */
@protocol OLAssetUploadRequestDelegate <NSObject>

@optional

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
