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
//  to place orders with any competit]ors to Kite Tech Ltd, all orders MUST go through the
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

#import "OLProductTemplate.h"
#import "OLProductTemplateSyncRequest.h"
#import "OLKitePrintSDK.h"
#import "OLKiteABTesting.h"

static NSString *const kKeyIdentifier = @"co.oceanlabs.pssdk.kKeyIdentifier";
static NSString *const kKeyName = @"co.oceanlabs.pssdk.kKeyName";
static NSString *const kKeyQuantity = @"co.oceanlabs.pssdk.kKeyQuantity";
static NSString *const kKeyEnabled = @"co.oceanlabs.pssdk.kKeyEnabled";
static NSString *const kKeyCostsByCurrency = @"co.oceanlabs.pssdk.kKeyCostsByCurrency";
static NSString *const kKeyCoverPhotosDict = @"co.oceanlabs.pssdk.kKeyCoverPhotosDict";
static NSString *const kKeyProductPhotographyURLs = @"co.oceanlabs.pssdk.kKeyProductPhotographyURLs";
static NSString *const kKeyTemplateClass = @"co.oceanlabs.pssdk.kKeyTemplateClass";
static NSString *const kKeyTemplateType = @"co.oceanlabs.pssdk.kKeyTemplateType";
static NSString *const kKeyTemplateUI = @"co.oceanlabs.pssdk.kKeyTemplateUI";
static NSString *const kKeyBlendMode = @"co.oceanlabs.pssdk.kKeyBlendMode";
static NSString *const kKeyLabelColor = @"co.oceanlabs.pssdk.kKeyLabelColor";
static NSString *const kKeySizeCm = @"co.oceanlabs.pssdk.kKeySizeCm";
static NSString *const kKeySizeInches = @"co.oceanlabs.pssdk.kKeySizeInches";
static NSString *const kKeyProductCode = @"co.oceanlabs.pssdk.kKeyProductCode";
static NSString *const kKeyImageBleed = @"co.oceanlabs.pssdk.kKeyImageBleed";
static NSString *const kKeyImageBorder = @"co.oceanlabs.pssdk.kKeyImageBorder";
static NSString *const kKeyMaskImageURL = @"co.oceanlabs.pssdk.kKeymaskImageURL";
static NSString *const kKeyProductBackgroundImageURL = @"co.oceanlabs.pssdk.kKeyProductBackgroundImageURL";
static NSString *const kKeyProductHighlightsImageURL = @"co.oceanlabs.pssdk.kKeyProductHighlightsImageURL";
static NSString *const kKeySizePx = @"co.oceanlabs.pssdk.kKeySizePx";
static NSString *const kKeyClassPhotoURL = @"co.oceanlabs.pssdk.kKeyClassPhotoURL";
static NSString *const kkeyDescription = @"co.oceanlabs.pssdk.kkeyDescription";
static NSString *const kkeyDescriptionMarkdown = @"co.oceanlabs.pssdk.kkeyDescriptionMarkdown";
static NSString *const kKeyShippingCosts = @"co.oceanlabs.pssdk.kKeyShippingCosts";
static NSString *const kKeyGridCountX = @"co.oceanlabs.pssdk.kKeyGridCountX";
static NSString *const kKeyGridCountY = @"co.oceanlabs.pssdk.kKeyGridCountY";
static NSString *const kKeySupportedOptions = @"co.oceanlabs.pssdk.kKeySupportedOptions";
static NSString *const kKeyShortDescription = @"co.oceanlabs.pssdk.kKeyShortDescription";
static NSString *const kKeyCollectionName = @"co.oceanlabs.pssdk.kKeyCollectionName";
static NSString *const kKeyCollectionId = @"co.oceanlabs.pssdk.kKeyCollectionId";
static NSString *const kKeyRepresentationAssets = @"co.oceanlabs.pssdk.kKeyRepresentationAssets";
static NSString *const kKeyLogo = @"co.oceanlabs.pssdk.kKeyLogo";
static NSString *const kKeyFulfilmentItems = @"co.oceanlabs.pssdk.kKeyFulfilmentItems";
static NSString *const kKeySupportsTextOnBorder = @"co.oceanlabs.pssdk.kKeySupportsTextOnBorder";

static NSMutableArray *templates;
static NSDate *lastSyncDate;
static OLProductTemplateSyncRequest *inProgressSyncRequest = nil;
static BOOL partial = NO;

@interface OLProductTemplate ()
@property (nonatomic, strong) NSDictionary<NSString *, NSDecimalNumber *> *costsByCurrencyCode;
@property (nonatomic, assign, readwrite) NSUInteger quantityPerSheet;
@property (strong, nonatomic) NSArray *_Nullable supportedOptions;
@end

@implementation OLProductTemplate

- (UIEdgeInsets)imageBorder{
    //If these numbers are > 1 then they represent points based on a 320 point width.
    if (_imageBorder.top >= 1 && _imageBorder.left >= 1 && _imageBorder.bottom >= 1 && _imageBorder.right >= 1){
        return UIEdgeInsetsMake(_imageBorder.top/320.0, _imageBorder.left/320.0, _imageBorder.bottom/320.0, _imageBorder.right/320.0);
    }
    else{
        return _imageBorder;
    }
}

- (NSURL *)coverPhotoURL{
    NSString *testResult = [OLKiteABTesting sharedInstance].coverPhotoId;
    NSURL *coverPhotoURL;
    if (testResult){
        coverPhotoURL = [NSURL URLWithString:self.coverPhotosDict[testResult]];
    }
    if (!coverPhotoURL && self.coverPhotosDict.allKeys.count > 0){
        coverPhotoURL = [NSURL URLWithString:self.coverPhotosDict[self.coverPhotosDict.allKeys.firstObject]];
    }
    
    return coverPhotoURL;
}

- (instancetype _Nonnull)initWithIdentifier:(NSString *_Nonnull)identifier name:(NSString *_Nonnull)name sheetQuantity:(NSUInteger)quantity sheetCostsByCurrencyCode:(NSDictionary<NSString *, NSDecimalNumber *> *_Nullable)costs enabled:(BOOL)enabled {
    if (self = [super init]) {
        _identifier = identifier;
        _name = name;
        _quantityPerSheet = quantity;
        self.costsByCurrencyCode = costs;
        _enabled = enabled;
    }
    
    return self;
}

- (void)setSupportedOptions:(NSArray *_Nullable)supportedOptions{
    _supportedOptions = supportedOptions;
    NSMutableArray<OLProductTemplateOption *> *options = [[NSMutableArray alloc] init];
    for (NSDictionary *option in supportedOptions){
        if ([option isKindOfClass:[NSDictionary class]]){
            [options addObject:[[OLProductTemplateOption alloc] initWithDictionary:option]];
        }
    }
    
    if ([options.lastObject.code isEqualToString:@"garment_size"]){
        OLProductTemplateOption *sizeOption = options.lastObject;
        [options removeObject:sizeOption];
        [options insertObject:sizeOption atIndex:0];
    }
    
    self.options = options;
}

- (NSString *)templateType{
    if (_templateType && ![_templateType isEqualToString:@""]){
        return _templateType;
    }
    else{
        return self.name;
    }
}

- (NSUInteger)quantityPerSheet{
    if (self.templateUI == OLTemplateUIPhotobook){
        return _quantityPerSheet % 2 == 0 ? _quantityPerSheet : _quantityPerSheet + 1;
    }
    return _quantityPerSheet;
}

- (NSDecimalNumber *)costPerSheetInCurrencyCode:(NSString *)currencyCode {
    return self.costsByCurrencyCode[currencyCode];
}

- (NSArray *)currenciesSupported {
    return self.costsByCurrencyCode.allKeys;
}

+ (void)sync {
    [OLProductTemplate syncWithCompletionHandler:NULL];
}

+ (void)syncWithCompletionHandler:(void(^_Nullable)(NSArray <OLProductTemplate *>* _Nullable templates, NSError * _Nullable error))handler {
    [OLProductTemplate syncTemplateId:nil withCompletionHandler:handler];
}

+ (void)syncTemplateId:(NSString *)templateId withCompletionHandler:(void(^_Nullable)(NSArray <OLProductTemplate *>* _Nullable templates, NSError * _Nullable error))handler {
    if (inProgressSyncRequest == nil) {
        inProgressSyncRequest = [[OLProductTemplateSyncRequest alloc] init];
        if (templateId) {
            inProgressSyncRequest.templateId = templateId;
        }
        [inProgressSyncRequest sync:^(NSArray *templates_, NSError *error) {
            partial = [inProgressSyncRequest isInProgress];
            if (!partial){
                inProgressSyncRequest = nil;
            }
            if (error) {
                if (handler){
                    handler(nil, error);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTemplateSyncPartialComplete object:self userInfo:@{kNotificationKeyTemplateSyncError: error}];
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTemplateSyncComplete object:self userInfo:@{kNotificationKeyTemplateSyncError: error}];
            } else {
                [self saveTemplatesAsLatest:templates_];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTemplateSyncPartialComplete object:self userInfo:nil];
                if (!partial){
                    if (handler){
                        handler(templates_, nil);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTemplateSyncComplete object:self userInfo:nil];
                }
            }
        }];
    }
}

+ (BOOL)isSyncInProgress {
    return inProgressSyncRequest != nil || partial;
}

+ (void)cancelSyncInProgress{
    [inProgressSyncRequest cancel];
}

+ (OLProductTemplate *_Nullable)templateWithId:(NSString *_Nonnull)identifier {
    NSArray *templates = [OLProductTemplate templates];
    for (OLProductTemplate *productTemplate in templates) {
        if ([productTemplate.identifier isEqualToString:identifier]) {
            return productTemplate;
        }
    }
    
#ifdef OL_VERBOSE
    NSLog(@"Template with id '%@' not found. Please ensure you've run OLProductTemplate.sync first if your templates are defined in the developer dashboard", identifier);
#endif
    return nil;
}

+ (void)saveTemplatesAsLatest:(NSArray *)templates_ {
    templates = [NSMutableArray arrayWithArray:templates_];
    lastSyncDate = [NSDate date];
}

+ (NSDate *_Nullable)lastSyncDate {
    return lastSyncDate;
}

+ (NSArray *_Nullable)templates {
    return templates;
}

+ (void) resetTemplates{
    templates = nil;
}

+(OLTemplateUI)templateUIWithIdentifier:(NSString *)identifier{
    if ([identifier isEqualToString:@"RECTANGLE"]){
        return OLTemplateUIRectangle;
    }
    else if ([identifier isEqualToString:@"FRAME"]){
        return OLTemplateUIFrame;
    }
    else if ([identifier isEqualToString:@"POSTER"]){
        return OLTemplateUIPoster;
    }
    else if ([identifier isEqualToString:@"CIRCLE"]){
        return OLTemplateUICircle;
    }
    else if ([identifier isEqualToString:@"PHONE_CASE"]){
        return OLTemplateUICase;
    }
    else if ([identifier isEqualToString:@"PHOTOBOOK"] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        return OLTemplateUIPhotobook;
    }
    else if ([identifier isEqualToString:@"NONCUSTOMIZABLE"]){
        return OLTemplateUINonCustomizable;
    }
    else if ([identifier isEqualToString:@"DOUBLESIDED"]){
        return OLTemplateUIDoubleSided;
    }
    else if ([identifier isEqualToString:@"CALENDAR"]){
        return OLTemplateUICalendar;
    }
    else if ([identifier isEqualToString:@"APPAREL"]){
        return OLTemplateUIApparel;
    }
#ifndef OL_KITE_LITE
    else if ([identifier isEqualToString:@"MUG"]){
        return OLTemplateUIMug;
    }
#endif
    return OLTemplateUINA;
}

#pragma mark - NSCoding protocol methods
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.identifier forKey:kKeyIdentifier];
    [aCoder encodeObject:self.name forKey:kKeyName];
    [aCoder encodeInteger:self.quantityPerSheet forKey:kKeyQuantity];
    [aCoder encodeBool:self.enabled forKey:kKeyEnabled];
    [aCoder encodeObject:self.costsByCurrencyCode forKey:kKeyCostsByCurrency];
    [aCoder encodeObject:self.coverPhotoURL forKey:kKeyCoverPhotosDict];
    [aCoder encodeObject:self.productPhotographyURLs forKey:kKeyProductPhotographyURLs];
    [aCoder encodeObject:self.labelColor forKey:kKeyLabelColor];
    [aCoder encodeObject:[NSNumber numberWithInt:self.templateUI] forKey:kKeyTemplateUI];
    [aCoder encodeObject:[NSNumber numberWithInt:self.blendMode] forKey:kKeyBlendMode];
    [aCoder encodeObject:self.templateClass forKey:kKeyTemplateClass];
    [aCoder encodeObject:self.templateType forKey:kKeyTemplateType];
    [aCoder encodeCGSize:self.sizeCm forKey:kKeySizeCm];
    [aCoder encodeCGSize:self.sizeInches forKey:kKeySizeInches];
    [aCoder encodeObject:self.productCode forKey:kKeyProductCode];
    [aCoder encodeUIEdgeInsets:self.imageBleed forKey:kKeyImageBleed];
    [aCoder encodeUIEdgeInsets:self.imageBorder forKey:kKeyImageBorder];
    [aCoder encodeObject:self.maskImageURL forKey:kKeyMaskImageURL];
    [aCoder encodeObject:self.productBackgroundImageURL forKey:kKeyProductBackgroundImageURL];
    [aCoder encodeObject:self.productHighlightsImageURL forKey:kKeyProductHighlightsImageURL];
    [aCoder encodeCGSize:self.sizePx forKey:kKeySizePx];
    [aCoder encodeObject:self.productDescription forKey:kkeyDescription];
    [aCoder encodeObject:self.productDescriptionMarkdown forKey:kkeyDescriptionMarkdown];
    [aCoder encodeObject:self.classPhotoURL forKey:kKeyClassPhotoURL];
    [aCoder encodeInteger:self.gridCountX forKey:kKeyGridCountX];
    [aCoder encodeInteger:self.gridCountY forKey:kKeyGridCountY];
    [aCoder encodeObject:self.supportedOptions forKey:kKeySupportedOptions];
    [aCoder encodeObject:self.shortDescription forKey:kKeyShortDescription];
    [aCoder encodeObject:self.collectionId forKey:kKeyCollectionId];
    [aCoder encodeObject:self.collectionName forKey:kKeyCollectionName];
    [aCoder encodeObject:self.representationAssets forKey:kKeyRepresentationAssets];
    [aCoder encodeObject:self.logo forKey:kKeyLogo];
    [aCoder encodeObject:self.fulfilmentItems forKey:kKeyFulfilmentItems];
    [aCoder encodeBool:self.supportsTextOnBorder forKey:kKeySupportsTextOnBorder];
    [aCoder encodeObject:self.shippingClasses forKey:@"shippingClasses"];
    [aCoder encodeObject:self.countryMapping forKey:@"countryMapping"];
}

- (NSString *)description{
    return [NSString stringWithFormat:@"%@ %@", self.identifier, [super description]];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _identifier = [aDecoder decodeObjectForKey:kKeyIdentifier];
        _name = [aDecoder decodeObjectForKey:kKeyName];
        _quantityPerSheet = [aDecoder decodeIntegerForKey:kKeyQuantity];
        _enabled = [aDecoder decodeBoolForKey:kKeyEnabled];
        _costsByCurrencyCode = [aDecoder decodeObjectForKey:kKeyCostsByCurrency];
        _coverPhotosDict = [aDecoder decodeObjectForKey:kKeyCoverPhotosDict];
        _productPhotographyURLs = [aDecoder decodeObjectForKey:kKeyProductPhotographyURLs];
        _templateUI = [[aDecoder decodeObjectForKey:kKeyTemplateUI] intValue];
        _blendMode = [[aDecoder decodeObjectForKey:kKeyBlendMode] intValue];
        _templateClass = [aDecoder decodeObjectForKey:kKeyTemplateClass];
        _templateType = [aDecoder decodeObjectForKey:kKeyTemplateType];
        _labelColor = [aDecoder decodeObjectForKey:kKeyLabelColor];
        _sizeCm = [aDecoder decodeCGSizeForKey:kKeySizeCm];
        _sizeInches = [aDecoder decodeCGSizeForKey:kKeySizeInches];
        _productCode = [aDecoder decodeObjectForKey:kKeyProductCode];
        _imageBleed = [aDecoder decodeUIEdgeInsetsForKey:kKeyImageBleed];
        _imageBorder = [aDecoder decodeUIEdgeInsetsForKey:kKeyImageBorder];
        _maskImageURL = [aDecoder decodeObjectForKey:kKeyMaskImageURL];
        _productBackgroundImageURL = [aDecoder decodeObjectForKey:kKeyProductBackgroundImageURL];
        _productHighlightsImageURL = [aDecoder decodeObjectForKey:kKeyProductHighlightsImageURL];
        _sizePx = [aDecoder decodeCGSizeForKey:kKeySizePx];
        _classPhotoURL = [aDecoder decodeObjectForKey:kKeyClassPhotoURL];
        _productDescription = [aDecoder decodeObjectForKey:kkeyDescription];
        _productDescriptionMarkdown = [aDecoder decodeObjectForKey:kkeyDescriptionMarkdown];
        _gridCountX = [aDecoder decodeIntegerForKey:kKeyGridCountX];
        _gridCountY = [aDecoder decodeIntegerForKey:kKeyGridCountY];
        self.supportedOptions = [aDecoder decodeObjectForKey:kKeySupportedOptions];
        self.shortDescription = [aDecoder decodeObjectForKey:kKeyShortDescription];
        self.collectionName = [aDecoder decodeObjectForKey:kKeyCollectionName];
        self.collectionId = [aDecoder decodeObjectForKey:kKeyCollectionId];
        self.representationAssets = [aDecoder decodeObjectForKey:kKeyRepresentationAssets];
        self.logo = [aDecoder decodeObjectForKey:kKeyLogo];
        self.fulfilmentItems = [aDecoder decodeObjectForKey:kKeyFulfilmentItems];
        self.supportsTextOnBorder = [aDecoder decodeBoolForKey:kKeySupportsTextOnBorder];
        self.shippingClasses = [aDecoder decodeObjectForKey:@"shippingClasses"];
        self.countryMapping = [aDecoder decodeObjectForKey:@"countryMapping"];
    }
    
    return self;
}

@synthesize availableShippingMethods;
@synthesize countryToRegionMapping;

- (NSString *)templateId {
    return self.identifier;
}

@end
