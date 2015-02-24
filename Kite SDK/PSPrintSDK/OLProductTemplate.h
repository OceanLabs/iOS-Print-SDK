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
    kOLTemplateClassNA,
    kOLTemplateClassSquare,
    kOLTemplateClassCircle,
    kOLTemplateClassFrame,
    kOLTemplateClassPoster,
    kOLTemplateClassPolaroid,
    kOLTemplateClassCase
}OLTemplateClass;

@class OLProductTemplateSyncRequest;

@interface OLProductTemplate : NSObject <NSCoding>
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign, readonly) NSUInteger quantityPerSheet;
@property (nonatomic, assign, readonly) BOOL enabled;
@property (nonatomic, readonly) NSArray *currenciesSupported;
@property (strong, nonatomic) NSURL *coverPhotoURL;
@property (strong, nonatomic) NSArray *productPhotographyURLs;
@property (assign, nonatomic) OLTemplateClass templateClass;
@property (strong, nonatomic) UIColor *labelColor;
@property (assign, nonatomic) CGSize sizeCm;
@property (assign, nonatomic) CGSize sizeInches;
@property (strong, nonatomic) NSString *productCode;

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name sheetQuantity:(NSUInteger)quantity sheetCostsByCurrencyCode:(NSDictionary/*<String, NSDecimalNumber>*/*)costs enabled:(BOOL)enabled;
- (NSDecimalNumber *)costPerSheetInCurrencyCode:(NSString *)currencyCode;
+(OLTemplateClass)templateClassWithIdentifier:(NSString *)identifier;

+ (void)sync;
+ (BOOL)isSyncInProgress;
+ (OLProductTemplate *)templateWithId:(NSString *)identifier;
+ (NSArray *)templates;
+ (NSDate *)lastSyncDate;
+ (void) resetTemplates;

@end
