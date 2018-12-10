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
#import "NSMutableArray+OLUserSelectedAssetsUtils.h"

@import Photobook;

typedef enum {
    kOLAssetTypeCorrupt,
    kOLAssetTypePHAsset,
    kOLAssetTypeRemoteImageURL,
    kOLAssetTypeImageFilePath,
    kOLAssetTypeImageData,
    kOLAssetTypeDataSource,
} OLAssetType;

@interface OLAsset (Private)

@property (nonatomic, strong) id<OLAssetDataSource> dataSource;

- (instancetype)initWithImageURL:(NSURL *)url mimeType:(NSString *)mimeType size:(CGSize)size;
+ (void)cancelAllImageOperations;
- (BOOL)isEdited;
- (BOOL)isEqual:(id)object ignoreEdits:(BOOL)ignoreEdits;
- (void)dataLengthWithCompletionHandler:(GetDataLengthHandler)handler;
- (void)dataWithCompletionHandler:(GetDataHandler)handler;
- (void)getImageURLWithProgress:(void(^)(float progress, float total))progressHandler completionHandler:(void(^)(NSURL *url, NSError *error))handler;
- (void)imageWithSize:(CGSize)size applyEdits:(BOOL)applyEdits progress:(void(^)(float progress))progress completion:(void(^)(UIImage *image, NSError *error))handler;
- (void)unloadImage;
- (PhotobookAsset *)photobookAsset;
+ (NSArray<PhotobookAsset *> *)photobookAssetsFromAssets:(NSArray <OLAsset *>*)assets;
+ (NSMutableArray<OLAsset *> *)userSelectedAssets;
@property (assign, nonatomic) BOOL corrupt;
@property (assign, nonatomic) NSInteger extraCopies;
@property (nonatomic, readonly) OLAssetType assetType;
@property (nonatomic, strong) NSString *imageFilePath;
@property (nonatomic, strong) NSURL *imageURL;
@property (strong, nonatomic) NSString *uuid;
@property (strong, nonatomic) OLPhotoEdits *edits;
@property (strong, nonatomic) PHAsset *phAsset;
@property (strong, nonatomic) id metadata;
@property (nonatomic, strong) NSData *imageData;
@end

