//
//  OLKiteTestHelper.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 08/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLAsset;
@class PHAsset;

@interface OLKiteTestHelper : NSObject

+ (NSArray <OLAsset *>*)urlAssets;
+ (NSArray <OLAsset *>*)imageAssets;
+ (NSData *)testImageData;
+ (PHAsset *)aPHAsset;
+ (void)mockTemplateRequest;
+ (void)undoMockTemplateRequest;
+ (void)mockTemplateServerErrorRequest;
+ (void)undoMockTemplateServerErrorRequest;
+ (void)mockCostRequest;
+ (void)undoMockCostRequest;
+ (void)mockCostServerErrorRequest;
+ (void)undoMockCostServerErrorRequest;
+ (void)mockPrintOrderRequest;
+ (void)undoMockPrintOrderRequest;
+ (void)mockPrintOrderServerErrorRequest;
+ (void)undoMockPrintOrderServerErrorRequest;
+ (void)mockPrintOrderValidationServerErrorRequest;
+ (void)undoMockPrintOrderValidationServerErrorRequest;
+ (void)mockPrintOrderValidationRejectedErrorRequest;
+ (void)undoMockPrintOrderValidationRejectedErrorRequest;

@end
