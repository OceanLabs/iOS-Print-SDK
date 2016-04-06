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
static NSString *const kKeyDateAddedToBasket = @"co.oceanlabs.pssdk.kKeyDateAddedToBasket";
static NSString *const kKeyDeclinedOffers = @"co.oceanlabs.pssdk.kKeyDeclinedOffers";
static NSString *const kKeyAcceptedOffers = @"co.oceanlabs.pssdk.kKeyAcceptedOffers";
static NSString *const kKeyRedeemedOffer = @"co.oceanlabs.pssdk.kKeyRedeemedOffer";

static id stringOrEmptyString(NSString *str) {
    return str ? str : @"";
}

@interface OLProductPrintJob ()
@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) NSArray *assets;
@property (strong, nonatomic) NSMutableDictionary *options;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

@implementation OLProductPrintJob

@synthesize address;
@synthesize uuid;
@synthesize extraCopies;
@synthesize dateAddedToBasket;

-(NSMutableSet *) declinedOffers{
    if (!_declinedOffers){
        _declinedOffers = [[NSMutableSet alloc] init];
    }
    return _declinedOffers;
}

-(NSMutableSet *) acceptedOffers{
    if (!_acceptedOffers){
        _acceptedOffers = [[NSMutableSet alloc] init];
    }
    return _acceptedOffers;
}

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
    if ([OLProductTemplate templateWithId:self.templateId].templateUI == kOLTemplateUINonCustomizable){
        return 1;
    }
    return self.assets.count;
}

- (NSDecimalNumber *)numberOfItemsInJob{
    OLProductTemplate *template = [OLProductTemplate templateWithId:self.templateId];
    if (template.templateUI == kOLTemplateUINonCustomizable){
        return [NSDecimalNumber decimalNumberWithString:@"1"];
    }
    
    float numberOfPhotos = [self assetsForUploading].count;
    return [[NSDecimalNumber alloc] initWithFloat:ceilf(numberOfPhotos / (float) MAX(template.quantityPerSheet, 1))];
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
    NSMutableArray *pdfs = [[NSMutableArray alloc] init];
    
    for (OLAsset *asset in self.assets) {
        if (asset.mimeType == kOLMimeTypePDF){
            [pdfs addObject:[NSString stringWithFormat:@"%lld", asset.assetId]];
        }
        else{
            [assets addObject:[NSString stringWithFormat:@"%lld", asset.assetId]];
        }
    }
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    json[@"template_id"] = [OLProductTemplate templateWithId:self.templateId].identifier;
    json[@"assets"] = assets;
    if (pdfs.count > 0){
        json[@"pdf"] = [pdfs firstObject];
    }
    json[@"frame_contents"] = @{};
    
    if (self.acceptedOffers.count > 0 && [self.acceptedOffers.allObjects.firstObject identifier]){
        json[@"triggered_upsell"] = [NSNumber numberWithUnsignedInteger:[self.acceptedOffers.allObjects.firstObject identifier]];
    }
    if (self.redeemedOffer){
        json[@"redeemed_upsell"] = [NSNumber numberWithUnsignedInteger:self.redeemedOffer.identifier];
    }
    
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
    objectCopy.declinedOffers = self.declinedOffers;
    objectCopy.acceptedOffers = self.acceptedOffers;
    objectCopy.redeemedOffer = self.redeemedOffer;
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
    [aCoder encodeObject:self.dateAddedToBasket forKey:kKeyDateAddedToBasket];
    [aCoder encodeObject:self.declinedOffers forKey:kKeyDeclinedOffers];
    [aCoder encodeObject:self.acceptedOffers forKey:kKeyAcceptedOffers];
    [aCoder encodeObject:self.redeemedOffer forKey:kKeyRedeemedOffer];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.templateId = [aDecoder decodeObjectForKey:kKeyProductTemplateId];
        self.assets = [aDecoder decodeObjectForKey:kKeyImages];
        self.uuid = [aDecoder decodeObjectForKey:kKeyUUID];
        self.extraCopies = [aDecoder decodeIntegerForKey:kKeyExtraCopies];
        self.options = [aDecoder decodeObjectForKey:kKeyProductPrintJobOptions];
        self.address = [aDecoder decodeObjectForKey:kKeyProductPringJobAddress];
        self.dateAddedToBasket = [aDecoder decodeObjectForKey:kKeyDateAddedToBasket];
        self.declinedOffers = [aDecoder decodeObjectForKey:kKeyDeclinedOffers];
        self.acceptedOffers = [aDecoder decodeObjectForKey:kKeyAcceptedOffers];
        self.redeemedOffer = [aDecoder decodeObjectForKey:kKeyRedeemedOffer];
    }
    
    return self;
}


@end
