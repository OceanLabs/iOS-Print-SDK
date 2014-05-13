//
//  OLProductPrintJob.h
//  Kite SDK
//
//  Created by Deon Botha on 02/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OLPrintJob.h"

@interface OLProductPrintJob : NSObject <OLPrintJob>

- (id)initWithTemplateId:(NSString *)templateId imageFilePaths:(NSArray/*<NSString>*/ *)imageFilePaths;
- (id)initWithTemplateId:(NSString *)templateId images:(NSArray/*<UIImage>*/ *)images;
- (id)initWithTemplateId:(NSString *)templateId OLAssets:(NSArray/*<OLAssets>*/ *)assets;
- (id)initWithTemplateId:(NSString *)templateId dataSources:(NSArray/*<id<OLAssetDataSource> >*/ *)dataSources;

@end
