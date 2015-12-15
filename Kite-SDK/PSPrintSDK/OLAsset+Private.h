//
//  OLAsset+Private.h
//  Kite SDK
//
//  Created by Deon Botha on 01/02/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
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
@property (nonatomic, strong) NSURL *imageURL; // if this is set no image data is going to be uploaded, rather we will just pass the url to the server and it can fetch the image when printing
@end

