//
//  OLProductTemplate.h
//  Kite SDK
//
//  Created by Deon Botha on 18/03/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^TemplateSyncHandler)(NSError *error);

NSString *const kNotificationTemplateSyncComplete;
NSString *const kNotificationKeyTemplateSyncError;

typedef enum {
    kOLTemplateTypeMagnets,
    kOLTemplateTypeSquares,
    kOLTemplateTypeMiniSquares,
    kOLTemplateTypePolaroids,
    kOLTemplateTypeMiniPolaroids,
    kOLTemplateTypeFrame2x2,
    kOLTemplateTypeFrame3x3,
    kOLTemplateTypeFrame4x4,
    kOLTemplateTypeFrame,
    kOLTemplateTypeLargeFormatA1,
    kOLTemplateTypeLargeFormatA2,
    kOLTemplateTypeLargeFormatA3,
    kOLTemplateTypePostcard    
} OLTemplateType;

NSString *const kOLDefaultTemplateForSquarePrints;
NSString *const kOLDefaultTemplateForSquareMiniPrints;
NSString *const kOLDefaultTemplateForMagnets;
NSString *const kOLDefaultTemplateForPolaroidStylePrints;
NSString *const kOLDefaultTemplateForPolaroidStyleMiniPrints;
NSString *const kOLDefaultTemplateForPostcard;
NSString *const kOLDefaultTemplateForPsPostcard;
NSString *const kOLDefaultTemplateFor60Postcard;
NSString *const kOLDefaultTemplateForFrames2x2;
NSString *const kOLDefaultTemplateForFrames3x3;
NSString *const kOLDefaultTemplateForFrames4x4;
NSString *const kOLDefaultTemplateForFrames;

NSString *const kOLDefaultTemplateForLargeFormatA1;
NSString *const kOLDefaultTemplateForLargeFormatA2;
NSString *const kOLDefaultTemplateForLargeFormatA3;


@class OLProductTemplateSyncRequest;

@interface OLProductTemplate : NSObject <NSCoding>
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign, readonly) NSUInteger quantityPerSheet;
@property (nonatomic, assign, readonly) BOOL enabled;
@property (nonatomic, readonly) NSArray *currenciesSupported;

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name sheetQuantity:(NSUInteger)quantity sheetCostsByCurrencyCode:(NSDictionary/*<String, NSDecimalNumber>*/*)costs enabled:(BOOL)enabled;
- (NSDecimalNumber *)costPerSheetInCurrencyCode:(NSString *)currencyCode;
- (NSURL *)coverImageURL;
-(NSArray *)productsPhotoURLs;
+(OLTemplateType)templateTypeWithIdentifier:(NSString *)identifier;

+ (void)sync;
+ (BOOL)isSyncInProgress;
+ (OLProductTemplate *)templateWithId:(NSString *)identifier;
+ (NSArray *)templates;
+ (NSDate *)lastSyncDate;

@end
