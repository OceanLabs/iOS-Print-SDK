//
//  ALAssetsLibrary+Singleton.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 10/7/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface ALAssetsLibrary (Singleton)

+ (ALAssetsLibrary *)defaultAssetsLibrary;

@end
