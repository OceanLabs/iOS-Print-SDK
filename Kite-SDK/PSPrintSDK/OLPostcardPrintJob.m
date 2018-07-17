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
#import "OLAsset+Private.h"
#import "OLProductTemplate.h"
#import "OLImageDownloader.h"

static NSString *const kKeyFrontImage = @"co.oceanlabs.pssdk.kKeyFrontImage";
static NSString *const kKeyBackImage = @"co.oceanlabs.pssdk.kKeyBackImage";
static NSString *const kKeyMessage = @"co.oceanlabs.pssdk.kKeyMessage";
static NSString *const kKeyAddress = @"co.oceanlabs.pssdk.kKeyAddress";
static NSString *const kKeyProductTemplateId = @"co.oceanlabs.pssdk.kKeyProductTemplateId";
static NSString *const kKeyPostcardPrintJobOptions = @"co.oceanlabs.pssdk.kKeyPostcardPrintJobOptions";
static NSString *const kKeyUUID = @"co.oceanlabs.pssdk.kKeyUUID";
static NSString *const kKeyExtraCopies = @"co.oceanlabs.pssdk.kKeyExtraCopies";
static NSString *const kKeyDateAddedToBasket = @"co.oceanlabs.pssdk.kKeyDateAddedToBasket";

@interface OLPostcardPrintJob ()
@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) OLAsset *frontImageAsset;
@property (nonatomic, strong) OLAsset *backImageAsset;
@property (nonatomic, copy) NSString *message;
@property (strong, nonatomic) NSMutableDictionary *options;

@end

@implementation OLPostcardPrintJob

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

- (id)initWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset message:(NSString *)message {
    return [self initWithTemplateId:templateId frontImageOLAsset:frontImageAsset backImageOLAsset:nil message:message];
}

- (id)initWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset {
    return [self initWithTemplateId:templateId frontImageOLAsset:frontImageAsset backImageOLAsset:backImageAsset message:nil];
}

- (id)initWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset message:(NSString *)message {
    if (self = [super init]) {
        self.uuid = [[NSUUID UUID] UUIDString];
        self.frontImageAsset = frontImageAsset;
        self.backImageAsset = backImageAsset;
        self.message = message;
        self.templateId = templateId;
        self.selectedShippingMethod = self.template.availableShippingMethods.firstObject;
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
    
    json[@"job_id"] = [self uuid];
    json[@"multiples"] = [NSNumber numberWithInteger:self.extraCopies + 1];
    
    return json;
}

-(id) copyWithZone:(NSZone *)zone{
    // Absolute hack but simple code, archive then unarchive copy :) Slower than doing it properly but still fast enough!
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}

- (NSUInteger) hash{
    NSUInteger val = 17;
    if (self.templateId) val *= [self.templateId hash];
    if (self.frontImageAsset) val *= [self.frontImageAsset hash];
    if (self.backImageAsset) val *= [self.backImageAsset hash];
    if (self.message && [self.message hash] > 0) val *= [self.message hash];
    if (self.extraCopies) val *= self.extraCopies+1;
    val = 18 * val + [self.options hash];
    val = 41 * val + [self.uuid hash];
    
    return val;
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
    result &= [self.options isEqualToDictionary:printJob.options];
    return result;
}

#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.frontImageAsset forKey:kKeyFrontImage];
    [aCoder encodeObject:self.backImageAsset forKey:kKeyBackImage];
    [aCoder encodeObject:self.message forKey:kKeyMessage];
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
        self.templateId = [aDecoder decodeObjectForKey:kKeyProductTemplateId];
        self.options = [aDecoder decodeObjectForKey:kKeyPostcardPrintJobOptions];
        self.extraCopies = [aDecoder decodeIntegerForKey:kKeyExtraCopies];
        self.uuid = [aDecoder decodeObjectForKey:kKeyUUID];
        self.dateAddedToBasket = [aDecoder decodeObjectForKey:kKeyDateAddedToBasket];
    }
    
    return self;
}

#pragma mark - Product

- (NSInteger) hashValue {
    return [self hash];
}

- (void)setIdentifier:(NSString *)s {
    self.uuid = s;
}

- (NSString *)identifier {
    return self.uuid;
}

- (void)setItemCount:(NSInteger)itemCount {
    self.extraCopies = itemCount - 1;
}

- (NSInteger)itemCount {
    return self.extraCopies + 1;
}

- (NSInteger)numberOfPages {
    OLProductTemplate *productTemplate = [OLProductTemplate templateWithId:self.templateId];
    NSUInteger sheetQuanity = productTemplate.quantityPerSheet == 0 ? 1 : productTemplate.quantityPerSheet;
    return ceil(productTemplate.quantityPerSheet / sheetQuanity);
}

@synthesize selectedShippingMethod;

- (OLProductTemplate *)template {
    return [OLProductTemplate templateWithId:self.templateId];
}

- (NSMutableDictionary *) upsoldOptions {
    return self.options;
}

@synthesize upsoldTemplate;

- (NSArray<PhotobookAsset *> * _Nullable)assetsToUpload {
    return [OLAsset photobookAssetsFromAssets:self.assetsForUploading];
}

- (NSDictionary<NSString *,id> * _Nullable)orderParameters {
    return self.jsonRepresentation;
}

- (void)previewImageWithSize:(CGSize)size completionHandler:(void (^ _Nonnull)(UIImage * _Nullable))completionHandler {
    [[OLImageDownloader sharedInstance] downloadImageAtURL:[OLProductTemplate templateWithId:self.templateId].coverPhotoURL withCompletionHandler:^(UIImage *image, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(image);
        });
    }];
}

- (void)processUploadedAssetsWithCompletionHandler:(void (^ _Nonnull)(NSError * _Nullable))completionHandler {
    completionHandler(nil);
}

@end
