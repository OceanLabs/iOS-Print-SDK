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

#import "OLPostcardPrintJob.h"
#import "OLAddress.h"
#import "OLCountry.h"
#import "OLAsset.h"
#import "OLProductTemplate.h"

static NSString *const kKeyFrontImage = @"co.oceanlabs.pssdk.kKeyFrontImage";
static NSString *const kKeyBackImage = @"co.oceanlabs.pssdk.kKeyBackImage";
static NSString *const kKeyMessage = @"co.oceanlabs.pssdk.kKeyMessage";
static NSString *const kKeyAddress = @"co.oceanlabs.pssdk.kKeyAddress";
static NSString *const kKeyProductTemplateId = @"co.oceanlabs.pssdk.kKeyProductTemplateId";
static NSString *const kKeyPostcardPrintJobOptions = @"co.oceanlabs.pssdk.kKeyPostcardPrintJobOptions";
static NSString *const kKeyUUID = @"co.oceanlabs.pssdk.kKeyUUID";
static NSString *const kKeyExtraCopies = @"co.oceanlabs.pssdk.kKeyExtraCopies";
static NSString *const kKeyDateAddedToBasket = @"co.oceanlabs.pssdk.kKeyDateAddedToBasket";

static id stringOrEmptyString(NSString *str) {
    return str ? str : @"";
}

@interface OLPostcardPrintJob ()
@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) OLAsset *frontImageAsset;
@property (nonatomic, strong) OLAsset *backImageAsset;
@property (nonatomic, copy) NSString *message;
@property (strong, nonatomic) NSMutableDictionary *options;

@end

@implementation OLPostcardPrintJob

@synthesize address;
@synthesize uuid;
@synthesize extraCopies;
@synthesize dateAddedToBasket;

-(NSMutableDictionary *) options{
    if (!_options){
        _options = [[NSMutableDictionary alloc] init];
    }
    return _options;
}

- (void)setValue:(NSString *)value forOption:(NSString *)option{
    self.options[option] = value;
}

- (id)initWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset message:(NSString *)message address:(OLAddress *)theAddress {
    return [self initWithTemplateId:templateId frontImageOLAsset:frontImageAsset backImageOLAsset:nil message:message address:theAddress];
}

- (id)initWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset {
    return [self initWithTemplateId:templateId frontImageOLAsset:frontImageAsset backImageOLAsset:backImageAsset message:nil address:nil];
}

- (id)initWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset message:(NSString *)message address:(OLAddress *)theAddress {
    if (self = [super init]) {
        self.uuid = [[NSUUID UUID] UUIDString];
        self.frontImageAsset = frontImageAsset;
        self.backImageAsset = backImageAsset;
        self.message = message;
        self.address = theAddress;
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

- (NSDecimalNumber *)numberOfItemsInJob{
    return [NSDecimalNumber decimalNumberWithString:@"1"];
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
    NSMutableDictionary *pdfs = [[NSMutableDictionary alloc] init];
    
    if (self.frontImageAsset.mimeType == kOLMimeTypePDF){
        pdfs[@"front_image"] = [NSString stringWithFormat:@"%lld", self.frontImageAsset.assetId];
    }
    else{
        assets[@"front_image"] = [NSString stringWithFormat:@"%lld", self.frontImageAsset.assetId];
    }
    
    if (self.backImageAsset){
        if (self.backImageAsset.mimeType == kOLMimeTypePDF){
            pdfs[@"back_image"] = [NSString stringWithFormat:@"%lld", self.backImageAsset.assetId];
        }
        else{
            assets[@"back_image"] = [NSString stringWithFormat:@"%lld", self.backImageAsset.assetId];
        }
    }
    
    // set message
    if (self.message) {
        [json setObject:self.message forKey:@"message"];
    }
    
    json[@"pdf"] = pdfs[@"front_image"];
    json[@"assets"] = assets;
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
    if (self.message && [self.message hash] > 0) result *= [self.message hash];
    if (self.address) result *= [self.address hash];
    if (self.extraCopies) result *= self.extraCopies+1;
    result = 18 * result + [self.options hash];
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
    if (self.backImageAsset) result &= [self.backImageAsset isEqual:printJob.backImageAsset];
    if (self.message) result &= [self.message isEqual:printJob.message];
    if (self.address) result &= [self.address isEqual:printJob.address];
    result &= [self.options isEqualToDictionary:printJob.options];
    return result;
}

#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.frontImageAsset forKey:kKeyFrontImage];
    [aCoder encodeObject:self.backImageAsset forKey:kKeyBackImage];
    [aCoder encodeObject:self.message forKey:kKeyMessage];
    [aCoder encodeObject:self.address forKey:kKeyAddress];
    [aCoder encodeObject:self.templateId forKey:kKeyProductTemplateId];
    [aCoder encodeObject:self.options forKey:kKeyPostcardPrintJobOptions];
    [aCoder encodeInteger:self.extraCopies forKey:kKeyExtraCopies];
    [aCoder encodeObject:self.uuid forKey:kKeyUUID];
    [aCoder encodeObject:self.dateAddedToBasket forKey:kKeyDateAddedToBasket];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.frontImageAsset = [aDecoder decodeObjectForKey:kKeyFrontImage];
        self.backImageAsset = [aDecoder decodeObjectForKey:kKeyBackImage];
        self.message = [aDecoder decodeObjectForKey:kKeyMessage];
        self.address = [aDecoder decodeObjectForKey:kKeyAddress];
        self.templateId = [aDecoder decodeObjectForKey:kKeyProductTemplateId];
        self.options = [aDecoder decodeObjectForKey:kKeyPostcardPrintJobOptions];
        self.extraCopies = [aDecoder decodeIntegerForKey:kKeyExtraCopies];
        self.uuid = [aDecoder decodeObjectForKey:kKeyUUID];
        self.dateAddedToBasket = [aDecoder decodeObjectForKey:kKeyDateAddedToBasket];
    }
    
    return self;
}

@end
