//
//  OLProductPrintJob.h
//  Kite SDK
//
//  Created by Deon Botha on 02/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OLPrintJob.h"

@interface OLProductPrintJob : NSObject <OLPrintJob, NSCopying>

/**
 *  Creates and returns a print job
 *
 *  @param templateId     The template ID of this job
 *  @param imageFilePaths The file paths of the images to print
 *
 *  @return The print job
 */
- (instancetype)initWithTemplateId:(NSString *)templateId imageFilePaths:(NSArray<NSString *> *)imageFilePaths;

/**
 *  Creates and returns a print job
 *
 *  @param templateId The template ID of this job
 *  @param images     The images to print
 *
 *  @return The print job
 */
- (instancetype)initWithTemplateId:(NSString *)templateId images:(NSArray<UIImage *> *)images;

/**
 *  Creates and returns a print job
 *
 *  @param templateId The template ID of this job
 *  @param assets     The assets to print
 *
 *  @return The print job
 */
- (instancetype)initWithTemplateId:(NSString *)templateId OLAssets:(NSArray<OLAsset *> *)assets;

/**
 *  Creates and returns a print job
 *
 *  @param templateId  The template ID of this job
 *  @param dataSources The custom data source objects to print
 *
 *  @return The print job
 */
- (instancetype)initWithTemplateId:(NSString *)templateId dataSources:(NSArray<id<OLAssetDataSource>> *)dataSources;

@end
