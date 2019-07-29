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

#import "OLGreetingCardPrintJob.h"
#import "OLAsset+Private.h"
#import "OLProductTemplate.h"
#import "OLImageDownloader.h"
#import "OLCountry.h"

static NSString *const kKeyFrontImage = @"co.oceanlabs.pssdk.kKeyFrontImage";
static NSString *const kKeyBackImage = @"co.oceanlabs.pssdk.kKeyBackImage";
static NSString *const kKeyInsideRightImage = @"co.oceanlabs.pssdk.kKeyInsideRightImage";
static NSString *const kKeyInsideLeftImage = @"co.oceanlabs.pssdk.kKeyInsideLeftImage";
static NSString *const kKeyMessage = @"co.oceanlabs.pssdk.kKeyMessage";
static NSString *const kKeyAddress = @"co.oceanlabs.pssdk.kKeyAddress";
static NSString *const kKeyProductTemplateId = @"co.oceanlabs.pssdk.kKeyProductTemplateId";
static NSString *const kKeyPrintJobOptions = @"co.oceanlabs.pssdk.kKeyPrintJobOptions";
static NSString *const kKeyUUID = @"co.oceanlabs.pssdk.kKeyUUID";
static NSString *const kKeyExtraCopies = @"co.oceanlabs.pssdk.kKeyExtraCopies";

@interface OLGreetingCardPrintJob ()
@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) OLAsset *frontImageAsset;
@property (nonatomic, strong) OLAsset *backImageAsset;
@property (strong, nonatomic) OLAsset *insideRightImageAsset;
@property (strong, nonatomic) OLAsset *insideLeftImageAsset;
@property (nonatomic, strong) PhotobookAsset *frontPhotobookAsset;
@property (nonatomic, strong) PhotobookAsset *backPhotobookAsset;
@property (strong, nonatomic) PhotobookAsset *insideRightPhotobookAsset;
@property (strong, nonatomic) PhotobookAsset *insideLeftPhotobookAsset;
@property (nonatomic, copy) NSString *message;

@end

@implementation OLGreetingCardPrintJob

@synthesize uuid;
@synthesize extraCopies;

- (void)setValue:(NSString *)value forOption:(NSString *)option {}

- (id)initWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset insideRightImageAsset:(OLAsset *)insideRightImageAsset insideLeftImageAsset:(OLAsset *)insideLeftImageAsset {
    if (self = [super init]) {
        self.uuid = [[NSUUID UUID] UUIDString];
        if (frontImageAsset) {
            self.frontPhotobookAsset = [OLAsset photobookAssetsFromAssets:@[frontImageAsset]].firstObject;
            self.frontImageAsset = frontImageAsset;
        }
        if (backImageAsset) {
            self.backPhotobookAsset = [OLAsset photobookAssetsFromAssets:@[backImageAsset]].firstObject;
            self.backImageAsset = backImageAsset;
        }
        if (insideRightImageAsset) {
            self.insideRightPhotobookAsset = [OLAsset photobookAssetsFromAssets:@[insideRightImageAsset]].firstObject;
            self.insideRightImageAsset = insideRightImageAsset;
        }
        if (insideLeftImageAsset) {
            self.insideLeftPhotobookAsset = [OLAsset photobookAssetsFromAssets:@[insideLeftImageAsset]].firstObject;
            self.insideLeftImageAsset = insideLeftImageAsset;
        }
        self.templateId = templateId;
        
        NSString *countryCode = [OLCountry countryForCurrentLocale].codeAlpha3;
        self.selectedShippingMethod = self.template.availableShippingMethods[countryCode].firstObject;
    }
    return self;
}

- (NSArray <PhotobookAsset *> *)assetsToUpload {
    NSMutableArray <PhotobookAsset *>*assets = [[NSMutableArray alloc] init];
    if (self.frontImageAsset) {
        [assets addObject:self.frontPhotobookAsset];
    }
    if (self.backImageAsset) {
        [assets addObject:self.backPhotobookAsset];
    }
    if (self.insideLeftImageAsset) {
        [assets addObject:self.insideLeftPhotobookAsset];
    }
    if (self.insideRightImageAsset) {
        [assets addObject:self.insideRightPhotobookAsset];
    }
    return assets;
}

- (NSArray<OLAsset *> *)assetsForUploading {
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    if (self.frontImageAsset){
        [assets addObject:self.frontImageAsset];
    }
    if (self.backImageAsset){
        [assets addObject:self.backImageAsset];
    }
    if (self.insideLeftImageAsset){
        [assets addObject:self.insideLeftImageAsset];
    }
    if (self.insideRightImageAsset){
        [assets addObject:self.insideRightImageAsset];
    }
    
    return assets;
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

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:self.templateId forKey:@"template_id"];
    
    NSMutableDictionary *assets = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *pdfs = [[NSMutableDictionary alloc] init];
    
//    if (self.frontImageAsset.mimeType == kOLMimeTypePDF){
//        pdfs[@"front_image"] = [NSString stringWithFormat:@"%lld", self.frontImageAsset.assetId];
//    }
    if (self.frontPhotobookAsset.uploadUrl){
        assets[@"front_image"] = self.frontPhotobookAsset.uploadUrl;
    }
    else{
        assets[@"front_image"] = @(self.frontImageAsset.assetId);
    }
    
    if (self.backImageAsset){
//        if (self.backImageAsset.mimeType == kOLMimeTypePDF){
//            pdfs[@"back_image"] = [NSString stringWithFormat:@"%lld", self.backImageAsset.assetId];
//        }
        if (self.backPhotobookAsset.uploadUrl){
            assets[@"back_image"] = self.backPhotobookAsset.uploadUrl;
        }
        else{
            assets[@"back_image"] = @(self.backImageAsset.assetId);
        }
    }
    if (self.insideRightImageAsset){
//        if (self.insideRightImageAsset.mimeType == kOLMimeTypePDF){
//            pdfs[@"inside_right_image"] = [NSString stringWithFormat:@"%lld", self.insideRightImageAsset.assetId];
//        }
        if (self.insideRightPhotobookAsset.uploadUrl){
            assets[@"inside_right_image"] = self.insideRightPhotobookAsset.uploadUrl;
        }
        else{
            assets[@"inside_right_image"] = @(self.insideRightImageAsset.assetId);
        }
    }
    if (self.insideLeftImageAsset){
//        if (self.insideLeftImageAsset.mimeType == kOLMimeTypePDF){
//            pdfs[@"inside_left_image"] = [NSString stringWithFormat:@"%lld", self.insideLeftImageAsset.assetId];
//        }
        if (self.insideLeftPhotobookAsset.uploadUrl){
            assets[@"inside_left_image"] = self.insideLeftPhotobookAsset.uploadUrl;
        }
        else{
            assets[@"inside_left_image"] = @(self.insideLeftImageAsset.assetId);
        }
    }
    
    json[@"assets"] = assets;
    json[@"pdf"] = pdfs[@"front_image"];
    json[@"job_id"] = [self uuid];
    json[@"multiples"] = [NSNumber numberWithInteger:self.extraCopies + 1];
    json[@"shipping_class"] = [NSNumber numberWithInteger:selectedShippingMethod.id];
    
    // set message
    if (self.message) {
        [json setObject:self.message forKey:@"message"];
    }
    
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
    if (self.insideRightImageAsset) val *= [self.insideRightImageAsset hash];
    if (self.insideLeftImageAsset) val *= [self.insideLeftImageAsset hash];
    if (self.message && [self.message hash] > 0) val *= [self.message hash];
    if (self.extraCopies) val *= self.extraCopies+1;
    val = 41 * val + [self.uuid hash];
    val = 42 * val + [self.selectedShippingMethod hash];
    return val;
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
    if (self.selectedShippingMethod) result &= [self.selectedShippingMethod isEqual:printJob.selectedShippingMethod];
    return result;
}

#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.frontImageAsset forKey:kKeyFrontImage];
    [aCoder encodeObject:self.backImageAsset forKey:kKeyBackImage];
    [aCoder encodeObject:self.insideRightImageAsset forKey:kKeyInsideRightImage];
    [aCoder encodeObject:self.insideLeftImageAsset forKey:kKeyInsideLeftImage];
    [aCoder encodeObject:self.message forKey:kKeyMessage];
    [aCoder encodeObject:self.templateId forKey:kKeyProductTemplateId];
    [aCoder encodeInteger:self.extraCopies forKey:kKeyExtraCopies];
    [aCoder encodeObject:self.uuid forKey:kKeyUUID];
    [aCoder encodeObject:self.selectedShippingMethod forKey:@"selectedShippingMethod"];
    
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.frontImageAsset = [aDecoder decodeObjectForKey:kKeyFrontImage];
        self.backImageAsset = [aDecoder decodeObjectForKey:kKeyBackImage];
        self.insideRightImageAsset = [aDecoder decodeObjectForKey:kKeyInsideRightImage];
        self.insideLeftImageAsset = [aDecoder decodeObjectForKey:kKeyInsideLeftImage];
        if (self.frontImageAsset) {
            self.frontPhotobookAsset = [OLAsset photobookAssetsFromAssets:@[self.frontImageAsset]].firstObject;
        }
        if (self.backImageAsset) {
            self.backPhotobookAsset = [OLAsset photobookAssetsFromAssets:@[self.backImageAsset]].firstObject;
        }
        if (self.insideLeftImageAsset) {
            self.insideLeftPhotobookAsset = [OLAsset photobookAssetsFromAssets:@[self.insideLeftImageAsset]].firstObject;
        }
        if (self.insideRightImageAsset) {
            self.insideRightPhotobookAsset = [OLAsset photobookAssetsFromAssets:@[self.insideRightImageAsset]].firstObject;
        }
        self.message = [aDecoder decodeObjectForKey:kKeyMessage];
        self.templateId = [aDecoder decodeObjectForKey:kKeyProductTemplateId];
        if (!self.template) {
            return nil;
        }
        self.extraCopies = [aDecoder decodeIntegerForKey:kKeyExtraCopies];
        self.uuid = [aDecoder decodeObjectForKey:kKeyUUID];
        self.selectedShippingMethod = [aDecoder decodeObjectForKey:@"selectedShippingMethod"];
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

@synthesize selectedShippingMethod;

- (OLProductTemplate *)template {
    if (![OLProductTemplate templateWithId:self.templateId]){
        OLProductTemplate *template = [[OLProductTemplate alloc] init];
        template.identifier = self.templateId;
        return template;
    }
    return [OLProductTemplate templateWithId:self.templateId];
}

- (NSDictionary<NSString *,id> * _Nullable)orderParameters {
    return self.jsonRepresentation;
}

- (NSDictionary<NSString *,id> * _Nullable)costParameters {
    return self.jsonRepresentation;
}

- (void)previewImageWithSize:(CGSize)size completionHandler:(void (^ _Nonnull)(UIImage * _Nullable))completionHandler {
    if (![OLProductTemplate templateWithId:self.templateId]){
        [OLProductTemplate syncTemplateId:self.templateId withCompletionHandler:^(NSArray <OLProductTemplate *>*templates, NSError *error){
            [[OLImageDownloader sharedInstance] downloadImageAtURL:[OLProductTemplate templateWithId:self.templateId].coverPhotoURL withCompletionHandler:^(UIImage *image, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(image);
                });
            }];
        }];
        return;
    }
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
