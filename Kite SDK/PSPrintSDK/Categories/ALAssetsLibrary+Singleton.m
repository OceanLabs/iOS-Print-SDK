//
//  ALAssetsLibrary+Singleton.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 10/7/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "ALAssetsLibrary+Singleton.h"

@implementation ALAssetsLibrary (Singleton)

+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

@end
