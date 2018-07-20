//
//  OLKiteTestHelper.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 08/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import "OLKiteTestHelper.h"
#import "OLKitePrintSDK.h"
#import "OLSwizzler.h"
#import "OLBaseRequest+Mock.h"

@import Photos;

@implementation OLKiteTestHelper

#pragma mark Image helper methods

+ (NSArray <OLAsset *>*)urlAssets{
    NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"] size:CGSizeMake(1824,1216)],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"] size: CGSizeMake(612, 612)],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"] size: CGSizeMake(843, 960)],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"] size: CGSizeMake(1034, 1034)],
                        ];
    return assets;
}

+ (NSData *)testImageData{
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLKiteTestHelper class]] pathForResource:@"1" ofType:@"jpg"]];
    return data;
}

+ (NSArray <OLAsset *>*)imageAssets{
    
    return @[[OLAsset assetWithImageAsJPEG:[UIImage imageWithData:[OLKiteTestHelper testImageData]]]];
}

+ (PHAsset *)aPHAsset{
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    
    return [fetchResult objectAtIndex:fetchResult.count-1];
}

+ (void)mockTemplateRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(startWithCompletionHandler:), @selector(mockTemplateStartWithCompletionHandler:));
}

+ (void)undoMockTemplateRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(mockTemplateStartWithCompletionHandler:), @selector(startWithCompletionHandler:));
}

+ (void)mockTemplateServerErrorRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(startWithCompletionHandler:), @selector(mockTemplateServerErrorWithCompletionHandler:));
}

+ (void)undoMockTemplateServerErrorRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(mockTemplateServerErrorWithCompletionHandler:), @selector(startWithCompletionHandler:));
}

+ (void)mockCostRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(mockCostRequestWithCompletionHandler:), @selector(startWithCompletionHandler:));
}

+ (void)undoMockCostRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(startWithCompletionHandler:), @selector(mockCostRequestWithCompletionHandler:));
}

+ (void)mockCostServerErrorRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(mockCostServerErrorWithCompletionHandler:), @selector(startWithCompletionHandler:));
}

+ (void)undoMockCostServerErrorRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(startWithCompletionHandler:), @selector(mockCostServerErrorWithCompletionHandler:));
}

+ (void)mockPrintOrderRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(mockPrintOrderRequestWithCompletionHandler:), @selector(startWithCompletionHandler:));
}

+ (void)undoMockPrintOrderRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(startWithCompletionHandler:), @selector(mockPrintOrderRequestWithCompletionHandler:));
}

+ (void)mockPrintOrderServerErrorRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(mockPrintOrderServerErrorRequestWithCompletionHandler:), @selector(startWithCompletionHandler:));
}

+ (void)undoMockPrintOrderServerErrorRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(startWithCompletionHandler:), @selector(mockPrintOrderServerErrorRequestWithCompletionHandler:));
}

+ (void)mockPrintOrderValidationServerErrorRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(mockPrintOrderValidationServerErrorRequestWithCompletionHandler:), @selector(startWithCompletionHandler:));
}

+ (void)undoMockPrintOrderValidationServerErrorRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(startWithCompletionHandler:), @selector(mockPrintOrderValidationServerErrorRequestWithCompletionHandler:));
}

+ (void)mockPrintOrderValidationRejectedErrorRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(mockPrintOrderValidationRejectedErrorRequestWithCompletionHandler:), @selector(startWithCompletionHandler:));
}

+ (void)undoMockPrintOrderValidationRejectedErrorRequest{
    OLSwizzleInstanceMethods([OLBaseRequest class], @selector(startWithCompletionHandler:), @selector(mockPrintOrderValidationRejectedErrorRequestWithCompletionHandler:));
}

@end
