//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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
#import "OLProductTemplateOption.h"
#import "OLProductRepresentation.h"
#import "OLFulfilmentItem.h"
#import "OLShippingClass.h"

@import Photobook;

typedef void (^TemplateSyncHandler)(NSError *_Nullable error);

extern NSString *_Nonnull const kNotificationTemplateSyncComplete;
extern NSString *_Nonnull const kNotificationTemplateSyncPartialComplete;
extern NSString *_Nonnull const kNotificationKeyTemplateSyncError;

typedef NS_ENUM(NSInteger, OLTemplateUI) {
    OLTemplateUINA,
    OLTemplateUIRectangle,
    OLTemplateUICircle,
    OLTemplateUIFrame,
    OLTemplateUIPoster,
    OLTemplateUICase,
    OLTemplateUIPostcard,
    OLTemplateUIPhotobook,
    OLTemplateUINonCustomizable,
    OLTemplateUIApparel,
    OLTemplateUIDoubleSided,
    OLTemplateUICalendar,
    OLTemplateUIMug,
};

typedef NS_ENUM(NSInteger, OLImageBlendMode) {
    OLImageBlendModeNormal,
    OLImageBlendModeMultiply,
};

@class OLProductTemplateSyncRequest;
@class OLCountry;

@interface OLProductTemplate : NSObject <NSCoding, Template>
@property (nonatomic, copy) NSString *_Nonnull identifier;
@property (nonatomic, copy, readonly) NSString *_Nonnull name;
@property (nonatomic, assign, readonly) NSUInteger quantityPerSheet;
@property (nonatomic, assign, readonly) BOOL enabled;
@property (nonatomic, readonly) NSArray *_Nonnull currenciesSupported;
@property (nonatomic, strong) NSDictionary<NSString *, NSDecimalNumber *> *_Nullable originalCostsByCurrencyCode;
@property (strong, nonatomic, readonly) NSURL *_Nullable coverPhotoURL;
@property (strong, nonatomic) NSDictionary<NSString *, NSString *> *_Nullable coverPhotosDict;
@property (strong, nonatomic) NSArray <NSString *>*_Nullable productPhotographyURLs;
@property (assign, nonatomic) OLTemplateUI templateUI;
@property (assign, nonatomic) OLTemplateUI blendMode;
@property (strong, nonatomic) NSString *_Nullable templateClass;
@property (strong, nonatomic) NSString *_Nullable templateType;
@property (strong, nonatomic) NSString *_Nullable shortDescription;
@property (strong, nonatomic) UIColor *_Nullable labelColor;
@property (assign, nonatomic) CGSize sizeCm;
@property (assign, nonatomic) CGSize sizeInches;
@property (strong, nonatomic) NSString *_Nullable productCode;
@property (assign, nonatomic) UIEdgeInsets imageBleed;
@property (assign, nonatomic) UIEdgeInsets imageBorder;
@property (strong, nonatomic) NSURL *_Nullable maskImageURL;
@property (strong, nonatomic) NSURL *_Nullable productBackgroundImageURL;
@property (strong, nonatomic) NSURL *_Nullable productHighlightsImageURL;
@property (assign, nonatomic) CGSize sizePx;
@property (strong, nonatomic) NSURL *_Nullable classPhotoURL;
@property (strong, nonatomic) NSString *_Nullable productDescription;
@property (strong, nonatomic) NSString *_Nullable productDescriptionMarkdown;
@property (assign, nonatomic) NSInteger gridCountX;
@property (assign, nonatomic) NSInteger gridCountY;
@property (strong, nonatomic) NSArray <OLProductTemplateOption *>*_Nullable options;
@property (strong, nonatomic) OLProductRepresentation *_Nullable productRepresentation;
@property (assign, nonatomic) BOOL printInStore;
@property (strong, nonatomic) NSString *_Nullable collectionId;
@property (strong, nonatomic) NSString *_Nullable collectionName;
@property (strong, nonatomic) NSArray <NSURL *>*_Nullable representationAssets;
@property (strong, nonatomic) NSURL *_Nullable logo;
@property (strong, nonatomic) NSMutableArray<OLFulfilmentItem *> *_Nullable fulfilmentItems;
@property (assign, nonatomic) BOOL supportsTextOnBorder;
@property (strong, nonatomic) NSDictionary<NSString *, NSArray<OLShippingClass *> *> * _Nullable shippingClasses;
@property (strong, nonatomic) NSDictionary * _Nullable countryMapping;

- (instancetype _Nonnull)initWithIdentifier:(NSString *_Nonnull)identifier name:(NSString *_Nonnull)name sheetQuantity:(NSUInteger)quantity sheetCostsByCurrencyCode:(NSDictionary<NSString *, NSDecimalNumber *> *_Nullable)costs enabled:(BOOL)enabled;
- (NSDecimalNumber *_Nullable)costPerSheetInCurrencyCode:(NSString *_Nonnull)currencyCode;
- (void)setSupportedOptions:(NSArray *_Nullable)options;
+ (OLTemplateUI)templateUIWithIdentifier:(NSString *_Nonnull)identifier;

+ (void)sync;
+ (void)syncWithCompletionHandler:(void(^_Nullable)(NSArray <OLProductTemplate *>* _Nullable templates, NSError * _Nullable error))handler;
+ (void)syncTemplateId:(NSString *_Nullable)templateId withCompletionHandler:(void(^_Nullable)(NSArray <OLProductTemplate *>* _Nullable templates, NSError * _Nullable error))handler;
+ (BOOL)isSyncInProgress;
+ (void)cancelSyncInProgress;
+ (OLProductTemplate *_Nullable)templateWithId:(NSString *_Nonnull)identifier;
+ (NSArray *_Nullable)templates;
+ (NSDate *_Nullable)lastSyncDate;
+ (void) resetTemplates;

@end
