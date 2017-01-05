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
    [[OLImageDownloader sharedInstance] downloadImageAtURL:self.imageURL withCompletionHandler:^(UIImage *image, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(image);
        });
    }];
}

- (CGFloat)pixelWidth{
    return 100;
}
- (CGFloat)pixelHeight{
    return 100;
}


@end
