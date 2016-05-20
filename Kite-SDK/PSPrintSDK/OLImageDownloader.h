//
//  OLImageDownloader.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 17/05/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLImageDownloader : NSObject

+ (instancetype)sharedInstance;
- (NSURLSessionDownloadTask *)downloadImageAtURL:(NSURL *)url withCompletionHandler:(void(^)(UIImage *image, NSError *error))handler;
- (NSURLSessionDownloadTask *)downloadImageAtURL:(NSURL *)url progress:(void(^)(NSInteger progress, NSInteger total))progressHandler withCompletionHandler:(void(^)(UIImage *image, NSError *error))handler;
- (BOOL)cachedDataExistForURL:(NSURL *)url;

@end
