//
//  OLProductTemplate.h
//  Kite SDK
//
//  Created by Deon Botha on 18/03/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^TemplateSyncHandler)(NSError *error);

extern NSString *const kNotificationTemplateSyncComplete;
extern NSString *const kNotificationKeyTemplateSyncError;

typedef enum {
    kOLTemplateUINA,
    kOLTemplateUIRectagle,
    kOLTemplateUICircle,
    kOLTemplateUIFrame,
    kOLTemplateUIPoster,
    kOLTemplateUICase,
    kOLTemplateUIPostcard,
    kOLTemplateUIPhotobook
}OLTemplateUI;

@class OLProductTemplateSyncRequest;

@interface OLProductTemplate : NSObject <NSCoding>
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign, readonly) NSUInteger quantityPerSheet;
@property (nonatomic, assign, readonly) BOOL enabled;
@property (nonatomic, readonly) NSArray *currenciesSupported;
@property (strong, nonatomic) NSURL *coverPhotoURL;
@property (strong, nonatomic) NSArray *productPhotographyURLs;
@property (assign, nonatomic) OLTemplateUI templateUI;
@property (strong, nonatomic) NSString *templateClass;
@property (strong, nonatomic) NSString *templateType;
@property (strong, nonatomic) UIColor *labelColor;
@property (assign, nonatomic) CGSize sizeCm;
@property (assign, nonatomic) CGSize sizeInches;
@property (strong, nonatomic) NSString *productCode;
@property (assign, nonatomic) UIEdgeInsets imageBleed;
@property (assign, nonatomic) UIEdgeInsets imageBorder;
@property (strong, nonatomic) NSURL *maskImageURL;
@property (assign, nonatomic) CGSize sizePx;
@property (strong, nonatomic) NSURL *classPhotoURL;

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name sheetQuantity:(NSUInteger)quantity sheetCostsByCurrencyCode:(NSDictionary/*<String, NSDecimalNumber>*/*)costs enabled:(BOOL)enabled;
- (NSDecimalNumber *)costPerSheetInCurrencyCode:(NSString *)currencyCode;
+ (OLTemplateUI)templateUIWithIdentifier:(NSString *)identifier;
+ (NSString *)templateUIStringWithTemplateClass:(OLTemplateUI)templateClass;

+ (void)sync;
+ (BOOL)isSyncInProgress;
+ (OLProductTemplate *)templateWithId:(NSString *)identifier;
+ (NSArray *)templates;
+ (NSDate *)lastSyncDate;
+ (void) resetTemplates;
+ (void) deleteCachedTemplates;

@end