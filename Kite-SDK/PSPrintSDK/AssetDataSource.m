//
//  CTAssetDataSource.m
//  KITAssetsPickerDemo
//
//  Created by Konstadinos Karayannis on 04/11/15.
//  Copyright © 2015 Kite.ly All rights reserved.
//

#import "AssetDataSource.h"
#import "OLImageDownloader.h"

@implementation AssetDataSource

- (void)thumbnailImageWithCompletionHandler:(void (^)(UIImage *))handler{
    [self imageWithSize:CGSizeMake(100, 100) applyEdits:YES progress:NULL completion:^(UIImage *image, NSError *error){
        if (image){
            handler(image);
        }
    }];
}

- (CGFloat)pixelWidth{
    return 100;
}
- (CGFloat)pixelHeight{
    return 100;
}

- (BOOL)isEqual:(id)object{
    OLAsset *selfAsset = [OLAsset assetWithURL:self.imageURL];
    OLAsset *objectAsset = [OLAsset assetWithURL:[object imageURL]];
    return [selfAsset isEqual:objectAsset];
}

+ (AssetDataSource *)assetWithURL:(NSURL *)url {
    NSAssert([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"], @"bad url scheme (%@), only http & https are supported", url.scheme);
    
    NSString *urlStr = url.absoluteString;
    if ([urlStr hasSuffix:@"jpg"] || [urlStr hasSuffix:@"jpeg"]) {
        return [[AssetDataSource alloc] initWithImageURL:url mimeType:kOLMimeTypeJPEG];
    } else if ([urlStr hasSuffix:@"png"]) {
        return [[AssetDataSource alloc] initWithImageURL:url mimeType:kOLMimeTypePNG];
    } else if ([urlStr hasSuffix:@"tiff"] || [urlStr hasSuffix:@"tif"]) {
        return [[AssetDataSource alloc] initWithImageURL:url mimeType:kOLMimeTypeTIFF];
    } else if ([urlStr hasSuffix:@"pdf"]){
        return [[AssetDataSource alloc] initWithImageURL:url mimeType:kOLMimeTypePDF];
    } else {
        // Worst case scenario just assume it's a JPEG.
        return [[AssetDataSource alloc] initWithImageURL:url mimeType:kOLMimeTypeJPEG];
    }
    
    return nil;
}

@end
