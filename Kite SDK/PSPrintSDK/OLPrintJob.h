//
//  OLPrintJob.h
//  Kite SDK
//
//  Created by Deon Botha on 30/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>
@class OLAddress;
@class OLAsset;

@protocol OLPrintJob <NSObject, NSCoding>

- (NSDictionary *)jsonRepresentation;

@property (nonatomic, readonly) NSArray/*<OLAsset>*/ *assetsForUploading;

@property (nonatomic, readonly) NSString *productName;

/**
 * The number of assets that make up this PrintJob. This is typically the number of user selected photos that will get printed as a result of submitting the job. 
 */
@property (nonatomic, readonly) NSUInteger quantity;
@property (nonatomic, readonly) NSString *templateId;
@property (nonatomic, readonly) NSArray *currenciesSupported;
- (NSDecimalNumber *)costInCurrency:(NSString *)currencyCode;

@end

@interface OLPrintJob : NSObject

+ (id<OLPrintJob>)postcardWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset message:(NSString *)message address:(OLAddress *)address;
+ (id<OLPrintJob>)postcardWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset;



+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId imageFilePaths:(NSArray/*<NSString>*/ *)imageFilePaths;
+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId images:(NSArray/*<UIImage>*/ *)images;
+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId OLAssets:(NSArray/*<OLAssets>*/ *)assets;
+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId dataSources:(NSArray/*<id<OLAssetDataSource> >*/ *)dataSources;

@end
