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

#import "OLProductTemplate.h"
#import "OLProductTemplateSyncRequest.h"
#import "OLCountry.h"
#import "OLKitePrintSDK.h"

static NSString *const kKeyIdentifier = @"co.oceanlabs.pssdk.kKeyIdentifier";
static NSString *const kKeyName = @"co.oceanlabs.pssdk.kKeyName";
static NSString *const kKeyQuantity = @"co.oceanlabs.pssdk.kKeyQuantity";
static NSString *const kKeyEnabled = @"co.oceanlabs.pssdk.kKeyEnabled";
static NSString *const kKeyCostsByCurrency = @"co.oceanlabs.pssdk.kKeyCostsByCurrency";
static NSString *const kKeyCoverPhotoURL = @"co.oceanlabs.pssdk.kKeyCoverPhotoURL";
static NSString *const kKeyProductPhotographyURLs = @"co.oceanlabs.pssdk.kKeyProductPhotographyURLs";
static NSString *const kKeyTemplateClass = @"co.oceanlabs.pssdk.kKeyTemplateClass";
static NSString *const kKeyTemplateType = @"co.oceanlabs.pssdk.kKeyTemplateType";
static NSString *const kKeyTemplateUI = @"co.oceanlabs.pssdk.kKeyTemplateUI";
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
static NSString *const kKeyUpsellOffers = @"co.oceanlabs.pssdk.kKeyUpsellOffers";

static NSMutableArray *templates;
static NSDate *lastSyncDate;
static OLProductTemplateSyncRequest *inProgressSyncRequest = nil;

@interface OLKitePrintSDK (Private)

+ (void)setCacheTemplates:(BOOL)cache;
+ (BOOL)cacheTemplates;

@end

@interface OLProductTemplate ()
@property (nonatomic, strong) NSDictionary<NSString *, NSDecimalNumber *> *costsByCurrencyCode;
@property (nonatomic, assign, readwrite) NSUInteger quantityPerSheet;
@property (strong, nonatomic) NSArray *_Nullable supportedOptions;
@property (strong, nonatomic, readwrite) NSArray <OLProductTemplateOption *>*_Nullable options;
@end

@interface OLCountry (Private)
+ (BOOL)isValidCurrencyCode:(NSString *)code;
@end

@implementation OLProductTemplate

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

+ (NSString *)templatesFilePath {
    NSArray * urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString *documentDirPath = [(NSURL *)[urls objectAtIndex:0] path];
    return [documentDirPath stringByAppendingPathComponent:@"co.oceanlabs.pssdk.Templates"];
}

- (void)setSupportedOptions:(NSArray *_Nullable)supportedOptions{
    _supportedOptions = supportedOptions;
    NSMutableArray *options = [[NSMutableArray alloc] init];
    for (NSDictionary *option in supportedOptions){
        if ([option isKindOfClass:[NSDictionary class]]){
            [options addObject:[[OLProductTemplateOption alloc] initWithDictionary:option]];
        }
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
    if (self.templateUI == kOLTemplateUIPhotobook){
        return _quantityPerSheet % 2 == 0 ? _quantityPerSheet : _quantityPerSheet + 1;
    }
    return _quantityPerSheet;
}

- (NSDecimalNumber *)costPerSheetInCurrencyCode:(NSString *)currencyCode {
    return self.costsByCurrencyCode[currencyCode];
}

- (NSDecimalNumber *)shippingCostForCountry:(OLCountry *)country{
    NSString *currencyCode = [self currencyForCurrentLocale];
    
    if ([[self.shippingCosts allKeys] containsObject:country.codeAlpha3]){
        NSString *cost = self.shippingCosts[country.codeAlpha3][currencyCode];
        return cost ? [NSDecimalNumber decimalNumberWithString:cost] : nil;
    }
    else if (country.isInEurope){
        NSString *cost = self.shippingCosts[@"europe"][currencyCode];
        return cost ? [NSDecimalNumber decimalNumberWithString:cost] : nil;
    }
    else{
        NSString *cost = self.shippingCosts[@"rest_of_world"][currencyCode];
        return cost? [NSDecimalNumber decimalNumberWithString:cost] : nil;
    }
}

- (NSString *)currencyForCurrentLocale {
    NSString *code = [OLCountry countryForCurrentLocale].currencyCode;
    if ([self.currenciesSupported containsObject:code]) {
        return code;
    }
    
    if ([self.currenciesSupported containsObject:@"USD"]) {
        return @"USD";
    }
    
    if ([self.currenciesSupported containsObject:@"GBP"]) {
        return @"GBP";
    }
    
    if ([self.currenciesSupported containsObject:@"EUR"]) {
        return @"EUR";
    }
    
    NSAssert(self.currenciesSupported.count > 0, @"This template has no costs associated with it.");
    code = self.currenciesSupported[0]; // return the first currency supported if the user hasn't specified one explicitly
    return code;
}

- (NSArray *)currenciesSupported {
    return self.costsByCurrencyCode.allKeys;
}

+ (void)sync {
    [OLProductTemplate syncWithCompletionHandler:NULL];
}

+ (void)syncWithCompletionHandler:(void(^_Nullable)(NSArray <OLProductTemplate *>* _Nullable templates, NSError * _Nullable error))handler{
    if (inProgressSyncRequest == nil) {
        inProgressSyncRequest = [[OLProductTemplateSyncRequest alloc] init];
        [inProgressSyncRequest sync:^(NSArray *templates_, NSError *error) {
            inProgressSyncRequest = nil;
            if (error) {
                if (handler){
                    handler(nil, error);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTemplateSyncComplete object:self userInfo:@{kNotificationKeyTemplateSyncError: error}];
            } else {
                [self saveTemplatesAsLatest:templates_];
                if (handler){
                    handler(templates_, nil);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTemplateSyncComplete object:self userInfo:nil];
            }
        }];
    }
}

+ (BOOL)isSyncInProgress {
    return inProgressSyncRequest != nil;
}

+ (OLProductTemplate *_Nullable)templateWithId:(NSString *_Nonnull)identifier {
    NSArray *templates = [OLProductTemplate templates];
    for (OLProductTemplate *productTemplate in templates) {
        if ([productTemplate.identifier isEqualToString:identifier]) {
            return productTemplate;
        }
    }
    
    NSLog(@"Template with id '%@' not found. Please ensure you've run OLProductTemplate.sync first if your templates are defined in the developer dashboard", identifier);
    return nil;
}

+ (void)saveTemplatesAsLatest:(NSArray *)templates_ {
    templates = [NSMutableArray arrayWithArray:templates_];
    lastSyncDate = [NSDate date];
    if ([OLKitePrintSDK cacheTemplates]){
        [NSKeyedArchiver archiveRootObject:@[lastSyncDate, templates] toFile:[OLProductTemplate templatesFilePath]];
    }
}

+ (NSDate *_Nullable)lastSyncDate {
    return lastSyncDate;
}

+ (NSMutableArray *)templatesFromBundledPlist {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"OLProductTemplates" ofType:@"plist"];
    NSMutableArray *plist = [[NSMutableArray alloc] initWithContentsOfFile:path];
    
    NSMutableArray *templates = [[NSMutableArray alloc] init];
    for (id productTemplate in plist) {
        if ([productTemplate isKindOfClass:[NSDictionary class]]) {
            id templateId = productTemplate[@"OLTemplateId"];
            id templateName = productTemplate[@"OLTemplateName"];
            id sheetQuantity = productTemplate[@"OLSheetQuanity"];
            id enabled = productTemplate[@"OLEnabled"] ? productTemplate[@"OLEnabled"] : [NSNumber numberWithInt:1];
            id sheetCosts = productTemplate[@"OLSheetCosts"];
            if ([templateId isKindOfClass:[NSString class]] && [templateName isKindOfClass:[NSString class]]
                && [sheetQuantity isKindOfClass:[NSNumber class]] && [enabled isKindOfClass:[NSNumber class]]
                && [sheetCosts isKindOfClass:[NSDictionary class]]) {
                
                NSMutableDictionary/*<String, NSDecimalNumber>*/ *costs = [[NSMutableDictionary alloc] init];
                for (id key in sheetCosts) {
                    id val = sheetCosts[key];
                    if ([key isKindOfClass:[NSString class]] && [val isKindOfClass:[NSString class]]) {
                        if ([OLCountry isValidCurrencyCode:key]) {
                            NSDecimalNumber *cost = [NSDecimalNumber decimalNumberWithString:val];
                            costs[key] = cost;
                        }
                    }
                }
                
                NSAssert(costs.count > 0, @"OLProductTemplates.plist %@ (%@) does not contain any cost information", templateId, templateName);
                if (costs.count > 0) {
                    [templates addObject:[[OLProductTemplate alloc] initWithIdentifier:templateId name:templateName sheetQuantity:[sheetQuantity unsignedIntegerValue] sheetCostsByCurrencyCode:costs enabled:[enabled boolValue]]];
                }
            } else {
                NSAssert(NO, @"Bad template format in OLProductTemplates.plist");
            }
        }
    }
    return templates;
}


+ (NSArray *_Nullable)templates {
    if (!templates) {
        NSArray *components = [NSKeyedUnarchiver unarchiveObjectWithFile:[OLProductTemplate templatesFilePath]];
        if (!components) {
            lastSyncDate = nil;
            templates = [self templatesFromBundledPlist];
        } else {
            lastSyncDate = components[0];
            templates = components[1];
        }
    }
    
    return templates;
}

+ (void) deleteCachedTemplates{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error;
    [manager removeItemAtPath:[OLProductTemplate templatesFilePath] error:&error];
}

+ (void) resetTemplates{
    templates = nil;
}

+(OLTemplateUI)templateUIWithIdentifier:(NSString *)identifier{
    if ([identifier isEqualToString:@"RECTANGLE"]){
        return kOLTemplateUIRectagle;
    }
    else if ([identifier isEqualToString:@"FRAME"]){
        return kOLTemplateUIFrame;
    }
    else if ([identifier isEqualToString:@"POSTER"]){
        return kOLTemplateUIPoster;
    }
    else if ([identifier isEqualToString:@"CIRCLE"]){
        return kOLTemplateUICircle;
    }
    else if ([identifier isEqualToString:@"PHONE_CASE"]){
        return kOLTemplateUICase;
    }
//    else if ([identifier isEqualToString:@"POSTCARD"]){
//        return kOLTemplateUIPostcard;
//    }
    else if ([identifier isEqualToString:@"PHOTOBOOK"]){
        return kOLTemplateUIPhotobook;
    }
    else if ([identifier isEqualToString:@"NONCUSTOMIZABLE"]){
        return kOLTemplateUINonCustomizable;
    }
    return kOLTemplateUINA;
}

+ (NSString *)templateUIStringWithTemplateClass:(OLTemplateUI)templateClass{
    switch (templateClass) {
        case kOLTemplateUICase:
            return @"Case";
            break;
        case kOLTemplateUICircle:
            return @"Circle";
            break;
        case kOLTemplateUIFrame:
            return @"Frame";
            break;
        case kOLTemplateUINA:
            return @"NA Class";
            break;
        case kOLTemplateUIPoster:
            return @"Poster";
            break;
        case kOLTemplateUIRectagle:
            return @"Rectangle";
            break;
        case kOLTemplateUINonCustomizable:
            return @"Non-Customizable";
            break;
        case kOLTemplateUIPostcard:
            return @"Postcard";
            break;
        case kOLTemplateUIPhotobook:
            return @"Photobook";
            break;
            
        default:
            return @"";
            break;
    }
}

- (NSString *)description {
    NSMutableString *supportedCurrencies = [[NSMutableString alloc] init];
    for (NSString *currency in self.costsByCurrencyCode) {
        [supportedCurrencies appendFormat:@" %@", currency];
    }
    return [NSString stringWithFormat:@"%@%@ (%@)%@ quantity: %lu",self.enabled ? @"enabled " : @"disabled ", self.identifier, self.name, supportedCurrencies, (unsigned long) self.quantityPerSheet];
}

#pragma mark - NSCoding protocol methods
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.identifier forKey:kKeyIdentifier];
    [aCoder encodeObject:self.name forKey:kKeyName];
    [aCoder encodeInteger:self.quantityPerSheet forKey:kKeyQuantity];
    [aCoder encodeBool:self.enabled forKey:kKeyEnabled];
    [aCoder encodeObject:self.costsByCurrencyCode forKey:kKeyCostsByCurrency];
    [aCoder encodeObject:self.coverPhotoURL forKey:kKeyCoverPhotoURL];
    [aCoder encodeObject:self.productPhotographyURLs forKey:kKeyProductPhotographyURLs];
    [aCoder encodeObject:self.labelColor forKey:kKeyLabelColor];
    [aCoder encodeObject:[NSNumber numberWithInt:self.templateUI] forKey:kKeyTemplateUI];
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
    [aCoder encodeObject:self.shippingCosts forKey:kKeyShippingCosts];
    [aCoder encodeInteger:self.gridCountX forKey:kKeyGridCountX];
    [aCoder encodeInteger:self.gridCountY forKey:kKeyGridCountY];
    [aCoder encodeObject:self.supportedOptions forKey:kKeySupportedOptions];
    [aCoder encodeObject:self.upsellOffers forKey:kKeyUpsellOffers];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _identifier = [aDecoder decodeObjectForKey:kKeyIdentifier];
        _name = [aDecoder decodeObjectForKey:kKeyName];
        _quantityPerSheet = [aDecoder decodeIntegerForKey:kKeyQuantity];
        _enabled = [aDecoder decodeBoolForKey:kKeyEnabled];
        _costsByCurrencyCode = [aDecoder decodeObjectForKey:kKeyCostsByCurrency];
        _coverPhotoURL = [aDecoder decodeObjectForKey:kKeyCoverPhotoURL];
        _productPhotographyURLs = [aDecoder decodeObjectForKey:kKeyProductPhotographyURLs];
        _templateUI = [[aDecoder decodeObjectForKey:kKeyTemplateUI] intValue];
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
        _shippingCosts = [aDecoder decodeObjectForKey:kKeyShippingCosts];
        _gridCountX = [aDecoder decodeIntegerForKey:kKeyGridCountX];
        _gridCountY = [aDecoder decodeIntegerForKey:kKeyGridCountY];
        self.supportedOptions = [aDecoder decodeObjectForKey:kKeySupportedOptions];
        self.upsellOffers = [aDecoder decodeObjectForKey:kKeyUpsellOffers];
    }
    
    return self;
}

@end