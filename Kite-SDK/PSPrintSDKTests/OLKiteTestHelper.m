//
//  OLKiteTestHelper.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 08/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import "OLKiteTestHelper.h"
#import "OLKitePrintSDK.h"

@import Photos;

@implementation OLKiteTestHelper

#pragma mark Image helper methods

+ (NSArray <OLAsset *>*)urlAssets{
    NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]]];
    return assets;
}

+ (NSData *)testImageData{
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLKiteTestHelper class]] pathForResource:@"1" ofType:@"jpg"]];
    return data;
}

+ (NSArray <OLAsset *>*)imageAssets{
    
    return @[[OLAsset assetWithImageAsJPEG:[UIImage imageWithData:[OLKiteTestHelper testImageData]]]];
}

//+ (PHAsset *)aPHAsset{
//    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
//    
//    return [fetchResult objectAtIndex:fetchResult.count-1];
//}

+ (OLPrintPhoto *)aPrintPhoto{
    OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
    printPhoto.asset = (OLAsset *)[OLKiteTestHelper imageAssets].firstObject;
    return printPhoto;
}

@end
