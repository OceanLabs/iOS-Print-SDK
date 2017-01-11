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

#import "OLAsset.h"
#import "OLPhotoEdits.h"
#import "OLPlaceholderAsset.h"

typedef enum {
    kOLAssetTypeCorrupt,
    kOLAssetTypePHAsset,
    kOLAssetTypeRemoteImageURL,
    kOLAssetTypeImageFilePath,
    kOLAssetTypeImageData,
    kOLAssetTypeDataSource,
//    kOLAssetTypeFacebookPhoto,
//    kOLAssetTypeInstagramPhoto
} OLAssetType;

@interface OLAsset (FriendMethods)

@property (nonatomic, strong) id<OLAssetDataSource> dataSource;

- (void)setUploadedWithAssetId:(long long)assetId previewURL:(NSURL *)previewURL;
- (void)dataLengthWithCompletionHandler:(GetDataLengthHandler)handler;
- (void)dataWithCompletionHandler:(GetDataHandler)handler;
- (void)imageWithSize:(CGSize)size applyEdits:(BOOL)applyEdits progress:(void(^)(float progress))progress completion:(void(^)(UIImage *image, NSError *error))handler;
- (void)unloadImage;
- (BOOL)isEdited;
- (BOOL)isEqual:(id)object ignoreEdits:(BOOL)ignoreEdits;
- (instancetype)initWithImageURL:(NSURL *)url mimeType:(NSString *)mimeType;
@property (nonatomic, readonly) OLAssetType assetType;
@property (nonatomic, strong) NSString *imageFilePath;
@property (nonatomic, strong) NSURL *imageURL;
@property (assign, nonatomic) NSInteger extraCopies;
@property (strong, nonatomic) OLPhotoEdits *edits;
@property (strong, nonatomic) NSString *uuid;
@property (strong, nonatomic) id metadata;
@property (strong, nonatomic) PHAsset *phAsset;
@end

