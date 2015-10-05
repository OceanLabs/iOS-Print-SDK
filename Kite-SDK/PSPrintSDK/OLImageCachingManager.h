//
//  OLImageCachingManager.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 9/4/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@import Photos;

@interface OLImageCachingManager : NSObject

@property (strong, nonatomic) PHCachingImageManager *photosCachingManager;

+ (instancetype)sharedInstance;

@end
