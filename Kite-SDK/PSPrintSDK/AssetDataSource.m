//
//  CTAssetDataSource.m
//  KITAssetsPickerDemo
//
//  Created by Konstadinos Karayannis on 04/11/15.
//  Copyright © 2015 Kite.ly All rights reserved.
//

#import "AssetDataSource.h"
#import <SDWebImage/SDWebImageManager.h>

@implementation AssetDataSource

- (void)dataLengthWithCompletionHandler:(void (^)(long long, NSError *))handler{
    [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:self.url] options:0 progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(UIImageJPEGRepresentation(image, 0.7).length, error);
        });
    }];
}

- (void)dataWithCompletionHandler:(void (^)(NSData *, NSError *))handler{
    [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:self.url] options:0 progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(UIImageJPEGRepresentation(image, 0.7), error);
        });
    }];
}

- (NSString *)mimeType{
    return @"image/jpeg";
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_url forKey:@"ly.kite.sdkdemo.asset.url"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _url = [aDecoder decodeObjectForKey:@"ly.kite.sdkdemo.asset.url"];
    }
    
    return self;
}

- (void)thumbnailImageWithCompletionHandler:(void (^)(UIImage *))handler{
    [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:self.url] options:0 progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
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
