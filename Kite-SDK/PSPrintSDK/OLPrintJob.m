//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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