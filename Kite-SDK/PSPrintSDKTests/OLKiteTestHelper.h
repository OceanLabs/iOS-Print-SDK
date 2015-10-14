//
//  OLKiteTestHelper.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 08/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLAsset;
@class OLPrintPhoto;
@class PHAsset;

@interface OLKiteTestHelper : NSObject

+ (NSArray <OLAsset *>*)urlAssets;
+ (NSArray <OLAsset *>*)imageAssets;
+ (NSData *)testImageData;
+ (PHAsset *)aPHAsset;
+ (OLPrintPhoto *)aPrintPhoto;

@end
