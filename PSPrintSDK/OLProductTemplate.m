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

NSString *const kNotificationTemplateSyncComplete = @"co.oceanlabs.pssdk.notification.kNotificationSyncComplete";
NSString *const kNotificationKeyTemplateSyncError = @"co.oceanlabs.pssdk.notification.kNotificationKeyTemplateSyncError";

NSString *const kOLDefaultTemplateForSquarePrints = @"squares";
NSString *const kOLDefaultTemplateForSquareMiniPrints = @"squares_mini";
NSString *const kOLDefaultTemplateForMagnets = @"magnets";
NSString *const kOLDefaultTemplateForPolaroidStylePrints = @"polaroids";
NSString *const kOLDefaultTemplateForPolaroidStyleMiniPrints = @"polaroids_mini";
NSString *const kOLDefaultTemplateForPostcard = @"default_postcard";
NSString *const kOLDefaultTemplateForPsPostcard = @"ps_postcard";
NSString *const kOLDefaultTemplateFor60Postcard = @"60_postcards";
NSString *const kOLDefaultTemplateForFrames2x2 = @"frames_2x2";
NSString *const kOLDefaultTemplateForFrames3x3 = @"frames_3x3";
NSString *const kOLDefaultTemplateForFrames4x4 = @"frames_4x4";
NSString *const kOLDefaultTemplateForFrames = @"frames";
NSString *const kOLDefaultTemplateForLargeFormatA1 = @"a1_poster";
NSString *const kOLDefaultTemplateForLargeFormatA2 = @"a2_poster";
NSString *const kOLDefaultTemplateForLargeFormatA3 = @"a3_poster";
NSString *const kOLDefaultTemplateForStickersSquare = @"stickers_square";
NSString *const kOLDefaultTemplateForStickersCircle = @"stickers_circle";

static NSString *const kKeyIdentifier = @"co.oceanlabs.pssdk.kKeyIdentifier";
static NSString *const kKeyName = @"co.oceanlabs.pssdk.kKeyName";
static NSString *const kKeyQuantity = @"co.oceanlabs.pssdk.kKeyQuantity";
static NSString *const kKeyEnabled = @"co.oceanlabs.pssdk.kKeyEnabled";
static NSString *const kKeyCostsByCurrency = @"co.oceanlabs.pssdk.kKeyCostsByCurrency";

static NSMutableArray *templates;
static NSDate *lastSyncDate;
static OLProductTemplateSyncRequest *inProgressSyncRequest = nil;

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
    
    NSAssert(NO, @"Template with id '%@' not found. Please ensure you've provided a OLProductTemplates.plist file detailing your print templates or run OLProductTemplate.sync first if your templates are defined in the developer dashboard", identifier);
    return nil;
}

+ (void)saveTemplatesAsLatest:(NSArray *)templates_ {
    templates = [NSMutableArray arrayWithArray:templates_];
    lastSyncDate = [NSDate date];
    [NSKeyedArchiver archiveRootObject:@[lastSyncDate, templates] toFile:[OLProductTemplate templatesFilePath]];
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

- (NSString *)description {
    NSMutableString *supportedCurrencies = [[NSMutableString alloc] init];
    for (NSString *currency in self.costsByCurrencyCode) {
        [supportedCurrencies appendFormat:@" %@", currency];
    }
    return [NSString stringWithFormat:@"%@%@ (%@)%@ quantity: %lu",self.enabled ? @"enabled " : @"disabled ", self.identifier, self.name, supportedCurrencies, (unsigned long) self.quantityPerSheet];
}

-(NSURL *)coverImageURL{
    switch ([OLProductTemplate templateTypeWithIdentifier:self.identifier]) {
        case kOLTemplateTypeMagnets: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/magnets.png"];
        case kOLTemplateTypeMiniSquares: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/mini%20squares.png"];
        case kOLTemplateTypeSquares: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/squares.png"];
        case kOLTemplateTypeMiniPolaroids: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/petite-polaroids.png"];
        case kOLTemplateTypePolaroids: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/polaroids.png"];
        case kOLTemplateTypeFrame: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/frames.png"];
        case kOLTemplateTypeFrame2x2: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/frames.png"];
        case kOLTemplateTypeFrame3x3: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/frames.png"];
        case kOLTemplateTypeFrame4x4: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/frames.png"];
        case kOLTemplateTypePostcard: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/postcards.png"];
        case kOLTemplateTypeLargeFormatA1: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/petite-polaroids.png"];
        case kOLTemplateTypeLargeFormatA2: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/petite-polaroids.png"];
        case kOLTemplateTypeLargeFormatA3: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/petite-polaroids.png"];
            case kOLTemplateTypeStickersCircle: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/landscape-circle-stickers-notext.png"];
            case kOLTemplateTypeStickersSquare: return [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/landscape-square-stickers-notext.png"];
        default: return nil;
    }
}

-(NSArray *)productsPhotoURLs{
    switch ([OLProductTemplate templateTypeWithIdentifier:self.identifier]) {
        case kOLTemplateTypeMagnets: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/magnets1%402x.jpg"], [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/magnets2%402x.jpg"]];
        case kOLTemplateTypeMiniSquares: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/mini%20squares%402x.jpg"], [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/mini%20squares2%402x.jpg"]];
        case kOLTemplateTypeSquares: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/squares1%402x.jpg"], [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/squares2%402x.jpg"]];
        case kOLTemplateTypeMiniPolaroids: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/mini%20polaroids1%402x.jpg"], [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/mini%20polaroids2%402x.jpg"]];
        case kOLTemplateTypePolaroids: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/polaroids2%402x.jpg"], [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/polaroids3%402x.jpg"]];
        case kOLTemplateTypeFrame2x2: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/frames1%402x.jpg"]];
        case kOLTemplateTypeFrame3x3: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/frames1%402x.jpg"]];
        case kOLTemplateTypeFrame4x4: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/frames1%402x.jpg"]];
        case kOLTemplateTypeFrame: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/frames1%402x.jpg"]];
        case kOLTemplateTypePostcard: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/postcards1%402x.jpg"], [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/postcards2%402x.jpg"]];
        case kOLTemplateTypeLargeFormatA1: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/polaroids3%402x.jpg"], [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/polaroids3%402x.jpg"]];
        case kOLTemplateTypeLargeFormatA2: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/polaroids3%402x.jpg"], [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/polaroids3%402x.jpg"]];
        case kOLTemplateTypeLargeFormatA3: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/polaroids3%402x.jpg"], [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/polaroids3%402x.jpg"]];
            case kOLTemplateTypeStickersSquare: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/product_square-stickers-1%402x.jpg"], [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/product_square-stickers-2%402x.jpg"]];
            case kOLTemplateTypeStickersCircle: return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/product_rounded-stickers-1%402x.jpg"], [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/product_rounded-stickers-2%402x.jpg"]];
        default: return nil;
    }
    return @[[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/polaroids3%402x.jpg"], [NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/polaroids3%402x.jpg"]];
}


#pragma mark - NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.identifier forKey:kKeyIdentifier];
    [aCoder encodeObject:self.name forKey:kKeyName];
    [aCoder encodeInteger:self.quantityPerSheet forKey:kKeyQuantity];
    [aCoder encodeBool:self.enabled forKey:kKeyEnabled];
    [aCoder encodeObject:self.costsByCurrencyCode forKey:kKeyCostsByCurrency];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _identifier = [aDecoder decodeObjectForKey:kKeyIdentifier];
        _name = [aDecoder decodeObjectForKey:kKeyName];
        _quantityPerSheet = [aDecoder decodeIntegerForKey:kKeyQuantity];
        _enabled = [aDecoder decodeBoolForKey:kKeyEnabled];
        _costsByCurrencyCode = [aDecoder decodeObjectForKey:kKeyCostsByCurrency];
    }
    
    return self;
}

+(OLTemplateType)templateTypeWithIdentifier:(NSString *)identifier{
    if ([identifier isEqualToString:kOLDefaultTemplateForFrames2x2]){
        return kOLTemplateTypeFrame2x2;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForFrames3x3]){
        return kOLTemplateTypeFrame3x3;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForFrames4x4]){
        return kOLTemplateTypeFrame4x4;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForFrames]){
        return kOLTemplateTypeFrame;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForMagnets]){
        return kOLTemplateTypeMagnets;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForSquarePrints]){
        return kOLTemplateTypeSquares;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForSquareMiniPrints]){
        return kOLTemplateTypeMiniSquares;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForPolaroidStylePrints]){
        return kOLTemplateTypePolaroids;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForPolaroidStyleMiniPrints]){
        return kOLTemplateTypeMiniPolaroids;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForLargeFormatA1]){
        return kOLTemplateTypeLargeFormatA1;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForLargeFormatA2]){
        return kOLTemplateTypeLargeFormatA2;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForLargeFormatA3]){
        return kOLTemplateTypeLargeFormatA3;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForStickersCircle]){
        return kOLTemplateTypeStickersCircle;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForStickersSquare]){
        return kOLTemplateTypeStickersSquare;
    }
    else if ([identifier isEqualToString:kOLDefaultTemplateForPostcard] || [identifier isEqualToString:kOLDefaultTemplateForPsPostcard] || [identifier isEqualToString:kOLDefaultTemplateFor60Postcard]){
        return kOLTemplateTypePostcard;
    }
//    NSAssert(NO, @"Unrecognized template: %@", identifier);
    return -1;
}

@end
