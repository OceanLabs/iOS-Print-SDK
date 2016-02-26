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

@class ALAsset;
@class PHAsset;
@class OLPrintPhoto;

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

/**
 *  Completion handler when loading the ALAsset
 *
 *  @param asset The ALAsset
 *  @param error The error
 */
typedef void (^LoadAssetCompletionHandler)(ALAsset *asset, NSError *error);

extern NSString *const kOLMimeTypeJPEG;
extern NSString *const kOLMimeTypePNG;
extern NSString *const kOLMimeTypeTIFF;
extern NSString *const kOLMimeTypePDF;

/**
 *  Protocol for a custom class to implement if they want to provide the data for an OLAsset.
 *  For example a custom image class that isn't built in to OLAsset can be used with OLAsset by implementing this protocol.
 */
@protocol OLAssetDataSource <NSObject, NSCoding>
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
 *  Optional method to delete any cache files from disk
 */
- (void)deleteFromDisk;
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
 *  Asset data in the form of a pre-rendered PDF. Using a PDF will not allow any editing functionality.
 *
 *  @param data The data
 *
 *  @return The OLAsset.
 */
+ (OLAsset *)assetWithDataAsPDF:(NSData *)data;

/**
 *  Create an asset with a file path
 *
 *  @param path The file path
 *
 *  @return The OLAsset
 */
+ (OLAsset *)assetWithFilePath:(NSString *)path;

/**
 *  Create an asset with an ALAsset
 *
 *  @param asset The ALAsset
 *
 *  @return The OLAsset
 */
+ (OLAsset *)assetWithALAsset:(ALAsset *)asset;

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
 *
 *  @return The OLAsset
 */
+ (OLAsset *)assetWithURL:(NSURL *)url;

/**
 *  Create an asset with a OLPrintPhoto
 *
 *  @param printPhoto The OLPrintPhoto
 *
 *  @return The OLAsset
 */
+ (OLAsset *)assetWithPrintPhoto:(OLPrintPhoto *)printPhoto;

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

/**
 *  The Kite previewURL. Will only be valid upon sucessfully uploading this asset to the server i.e. OLAsset.isUploaded == YES
 */
@property (nonatomic, readonly) NSURL *previewURL;

/**
 *  Special method for OLAssets created from ALAssets. Loads the ALAsset.
 *
 *  @param handler Completion handler
 */
- (void)loadALAssetWithCompletionHandler:(LoadAssetCompletionHandler)handler;

/**
 *  Special method for OLAssets created from PHAssets. Finds and returns the PHAsset in the PHAssetLibrary with the known localIdentifier.
 *
 *  @return The PHAsset
 */
- (PHAsset *)loadPHAsset;

/**
 *  Method to delete any cache files from disk
 */
- (void)deleteFromDisk;

@end
