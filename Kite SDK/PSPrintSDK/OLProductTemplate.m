//
//  OLProductTemplate.m
//  Kite SDK
//
//  Created by Deon Botha on 18/03/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
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
static NSString *const kKeySizePx = @"co.oceanlabs.pssdk.kKeySizePx";
static NSString *const kKeyClassPhotoURL = @"co.oceanlabs.pssdk.kKeyClassPhotoURL";

static NSMutableArray *templates;
static NSDate *lastSyncDate;
static OLProductTemplateSyncRequest *inProgressSyncRequest = nil;

@interface OLKitePrintSDK (Private)

+ (void)setCacheTemplates:(BOOL)cache;
+ (BOOL)cacheTemplates;

@end

@interface OLProductTemplate ()
@property (nonatomic, strong) NSDictionary/*<NSString, NSDecimalNumber>*/ *costsByCurrencyCode;
@end

@interface OLCountry (Private)
+ (BOOL)isValidCurrencyCode:(NSString *)code;
@end

@implementation OLProductTemplate

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name sheetQuantity:(NSUInteger)quantity sheetCostsByCurrencyCode:(NSDictionary/*<String, NSDecimalNumber>*/*)costs enabled:(BOOL)enabled {
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

- (NSString *)templateType{
    if (_templateType && ![_templateType isEqualToString:@""]){
        return _templateType;
    }
    else{
        return self.name;
    }
}

- (NSDecimalNumber *)costPerSheetInCurrencyCode:(NSString *)currencyCode {
    return self.costsByCurrencyCode[currencyCode];
}

- (NSArray *)currenciesSupported {
    return self.costsByCurrencyCode.allKeys;
}

+ (void)sync {
    if (inProgressSyncRequest == nil) {
        inProgressSyncRequest = [[OLProductTemplateSyncRequest alloc] init];
        [inProgressSyncRequest sync:^(NSArray *templates_, NSError *error) {
            inProgressSyncRequest = nil;
            if (error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTemplateSyncComplete object:self userInfo:@{kNotificationKeyTemplateSyncError: error}];
            } else {
                [self saveTemplatesAsLatest:templates_];
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTemplateSyncComplete object:self userInfo:nil];
            }
        }];
    }
}

+ (BOOL)isSyncInProgress {
    return inProgressSyncRequest != nil;
}

+ (OLProductTemplate *)templateWithId:(NSString *)identifier {
    NSArray *templates = [OLProductTemplate templates];
    for (OLProductTemplate *template in templates) {
        if ([template.identifier isEqualToString:identifier]) {
            return template;
        }
    }
    
    NSAssert(NO, @"Template with id '%@' not found. Please ensure you've run OLProductTemplate.sync first if your templates are defined in the developer dashboard", identifier);
    return nil;
}

+ (void)saveTemplatesAsLatest:(NSArray *)templates_ {
    templates = [NSMutableArray arrayWithArray:templates_];
    lastSyncDate = [NSDate date];
    if ([OLKitePrintSDK cacheTemplates]){
        [NSKeyedArchiver archiveRootObject:@[lastSyncDate, templates] toFile:[OLProductTemplate templatesFilePath]];
    }
}

+ (NSDate *)lastSyncDate {
    return lastSyncDate;
}

+ (NSMutableArray *)templatesFromBundledPlist {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"OLProductTemplates" ofType:@"plist"];
    NSMutableArray *plist = [[NSMutableArray alloc] initWithContentsOfFile:path];
    
    NSMutableArray *templates = [[NSMutableArray alloc] init];
    for (id template in plist) {
        if ([template isKindOfClass:[NSDictionary class]]) {
            id templateId = template[@"OLTemplateId"];
            id templateName = template[@"OLTemplateName"];
            id sheetQuantity = template[@"OLSheetQuanity"];
            id enabled = template[@"OLEnabled"] ? template[@"OLEnabled"] : [NSNumber numberWithInt:1];
            id sheetCosts = template[@"OLSheetCosts"];
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


+ (NSArray *)templates {
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
//    else if ([identifier isEqualToString:@"PHOTOBOOK"]){
//                return kOLTemplateUIPhotobook;
//    }
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
    [aCoder encodeCGSize:self.sizePx forKey:kKeySizePx];
    [aCoder encodeObject:self.classPhotoURL forKey:kKeyClassPhotoURL];
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
        _sizePx = [aDecoder decodeCGSizeForKey:kKeySizePx];
        _classPhotoURL = [aDecoder decodeObjectForKey:kKeyClassPhotoURL];
    }
    
    return self;
}

@end