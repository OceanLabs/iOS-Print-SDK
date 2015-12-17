//
//  OLProductPrintJob.m
//  Kite SDK
//
//  Created by Deon Botha on 02/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLProductPrintJob.h"
#import "OLAsset.h"
#import "OLAddress.h"
#import "OLCountry.h"
#import "OLProductTemplate.h"

static NSString *const kKeyProductTemplateId = @"co.oceanlabs.pssdk.kKeyProductTemplateId";
static NSString *const kKeyImages = @"co.oceanlabs.pssdk.kKeyImages";
static NSString *const kKeyUUID = @"co.oceanlabs.pssdk.kKeyUUID";
static NSString *const kKeyExtraCopies = @"co.oceanlabs.pssdk.kKeyExtraCopies";
static NSString *const kKeyProductPringJobAddress = @"co.oceanlabs.pssdk.kKeyProductPringJobAddress";
static NSString *const kKeyProductPrintJobOptions = @"co.oceanlabs.pssdk.kKeyProductPrintJobOptions";

static id stringOrEmptyString(NSString *str) {
    return str ? str : @"";
}

@interface OLProductPrintJob ()
@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) NSArray *assets;
@property (strong, nonatomic) NSMutableDictionary *options;
@end

@implementation OLProductPrintJob

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

- (instancetype)initWithTemplateId:(NSString *)templateId imageFilePaths:(NSArray<NSString *> *)imageFilePaths {
    if (self = [super init]) {
        NSMutableArray *assets = [[NSMutableArray alloc] init];
        for (id imagePath in imageFilePaths) {
            NSAssert([imagePath isKindOfClass:[NSString class]], @"OLProductPrintJob initWithProduct:imageFilePaths: requires an NSArray of NSString not: %@", [imagePath class]);
            [assets addObject:[OLAsset assetWithFilePath:imagePath]];
        }
        self.uuid = [[NSUUID UUID] UUIDString];
        self.assets = assets;
        self.templateId = templateId;
    }
    
    return self;
}

- (instancetype)initWithTemplateId:(NSString *)templateId images:(NSArray<UIImage *> *)images {
    if (self = [super init]) {
        NSMutableArray *assets = [[NSMutableArray alloc] init];
        for (id image in images) {
            NSAssert([image isKindOfClass:[UIImage class]], @"OLProductPrintJob initWithProduct:images: requires an NSArray of UIImage not: %@", [image class]);
            [assets addObject:[OLAsset assetWithImageAsJPEG:image]];
        }
        self.uuid = [[NSUUID UUID] UUIDString];
        self.assets = assets;
        self.templateId = templateId;
    }
    
    return self;
}

- (instancetype)initWithTemplateId:(NSString *)templateId OLAssets:(NSArray<OLAsset *> *)assets {
    if (self = [super init]) {
#ifdef DEBUG
        for (id asset in assets) {
            NSAssert([asset isKindOfClass:[OLAsset class]], @"OLProductPrintJob initWithProduct:OLAssets: requires an NSArray of OLAsset not: %@", [asset class]);
        }
#endif
        self.uuid = [[NSUUID UUID] UUIDString];
        self.assets = assets;
        self.templateId = templateId;
    }
    
    return self;
}

- (instancetype)initWithTemplateId:(NSString *)templateId dataSources:(NSArray<id<OLAssetDataSource>> *)dataSources {
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (id dataSource in dataSources) {
        NSAssert([dataSource conformsToProtocol:@protocol(OLAssetDataSource)], @"The object you provided of type %@ does not conform to the OLAssetDataSource protocol", [dataSource class]);
        [assets addObject:[OLAsset assetWithDataSource:dataSource]];
    }
    return [self initWithTemplateId:templateId OLAssets:assets];
}

- (NSString *)productName {
    return [OLProductTemplate templateWithId:self.templateId].name;
}

- (NSUInteger)quantity {
    return self.assets.count;
}

- (NSString *)templateId {
    return _templateId;
}

- (NSArray *)assetsForUploading {
    return self.assets;
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

- (NSDictionary *)jsonRepresentation {
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    
    for (OLAsset *asset in self.assets) {
        [assets addObject:[NSString stringWithFormat:@"%lld", asset.assetId]];
    }
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    json[@"template_id"] = [OLProductTemplate templateWithId:self.templateId].identifier;
    json[@"assets"] = assets;
    json[@"frame_contents"] = @{};
    
    json[@"options"] = self.options;
    
    if (self.address) {
        NSDictionary *shippingAddress = @{@"recipient_name": stringOrEmptyString(self.address.fullNameFromFirstAndLast),
                                          @"address_line_1": stringOrEmptyString(self.address.line1),
                                          @"address_line_2": stringOrEmptyString(self.address.line2),
                                          @"city": stringOrEmptyString(self.address.city),
                                          @"county_state": stringOrEmptyString(self.address.stateOrCounty),
                                          @"postcode": stringOrEmptyString(self.address.zipOrPostcode),
                                          @"country_code": stringOrEmptyString(self.address.country.codeAlpha3)
                                          };
        [json setObject:shippingAddress forKey:@"shipping_address"];
    }
    
    return json;
}

- (id)copyWithZone:(NSZone *)zone {
    OLProductPrintJob *objectCopy = [[OLProductPrintJob allocWithZone:zone] init];
    // Copy over all instance variables from self to objectCopy.
    // Use deep copies for all strong pointers, shallow copies for weak.
    objectCopy.assets = self.assets;
    objectCopy.templateId = self.templateId;
    objectCopy.uuid = self.uuid;
    objectCopy.extraCopies = self.extraCopies;
    objectCopy.options = self.options;
    return objectCopy;
}

- (NSUInteger) hash {
    NSUInteger val = [self.templateId hash];
    for (id asset in self.assets) {
        val = 37 * val + [asset hash];
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
    
    if (![object isKindOfClass:[OLProductPrintJob class]]) {
        return NO;
    }
    OLProductPrintJob* printJob = (OLProductPrintJob*)object;
    
    return [self.templateId isEqual:printJob.templateId] && [self.assets isEqualToArray:printJob.assets] && [self.options isEqualToDictionary:printJob.options] && ((!self.address && !printJob.address) || [self.address isEqual:printJob.address]);
}


#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.templateId forKey:kKeyProductTemplateId];
    [aCoder encodeObject:self.assets forKey:kKeyImages];
    [aCoder encodeObject:self.uuid forKey:kKeyUUID];
    [aCoder encodeInteger:self.extraCopies forKey:kKeyExtraCopies];
    [aCoder encodeObject:self.options forKey:kKeyProductPrintJobOptions];
    [aCoder encodeObject:self.address forKey:kKeyProductPringJobAddress];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.templateId = [aDecoder decodeObjectForKey:kKeyProductTemplateId];
        self.assets = [aDecoder decodeObjectForKey:kKeyImages];
        self.uuid = [aDecoder decodeObjectForKey:kKeyUUID];
        self.extraCopies = [aDecoder decodeIntegerForKey:kKeyExtraCopies];
        self.options = [aDecoder decodeObjectForKey:kKeyProductPrintJobOptions];
        self.address = [aDecoder decodeObjectForKey:kKeyProductPringJobAddress];
    }
    
    return self;
}


@end
