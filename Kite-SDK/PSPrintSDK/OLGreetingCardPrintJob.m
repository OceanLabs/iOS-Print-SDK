//
//  OLPostcardPrintJob.m
//  Kite SDK
//
//  Created by Deon Botha on 30/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLGreetingCardPrintJob.h"
#import "OLAddress.h"
#import "OLCountry.h"
#import "OLAsset.h"
#import "OLProductTemplate.h"

static NSString *const kKeyFrontImage = @"co.oceanlabs.pssdk.kKeyFrontImage";
static NSString *const kKeyBackImage = @"co.oceanlabs.pssdk.kKeyBackImage";
static NSString *const kKeyInsideRightImage = @"co.oceanlabs.pssdk.kKeyInsideRightImage";
static NSString *const kKeyInsideLeftImage = @"co.oceanlabs.pssdk.kKeyInsideLeftImage";
static NSString *const kKeyMessage = @"co.oceanlabs.pssdk.kKeyMessage";
static NSString *const kKeyAddress = @"co.oceanlabs.pssdk.kKeyAddress";
static NSString *const kKeyProductTemplateId = @"co.oceanlabs.pssdk.kKeyProductTemplateId";
static NSString *const kKeyPrintJobOptions = @"co.oceanlabs.pssdk.kKeyPrintJobOptions";

static id stringOrEmptyString(NSString *str) {
    return str ? str : @"";
}

@interface OLGreetingCardPrintJob ()
@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) OLAsset *frontImageAsset;
@property (nonatomic, strong) OLAsset *backImageAsset;
@property (strong, nonatomic) OLAsset *insideRightImageAsset;
@property (strong, nonatomic) OLAsset *insideLeftImageAsset;
@property (nonatomic, copy) NSString *message;
@property (strong, nonatomic) NSMutableDictionary *options;

@end

@implementation OLGreetingCardPrintJob

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
- (id)initWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset insideRightImageAsset:(OLAsset *)insideRightImageAsset insideLeftImageAsset:(OLAsset *)insideLeftImageAsset {
    if (self = [super init]) {
        self.uuid = [[NSUUID UUID] UUIDString];
        self.frontImageAsset = frontImageAsset;
        self.backImageAsset = backImageAsset;
        self.insideRightImageAsset = insideRightImageAsset;
        self.insideLeftImageAsset = insideLeftImageAsset;
        self.templateId = templateId;
    }
    return self;
}

- (NSString *)templateId {
    return _templateId;
}

- (NSUInteger)quantity {
    return 1;
}

- (NSString *)productName {
    return [OLProductTemplate templateWithId:self.templateId].name;
}

- (NSDecimalNumber *)costInCurrency:(NSString *)currencyCode {
    return [[OLProductTemplate templateWithId:self.templateId] costPerSheetInCurrencyCode:currencyCode];
}

- (NSArray *)currenciesSupported {
    return [OLProductTemplate templateWithId:self.templateId].currenciesSupported;
}

- (NSArray<OLAsset *> *)assetsForUploading {
    if (self.backImageAsset) {
        return @[self.frontImageAsset, self.backImageAsset];
    } else {
        return @[self.frontImageAsset];
    }
}

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:self.templateId forKey:@"template_id"];
    
    NSMutableDictionary *assets = [[NSMutableDictionary alloc] init];
    json[@"assets"] = assets;
    assets[@"front_image"] = [NSNumber numberWithLongLong:self.frontImageAsset.assetId];
    
    if (self.backImageAsset){
        assets[@"back_image"] = [NSNumber numberWithLongLong:self.backImageAsset.assetId];
    }
    if (self.insideRightImageAsset){
        assets[@"inside_right_image"] = [NSNumber numberWithLongLong:self.insideRightImageAsset.assetId];
    }
    
    // set message
    if (self.message) {
        [json setObject:self.message forKey:@"message"];
    }
    
    json[@"options"] = self.options;
    
    if (self.address) {
        NSDictionary *shippingAddress = @{@"recipient_name": stringOrEmptyString(self.address.fullNameFromFirstAndLast),
                                          @"recipient_first_name": stringOrEmptyString(self.address.recipientFirstName),
                                          @"recipient_last_name": stringOrEmptyString(self.address.recipientLastName),
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

-(id) copyWithZone:(NSZone *)zone{
    // Absolute hack but simple code, archive then unarchive copy :) Slower than doing it properly but still fast enough!
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}

- (NSUInteger) hash{
    NSUInteger result = 17;
    if (self.templateId) result *= [self.templateId hash];
    if (self.frontImageAsset) result *= [self.frontImageAsset hash];
    if (self.backImageAsset) result *= [self.backImageAsset hash];
    if (self.insideRightImageAsset) result *= [self.insideRightImageAsset hash];
    if (self.insideLeftImageAsset) result *= [self.insideLeftImageAsset hash];
    if (self.message && [self.message hash] > 0) result *= [self.message hash];
    if (self.address) result *= [self.address hash];
    result = 18 * result + [self.options hash];
    return result;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[OLGreetingCardPrintJob class]]) {
        return NO;
    }
    OLGreetingCardPrintJob* printJob = (OLGreetingCardPrintJob*)object;
    BOOL result = YES;
    if (self.templateId) result &= [self.templateId isEqual:printJob.templateId];
    if (self.frontImageAsset) result &= [self.frontImageAsset isEqual:printJob.frontImageAsset];
    if (self.backImageAsset) result &= [self.backImageAsset isEqual:printJob.backImageAsset];
    if (self.insideRightImageAsset) result &= [self.insideRightImageAsset isEqual:printJob.insideRightImageAsset];
    if (self.insideLeftImageAsset) result &= [self.insideLeftImageAsset isEqual:printJob.insideLeftImageAsset];
    if (self.message) result &= [self.message isEqual:printJob.message];
    if (self.address) result &= [self.address isEqual:printJob.address];
    result &= [self.options isEqualToDictionary:printJob.options];
    return result;
}

#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.frontImageAsset forKey:kKeyFrontImage];
    [aCoder encodeObject:self.backImageAsset forKey:kKeyBackImage];
    [aCoder encodeObject:self.insideRightImageAsset forKey:kKeyInsideRightImage];
    [aCoder encodeObject:self.insideLeftImageAsset forKey:kKeyInsideLeftImage];
    [aCoder encodeObject:self.message forKey:kKeyMessage];
    [aCoder encodeObject:self.address forKey:kKeyAddress];
    [aCoder encodeObject:self.templateId forKey:kKeyProductTemplateId];
    [aCoder encodeObject:self.backImageAsset forKey:kKeyBackImage];
    [aCoder encodeObject:self.options forKey:kKeyPrintJobOptions];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.frontImageAsset = [aDecoder decodeObjectForKey:kKeyFrontImage];
        self.backImageAsset = [aDecoder decodeObjectForKey:kKeyBackImage];
        self.insideRightImageAsset = [aDecoder decodeObjectForKey:kKeyInsideRightImage];
        self.insideLeftImageAsset = [aDecoder decodeObjectForKey:kKeyInsideLeftImage];
        self.message = [aDecoder decodeObjectForKey:kKeyMessage];
        self.address = [aDecoder decodeObjectForKey:kKeyAddress];
        self.templateId = [aDecoder decodeObjectForKey:kKeyProductTemplateId];
        self.backImageAsset = [aDecoder decodeObjectForKey:kKeyBackImage];
        self.options = [aDecoder decodeObjectForKey:kKeyPrintJobOptions];
    }
    
    return self;
}

@end
