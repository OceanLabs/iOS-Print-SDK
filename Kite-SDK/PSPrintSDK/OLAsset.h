//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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

#import <UIKit/UIKit.h>

@class PHAsset;

/**
 *  Use this size to request the maximum available size of an image
 */
extern CGSize const OLAssetMaximumSize;

/**
 *  Handler to get the data length
 *
 *  @param dataLength The data length
 *  @param error      The error
 */
typedef void (^GetDataLengthHandler)(long long dataLength, NSError *error);

/**
 *  Handler to get the data
 *
 *  @param data  The data
 *  @param error The error
 */
typedef void (^GetDataHandler)(NSData *data, NSError *error);

extern NSString *const kOLMimeTypeJPEG;
extern NSString *const kOLMimeTypePNG;

/**
 *  Protocol for a custom class to implement if they want to provide the data for an OLAsset.
 *  For example a custom image class that isn't built in to OLAsset can be used with OLAsset by implementing this protocol.
 */
@protocol OLAssetDataSource <NSObject, NSCoding, NSCopying>
/**
 *  The mime type of the image
 *
 *  @return The mime type of the image
 */
- (NSString *)mimeType;

/**
 *  Provide the length of the data
 *
 *  @param handler Handler to provide the length of the data asynchronously
 */
- (void)dataLengthWithCompletionHandler:(GetDataLengthHandler)handler;

/**
 *  The data of the image
 *
 *  @param handler Handler to provide the data of the image asynchronously
 */
- (void)dataWithCompletionHandler:(GetDataHandler)handler;

@optional

/**
 *  Optional method to cancel loading of the image (for example downloading from the network)
 */
- (void)cancelAnyLoadingOfData;


/**
 Provide the image at the requested size.

 @param size The requested size
 @param handler Handler to provide the image asynchronously
 */
- (void)imageForSize:(CGSize)size completionHandler:(void(^)(UIImage *image, NSError *error))handler;
@end

/**
 *  This object holds the image data to be sent for printing. Supports various formats such as jpeg/png data, UIIMage, URLs, ALAssets, PHAssets and file paths
 */
@interface OLAsset : NSObject <NSCoding>

/**
 *  Create an asset with a UIImage
 *
 *  @param image The image
 *
 *  @return The OLAsset
 */
+ (OLAsset *)assetWithImageAsJPEG:(UIImage *)image;

/**
 *  Create an asset with a UIImage
 *
 *  @param image The image
 *
 *  @return The OLAsset
 */
+ (OLAsset *)assetWithImageAsPNG:(UIImage *)image;

/**
 *  Create an asset with JPEG data
 *
 *  @param data The data
 *
 *  @return The OLAsset
 */
+ (OLAsset *)assetWithDataAsJPEG:(NSData *)data;

/**
 *  Create an asset with PNG data
 *
 *  @param data The data
 *
 *  @return The OLAsset
 */
+ (OLAsset *)assetWithDataAsPNG:(NSData *)data;

/**
 *  Create an asset with a file path
 *
 *  @param path The file path
 *
 *  @return The OLAsset
 */
+ (OLAsset *)assetWithFilePath:(NSString *)path;

/**
 *  Create an asset with a PHAsset
 *
 *  @param asset The PHAsset
 *
 *  @return The OLAsset
 */
+ (OLAsset *)assetWithPHAsset:(PHAsset *)asset;

/**
 *  Create an asset with a custom class implementing the OLAssetDataSource protocol
 *
 *  @param dataSource The custom object
 *
 *  @return The OLAsset
 */
+ (OLAsset *)assetWithDataSource:(id<OLAssetDataSource>)dataSource;

/**
 *  Create an asset with a URL
 *
 *  @param url The URL
 *  @param size The original size of the image
 *
 *  @return The OLAsset
 */
+ (OLAsset *)assetWithURL:(NSURL *)url size:(CGSize)size;

/**
 *  The mime type of the asset
 */
@property (nonatomic, readonly) NSString *mimeType;

/**
 *  Boolean that shows if the asset has been uploaded
 */
@property (nonatomic, readonly, getter = isUploaded) BOOL uploaded;

/**
 *  The Kite assetID. Will only be valid upon sucessfully uploading this asset to the server i.e. OLAsset.isUploaded == YES
 */
@property (nonatomic, readonly) long long assetId;

@end
