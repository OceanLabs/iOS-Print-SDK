//
//  OLImageCachingManager.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 9/4/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLImageCachingManager.h"

@implementation OLImageCachingManager

-(PHCachingImageManager *) photosCachingManager{
    if (!_photosCachingManager){
        _photosCachingManager = [[PHCachingImageManager alloc] init];
    }
    return _photosCachingManager;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static OLImageCachingManager * sharedInstance;
    dispatch_once(&once, ^ { sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

@end
