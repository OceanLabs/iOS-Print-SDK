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
#import "OLPhotobookPrintJob.h"
#import "OLApparelPrintJob.h"
#import "OLGreetingCardPrintJob.h"

@implementation OLPrintJob

+ (id<OLPrintJob>)postcardWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset message:(NSString *)message address:(OLAddress *)address{
    return [[OLPostcardPrintJob alloc] initWithTemplateId:templateId frontImageOLAsset:frontImageAsset message:message address:address];
}

+ (id<OLPrintJob>)postcardWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset {
    return [[OLPostcardPrintJob alloc] initWithTemplateId:templateId frontImageOLAsset:frontImageAsset backImageOLAsset:backImageAsset];
}

+ (id<OLPrintJob>)greetingCardWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset insideRightImageAsset:(OLAsset *)insideRightImageAsset insideLeftImageAsset:(OLAsset *)insideLeftImageAsset{
    return [[OLGreetingCardPrintJob alloc] initWithTemplateId:templateId frontImageOLAsset:frontImageAsset backImageOLAsset:backImageAsset insideRightImageAsset:insideRightImageAsset insideLeftImageAsset:insideLeftImageAsset];
}

+ (id<OLPrintJob>)photobookWithTemplateId:(NSString *)templateId OLAssets:(NSArray <OLAsset *> *)assets frontCoverOLAsset:(OLAsset *)frontCover backCoverOLAsset:(OLAsset *)backCover{
    OLPhotobookPrintJob *job = [[OLPhotobookPrintJob alloc] initWithTemplateId:templateId OLAssets:assets];
    job.frontCover = frontCover;
    job.backCover = backCover;
    
    return job;
}

+ (id<OLPrintJob>)apparelWithTemplateId:(NSString *)templateId OLAssets:(NSDictionary<NSString *, OLAsset *> *)assets{
    OLApparelPrintJob *job = [[OLApparelPrintJob alloc] initWithTemplateId:templateId OLAssets:assets];
    return job;
}

+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId imageFilePaths:(NSArray<NSString *> *)imageFilePaths {
    return [[OLProductPrintJob alloc] initWithTemplateId:templateId imageFilePaths:imageFilePaths];
}

+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId images:(NSArray<UIImage *> *)images {
    return [[OLProductPrintJob alloc] initWithTemplateId:templateId images:images];
}

+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId OLAssets:(NSArray<OLAsset *> *)assets {
    return [[OLProductPrintJob alloc] initWithTemplateId:templateId OLAssets:assets];
}

+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId dataSources:(NSArray<id<OLAssetDataSource>> *)dataSources {
    return [[OLProductPrintJob alloc] initWithTemplateId:templateId dataSources:dataSources];
}

-(instancetype)init{
    NSAssert(NO, @"Not meant to be instantiated. Take a look at OLProductPrintJob instead");
    return nil;
}

@end