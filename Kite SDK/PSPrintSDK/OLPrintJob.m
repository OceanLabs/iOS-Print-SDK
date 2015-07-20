//
//  PrintStudio.m
//  Kite SDK
//
//  Created by Deon Botha on 02/01/2014.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLPrintJob.h"
#import "OLPostcardPrintJob.h"
#import "OLProductPrintJob.h"
#import "OLAsset.h"

@implementation OLPrintJob

+ (id<OLPrintJob>)postcardWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset message:(NSString *)message address:(OLAddress *)address{
    return [[OLPostcardPrintJob alloc] initWithTemplateId:templateId frontImageOLAsset:frontImageAsset message:message address:address];
}

+ (id<OLPrintJob>)postcardWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset {
    return [[OLPostcardPrintJob alloc] initWithTemplateId:templateId frontImageOLAsset:frontImageAsset backImageOLAsset:backImageAsset];
}

+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId imageFilePaths:(NSArray/*<NSString>*/ *)imageFilePaths {
    return [[OLProductPrintJob alloc] initWithTemplateId:templateId imageFilePaths:imageFilePaths];
}

+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId images:(NSArray/*<UIImage>*/ *)images {
    return [[OLProductPrintJob alloc] initWithTemplateId:templateId images:images];
}

+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId OLAssets:(NSArray/*<OLAssets>*/ *)assets {
    return [[OLProductPrintJob alloc] initWithTemplateId:templateId OLAssets:assets];
}

+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId dataSources:(NSArray/*<id<OLAssetDataSource> >*/ *)dataSources {
    return [[OLProductPrintJob alloc] initWithTemplateId:templateId dataSources:dataSources];
}

@end