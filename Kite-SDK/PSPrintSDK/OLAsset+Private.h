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

#import "OLAsset.h"

typedef enum {
    kOLAssetTypeALAsset,
    kOLAssetTypePHAsset,
    kOLAssetTypeRemoteImageURL,
    kOLAssetTypeImageFilePath,
    kOLAssetTypeImageData,
    kOLAssetTypeDataSource
} OLAssetType;

@interface OLAsset (FriendMethods)

@property (nonatomic, strong) id<OLAssetDataSource> dataSource;

- (void)setUploadedWithAssetId:(long long)assetId previewURL:(NSURL *)previewURL;
- (void)dataLengthWithCompletionHandler:(GetDataLengthHandler)handler;
- (void)dataWithCompletionHandler:(GetDataHandler)handler;
@property (nonatomic, readonly) OLAssetType assetType;
@property (nonatomic, strong) NSString *imageFilePath;
@property (nonatomic, strong) NSURL *imageURL; // if this is set no image data is going to be uploaded, rather we will just pass the url to the server and it can fetch the image when printing
@end

