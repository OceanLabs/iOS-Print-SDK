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

@end
