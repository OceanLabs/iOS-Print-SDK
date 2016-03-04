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
 *  Set a value for an option
 *
 *  @param value  The value to set
 *  @param option The option
 */
- (void)setValue:(NSString *)value forOption:(NSString *)option;

/**
 *  Number of items in a job (for example multiple packs of prints in a single job)
 *
 *  @return The number of items
 */
- (NSDecimalNumber *)numberOfItemsInJob;

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

/**
 *  The date the job was added to the basket.
 */
@property (strong, nonatomic) NSDate *dateAddedToBasket;

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
 *  @param frontImageAsset The image to print on the front of the postcard
 *  @param backImageAsset  The image to print on the back of the postcard
 *
 *  @return The postcard print job
 */
+ (id<OLPrintJob>)postcardWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset;

/**
 *  Creates and returns a greeting card print job
 *
 *  @param templateId              The template ID of this job
 *  @param frontImageAsset         The image to print on the front of the greeting card
 *  @param backImageAsset          The image to print on the back of the greeting card
 *  @param insideRightImageAsset   The image to print on the right side inside the greeting card
 *  @param insideLeftImageAsset    The image to print on the left side inside the greeting card
 *
 *  @return The greeting card print job
 */
+ (id<OLPrintJob>)greetingCardWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset insideRightImageAsset:(OLAsset *)insideRightImageAsset insideLeftImageAsset:(OLAsset *)insideLeftImageAsset;

/**
 *  Creates and returns a photo book print job
 *
 *  @param templateId The template ID of this job
 *  @param assets     The assets to print inside the book
 *  @param frontCover The image to print on the front cover
 *  @param backCover  The image to print on the back cover
 *
 *  @return The photo book print job
 */
+ (id<OLPrintJob>)photobookWithTemplateId:(NSString *)templateId OLAssets:(NSArray <OLAsset *> *)assets frontCoverOLAsset:(OLAsset *)frontCover backCoverOLAsset:(OLAsset *)backCover;

/**
 *  Creates and returns an apparel print job
 *
 *  @param templateId The template ID of this job
 *  @param assets     The dictionary of OLAssets. Please find a list of keys here: https://www.kite.ly/docs/?objective_c#ordering-apparel
 *
 *  @return The apparel print job
 */
+ (id<OLPrintJob>)apparelWithTemplateId:(NSString *)templateId OLAssets:(NSDictionary<NSString *, OLAsset *> *)assets;

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
