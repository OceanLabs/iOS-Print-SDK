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
@protocol OLAssetDataSource;

/**
 *  Protocol to be implemented by print job classes. A print job is defined by a single template ID, which means can only refer to a single product.
 *  Print jobs are part of the OLPrintOrder object which get submitted for printing.
 */
@protocol OLPrintJob <NSObject, NSCoding, NSCopying>

/**
 *  The json representation of the print job.
 *
 *  @return The json dictionary
 */
- (NSDictionary *)jsonRepresentation;

/**
 *  An array of the OLAssets that need to be uploaded
 */
@property (nonatomic, readonly) NSArray<OLAsset *> *assetsForUploading;


/**
 *  The name of the product of this print job
 */
@property (nonatomic, readonly) NSString *productName;

/**
 * The number of assets that make up this PrintJob. This is typically the number of user selected photos that will get printed as a result of submitting the job. 
 */
@property (nonatomic, readonly) NSUInteger quantity;

/**
 *  The template ID of this print job
 */
@property (nonatomic, readonly) NSString *templateId;

/**
 *  An array of the currencies that this print job supports
 */
@property (nonatomic, readonly) NSArray *currenciesSupported;

/**
 *  The shipping address of this print job (overrides the print order shipping address)
 */
@property (nonatomic, strong) OLAddress *address;

/**
 *  A unique indentifier for this job
 */
@property (nonatomic, strong) NSString *uuid;

/**
 *  The number of extra copies that user wants of this print job
 */
@property (assign, nonatomic) NSInteger extraCopies;

@end

/**
 *  Abstract class that provides static methods that instantiate the appropriate print job objects.
 */
@interface OLPrintJob : NSObject

/**
 *  Creates and returns a postcard print job
 *
 *  @param templateId      The template ID of this job
 *  @param frontImageAsset The image to print on the front of the postcard
 *  @param message         The message on the back of the postcard
 *  @param address         The shipping address of the postcard
 *
 *  @return The postcard print job
 */
+ (id<OLPrintJob>)postcardWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset message:(NSString *)message address:(OLAddress *)address;

/**
 *  Creates and returns a postcard print job
 *
 *  @param templateId      The template ID of this job
 *  @param frontImageAsset he image to print on the front of the postcard
 *  @param backImageAsset  he image to print on the back of the postcard
 *
 *  @return The postcard print job
 */
+ (id<OLPrintJob>)postcardWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset;


/**
 *  Creates and returns a print job
 *
 *  @param templateId     The template ID of this job
 *  @param imageFilePaths The file paths of the images to print
 *
 *  @return The print job
 */
+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId imageFilePaths:(NSArray<NSString *> *)imageFilePaths;

/**
 *  Creates and returns a print job
 *
 *  @param templateId The template ID of this job
 *  @param images     The images to print
 *
 *  @return The print job
 */
+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId images:(NSArray<UIImage *> *)images;

/**
 *  Creates and returns a print job
 *
 *  @param templateId The template ID of this job
 *  @param assets     The assets to print
 *
 *  @return The print job
 */
+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId OLAssets:(NSArray<OLAsset *> *)assets;

/**
 *  Creates and returns a print job
 *
 *  @param templateId  The template ID of this job
 *  @param dataSources The custom data source objects to print
 *
 *  @return The print job
 */
+ (id<OLPrintJob>)printJobWithTemplateId:(NSString *)templateId dataSources:(NSArray<id<OLAssetDataSource>> *)dataSources;

@end
