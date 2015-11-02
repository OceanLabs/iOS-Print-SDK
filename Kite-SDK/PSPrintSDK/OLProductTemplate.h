//
//  OLProductTemplate.h
//  Kite SDK
//
//  Created by Deon Botha on 18/03/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OLProductTemplateOption.h"

typedef void (^TemplateSyncHandler)(NSError *_Nullable error);

extern NSString *_Nonnull const kNotificationTemplateSyncComplete;
extern NSString *_Nonnull const kNotificationKeyTemplateSyncError;

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
@class OLCountry;

@interface OLProductTemplate : NSObject <NSCoding>
@property (nonatomic, copy, readonly) NSString *_Nonnull identifier;
@property (nonatomic, copy, readonly) NSString *_Nonnull name;
@property (nonatomic, assign, readonly) NSUInteger quantityPerSheet;
@property (nonatomic, assign, readonly) BOOL enabled;
@property (nonatomic, readonly) NSArray *_Nonnull currenciesSupported;
@property (strong, nonatomic) NSURL *_Nullable coverPhotoURL;
@property (strong, nonatomic) NSArray *_Nullable productPhotographyURLs;
@property (assign, nonatomic) OLTemplateUI templateUI;
@property (strong, nonatomic) NSString *_Nullable templateClass;
@property (strong, nonatomic) NSString *_Nullable templateType;
@property (strong, nonatomic) UIColor *_Nullable labelColor;
@property (assign, nonatomic) CGSize sizeCm;
@property (assign, nonatomic) CGSize sizeInches;
@property (strong, nonatomic) NSString *_Nullable productCode;
@property (assign, nonatomic) UIEdgeInsets imageBleed;
@property (assign, nonatomic) UIEdgeInsets imageBorder;
@property (strong, nonatomic) NSURL *_Nullable maskImageURL;
@property (assign, nonatomic) CGSize sizePx;
@property (strong, nonatomic) NSURL *_Nullable classPhotoURL;
@property (strong, nonatomic) NSString *_Nullable productDescription;
@property (strong, nonatomic) NSDictionary *_Nullable shippingCosts;
@property (assign, nonatomic) NSInteger gridCountX;
@property (assign, nonatomic) NSInteger gridCountY;
@property (strong, nonatomic, readonly) NSArray <OLProductTemplateOption *>*_Nullable options;

- (instancetype _Nonnull)initWithIdentifier:(NSString *_Nonnull)identifier name:(NSString *_Nonnull)name sheetQuantity:(NSUInteger)quantity sheetCostsByCurrencyCode:(NSDictionary<NSString *, NSDecimalNumber *> *_Nullable)costs enabled:(BOOL)enabled;
- (NSDecimalNumber *_Nullable)costPerSheetInCurrencyCode:(NSString *_Nonnull)currencyCode;
- (NSDecimalNumber *_Nullable)shippingCostForCountry:(OLCountry *_Nonnull)country;
- (NSString *_Nonnull)currencyForCurrentLocale;
- (void)setSupportedOptions:(NSArray *_Nullable)options;
+ (OLTemplateUI)templateUIWithIdentifier:(NSString *_Nonnull)identifier;
+ (NSString *_Nonnull)templateUIStringWithTemplateClass:(OLTemplateUI)templateClass;

+ (void)sync;
+ (void)syncWithCompletionHandler:(void(^_Nullable)(NSArray <OLProductTemplate *>* _Nullable templates, NSError * _Nullable error))handler;
+ (BOOL)isSyncInProgress;
+ (OLProductTemplate *_Nullable)templateWithId:(NSString *_Nonnull)identifier;
+ (NSArray *_Nullable)templates;
+ (NSDate *_Nullable)lastSyncDate;
+ (void) resetTemplates;
+ (void) deleteCachedTemplates;

@end