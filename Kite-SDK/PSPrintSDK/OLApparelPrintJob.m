//
//  OLApparelPrintJob.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 23/6/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLApparelPrintJob.h"
#import "OLProductTemplate.h"
#import "OLAsset.h"
#import "OLAddress.h"

static NSString *const kKeyApparelProductTemplateId = @"co.oceanlabs.pssdk.kKeyApparelProductTemplateId";
static NSString *const kKeyApparelImages = @"co.oceanlabs.pssdk.kKeyApparelImages";
static NSString *const kKeyFrontAsset = @"co.oceanlabs.pssdk.kKeyFrontAsset";
static NSString *const kKeyBackAsset = @"co.oceanlabs.pssdk.kKeyBackAsset";
static NSString *const kKeyApparelAddress = @"co.oceanlabs.pssdk.kKeyApparelAddress";
static NSString *const kKeyApparelUuid = @"co.oceanlabs.pssdk.kKeyApparelUuid";
static NSString *const kKeyApparelExtraCopies = @"co.oceanlabs.pssdk.kKeyApparelExtraCopies";
static NSString *const kKeyApparelPrintJobOptions = @"co.oceanlabs.pssdk.kKeyApparelPrintJobOptions";

@interface OLApparelPrintJob ()
@property (nonatomic, strong) NSString *templateId;
@property (strong, nonatomic) NSMutableDictionary *options;
@end

@implementation OLApparelPrintJob

@synthesize address;
@synthesize uuid;
@synthesize extraCopies;

-(NSMutableDictionary *) options{
    if (!_options){
        _options = [[NSMutableDictionary alloc] init];
    }
    return _options;
}

- (void)setValue:(NSString *)value forOption:(NSString *)option{
    self.options[option] = value;
}

- (id)initWithTemplateId:(NSString *)templateId OLAssets:(NSDictionary<NSString *, OLAsset *> *)assets{
    if (self = [super init]){
#ifdef DEBUG
        for (NSString *key in [self.assets allKeys]){
            NSAssert([self.assets[key] isKindOfClass:[OLAsset class]], @"initWithTemplateId:OLAssets: requires an NSArray of OLAsset not: %@", [self.assets[key] class]);
        }
#endif
        self.uuid = [[NSUUID UUID] UUIDString];
        self.assets = assets;
        self.templateId = templateId;
    }
    
    return self;
}

#pragma mark - OLPrintJob Protocol

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    json[@"template_id"] = [OLProductTemplate templateWithId:self.templateId].identifier;
    
    NSMutableDictionary *assets = [[NSMutableDictionary alloc] init];
    for (NSString *key in [self.assets allKeys]){
        [assets setObject:[NSString stringWithFormat:@"%lld", [self.assets[key] assetId]] forKey:key];
    }
    json[@"assets"] = assets;
    json[@"options"] = self.options;
    
    return json;
}

- (NSUInteger)quantity {
    return 1;
}

- (NSDecimalNumber *)costInCurrency:(NSString *)currencyCode {
    OLProductTemplate *productTemplate = [OLProductTemplate templateWithId:self.templateId];
    NSUInteger expectedQuantity = productTemplate.quantityPerSheet;
    NSDecimalNumber *cost = [productTemplate costPerSheetInCurrencyCode:currencyCode];
    NSUInteger numOrders = (NSUInteger) floorf((self.quantity + expectedQuantity - 1)  / expectedQuantity);
    return (NSDecimalNumber *) [cost decimalNumberByMultiplyingBy:(NSDecimalNumber *) [NSDecimalNumber numberWithUnsignedInteger:numOrders]];
}

- (NSArray *)currenciesSupported {
    return [OLProductTemplate templateWithId:self.templateId].currenciesSupported;
}

- (NSString *)productName {
    return [OLProductTemplate templateWithId:self.templateId].name;
}

- (NSArray *)assetsForUploading {
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (NSString *key in [self.assets allKeys]){
        [assets addObject:self.assets[key]];
    }
    return assets;
}

- (NSUInteger) hash {
    NSUInteger val = [self.templateId hash];
    for (NSString *key in [self.assets allKeys]){
        val = 37 * val + [self.assets[key] hash];
    }
    
    val = 38 * val + self.extraCopies;
    val = 39 * val + [self.options hash];
    val = 40 * val + [self.address hash];
    
    return val;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[OLApparelPrintJob class]]) {
        return NO;
    }
    OLApparelPrintJob* printJob = (OLApparelPrintJob*)object;
    
    return [self.templateId isEqual:printJob.templateId] && [self.assets isEqualToDictionary:printJob.assets] && [self.options isEqualToDictionary:printJob.options] && ((!self.address && !printJob.address) || [self.address isEqual:printJob.address]);
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    OLApparelPrintJob *objectCopy = [[OLApparelPrintJob allocWithZone:zone] init];
    // Copy over all instance variables from self to objectCopy.
    // Use deep copies for all strong pointers, shallow copies for weak.
    objectCopy.assets = self.assets;
    objectCopy.templateId = self.templateId;
    objectCopy.options = self.options;
    objectCopy.uuid = self.uuid;
    objectCopy.extraCopies = self.extraCopies;
    return objectCopy;
}

#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.templateId forKey:kKeyApparelProductTemplateId];
    [aCoder encodeObject:self.assets forKey:kKeyApparelImages];
    [aCoder encodeObject:self.uuid forKey:kKeyApparelUuid];
    [aCoder encodeInteger:self.extraCopies forKey:kKeyApparelExtraCopies];
    [aCoder encodeObject:self.address forKey:kKeyApparelAddress];
    [aCoder encodeObject:self.options forKey:kKeyApparelPrintJobOptions];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.templateId = [aDecoder decodeObjectForKey:kKeyApparelProductTemplateId];
        self.assets = [aDecoder decodeObjectForKey:kKeyApparelImages];
        self.extraCopies = [aDecoder decodeIntegerForKey:kKeyApparelExtraCopies];
        self.uuid = [aDecoder decodeObjectForKey:kKeyApparelUuid];
        self.address = [aDecoder decodeObjectForKey:kKeyApparelAddress];
        self.options = [aDecoder decodeObjectForKey:kKeyApparelPrintJobOptions];
    }
    
    return self;
}

@end
