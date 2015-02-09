//
//  OLPostcardPrintJob.m
//  Kite SDK
//
//  Created by Deon Botha on 30/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLPostcardPrintJob.h"
#import "OLAddress.h"
#import "OLCountry.h"
#import "OLAsset.h"
#import "OLProductTemplate.h"

static NSString *const kKeyFrontImage = @"co.oceanlabs.pssdk.kKeyFrontImage";
static NSString *const kKeyTextOnPhotoImage = @"co.oceanlabs.pssdk.kKeyTextOnPhotoImage";
static NSString *const kKeyMessage = @"co.oceanlabs.pssdk.kKeyMessage";
static NSString *const kKeyAddress = @"co.oceanlabs.pssdk.kKeyAddress";
static NSString *const kKeyLocation = @"co.oceanlabs.pssdk.kKeyLocation";
static NSString *const kKeyProductTemplateId = @"co.oceanlabs.pssdk.kKeyProductTemplateId";

static id stringOrNSNull(NSString *str) {
    return str ? str : [NSNull null];
}

static id stringOrEmptyString(NSString *str) {
    return str ? str : @"";
}

@interface OLPostcardPrintJob ()
@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) OLAsset *frontImageAsset;
@property (nonatomic, strong) OLAsset *textOnPhotoImageAsset;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, strong) OLAddress *address;
@property (nonatomic, strong) NSArray *location;

@end

@implementation OLPostcardPrintJob


- (id)initWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset textOnPhotoImageOLAsset:(OLAsset *)textOnPhotoAsset message:(NSString *)message address:(OLAddress *)address location:(NSArray/*<NSString>*/ *)location; {
    if (self = [super init]) {
        self.frontImageAsset = frontImageAsset;
        self.textOnPhotoImageAsset = textOnPhotoAsset;
        self.message = message;
        self.address = address;
        self.location = location;
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

- (NSArray/*<OLImage>*/ *)assetsForUploading {
    if (self.textOnPhotoImageAsset) {
        return @[self.frontImageAsset, self.textOnPhotoImageAsset];
    } else {
        return @[self.frontImageAsset];
    }
}

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:self.templateId forKey:@"template_id"];
    
    NSMutableDictionary *assets = [[NSMutableDictionary alloc] init];
    json[@"assets"] = assets;
    assets[@"photo"] = [NSNumber numberWithLongLong:self.frontImageAsset.assetId];
    if (self.textOnPhotoImageAsset) {
        assets[@"overlay_image"] = [NSNumber numberWithLongLong:self.textOnPhotoImageAsset.assetId];
    }

    NSMutableDictionary *frameContents = [[NSMutableDictionary alloc] init];
    [json setObject:frameContents forKey:@"frame_contents"];
    
    // set message
    [frameContents setObject:@{@"paragraphs":@[@{@"content":@"15", @"style":@"spacer"}, @{@"content":self.message, @"style":@"body"}]} forKey:@"frame1"];
    
    // set location
    static const NSUInteger kAssetIdLocationIcon = 10;
    if (self.location.count == 1) {
        [frameContents setObject:@{@"paragraphs":@[@{@"content":self.location[0], @"style":@"location1"}]} forKey:@"location"];
        assets[@"location_icon"] = [NSNumber numberWithLongLong:kAssetIdLocationIcon];
    } else if (self.location.count > 1) {
        [frameContents setObject:@{@"paragraphs":@[@{@"content":self.location[0], @"style":@"location1"}, @{@"content":self.location[1], @"style":@"location2"}]} forKey:@"location"];
        assets[@"location_icon"] = [NSNumber numberWithLongLong:kAssetIdLocationIcon];
    }
    
    // set address
    NSArray *addrComponents = @[@[stringOrNSNull(self.address.recipientName), @"body-centered"],
                                @[stringOrNSNull(self.address.line1), @"body-centered"],
                                @[stringOrNSNull(self.address.line2), @"body-centered"],
                                @[stringOrNSNull(self.address.city), @"body-centered"],
                                @[stringOrNSNull(self.address.stateOrCounty), @"body-centered"],
                                @[stringOrNSNull(self.address.zipOrPostcode), @"postcode-or-country"],
                                @[stringOrNSNull(self.address.country.name), @"postcode-or-country"]];
    
    NSUInteger addrComponentId = 0;
    for (NSArray *addrComponent in addrComponents) {
        id component = addrComponent[0];
        NSString *style = addrComponent[1];
        if ([component isKindOfClass:[NSString class]]) {
            if ([[component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet] ] length] > 0) {
                [frameContents setObject:@{@"paragraphs":@[@{@"content":component, @"style":style}]} forKey:[NSString stringWithFormat:@"addr%lu", (unsigned long)++addrComponentId]];
            }
        }
    }
    
    if (addrComponentId == 7) {
        assets[@"extra_dots"] = [NSNumber numberWithLongLong:11];
    }
    
    if (self.address) {
        NSDictionary *shippingAddress = @{@"recipient_name": stringOrEmptyString(self.address.recipientName),
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
    NSUInteger result = 1;
    if (self.templateId) result *= [self.templateId hash];
    if (self.frontImageAsset) result *= [self.frontImageAsset hash];
    if (self.textOnPhotoImageAsset) result *= [self.textOnPhotoImageAsset hash];
    if (self.message && [self.message hash] > 0) result *= [self.message hash];
    if (self.address) result *= [self.address hash];
    if (self.location) result *= [self.location hash];
    return result;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[OLPostcardPrintJob class]]) {
        return NO;
    }
    OLPostcardPrintJob* printJob = (OLPostcardPrintJob*)object;
    BOOL result = YES;
    if (self.templateId) result &= [self.templateId isEqual:printJob.templateId];
    if (self.frontImageAsset) result &= [self.frontImageAsset isEqual:printJob.frontImageAsset];
    if (self.textOnPhotoImageAsset) result &= [self.textOnPhotoImageAsset isEqual:printJob.textOnPhotoImageAsset];
    if (self.message) result &= [self.message isEqual:printJob.message];
    if (self.address) result &= [self.address isEqual:printJob.address];
    if (self.location) result &= [self.location isEqual:printJob.location];
    return result;
}

#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.frontImageAsset forKey:kKeyFrontImage];
    [aCoder encodeObject:self.message forKey:kKeyMessage];
    [aCoder encodeObject:self.address forKey:kKeyAddress];
    [aCoder encodeObject:self.location forKey:kKeyLocation];
    [aCoder encodeObject:self.textOnPhotoImageAsset forKey:kKeyTextOnPhotoImage];
    [aCoder encodeObject:self.templateId forKey:kKeyProductTemplateId];
    
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.frontImageAsset = [aDecoder decodeObjectForKey:kKeyFrontImage];
        self.message = [aDecoder decodeObjectForKey:kKeyMessage];
        self.address = [aDecoder decodeObjectForKey:kKeyAddress];
        self.location = [aDecoder decodeObjectForKey:kKeyLocation];
        self.textOnPhotoImageAsset = [aDecoder decodeObjectForKey:kKeyTextOnPhotoImage];
        self.templateId = [aDecoder decodeObjectForKey:kKeyProductTemplateId];
    }
    
    return self;
}

@end
