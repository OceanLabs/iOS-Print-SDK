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
- (void)downloadImageAtURL:(NSURL *)url withCompletionHandler:(void(^)(UIImage *image, NSError *error))handler;
- (void)downloadImageAtURL:(NSURL *)url progress:(void(^)(NSInteger progress, NSInteger total))progressHandler withCompletionHandler:(void(^)(UIImage *image, NSError *error))handler;

@end
