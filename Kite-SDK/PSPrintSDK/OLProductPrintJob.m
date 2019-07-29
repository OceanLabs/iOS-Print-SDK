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

#import "OLProductPrintJob.h"
#import "OLAsset+Private.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLImageDownloader.h"
#import "OLCountry.h"

static NSString *const kKeyProductTemplateId = @"co.oceanlabs.pssdk.kKeyProductTemplateId";
static NSString *const kKeyImages = @"co.oceanlabs.pssdk.kKeyImages";
static NSString *const kKeyUUID = @"co.oceanlabs.pssdk.kKeyUUID";
static NSString *const kKeyExtraCopies = @"co.oceanlabs.pssdk.kKeyExtraCopies";
static NSString *const kKeyTemplateShippingMethods = @"co.oceanlabs.pssdk.kKeyTemplateShippingMethods";
static NSString *const kKeyTemplateCountryToRegionMapping = @"co.oceanlabs.pssdk.kKeyTemplateCountryToRegionMapping";
static NSString *const kKeyProductPringJobAddress = @"co.oceanlabs.pssdk.kKeyProductPringJobAddress";
static NSString *const kKeyProductPrintJobOptions = @"co.oceanlabs.pssdk.kKeyProductPrintJobOptions";

@interface OLProductPrintJob ()
@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) NSArray *assetsForUploading;
@property (nonatomic, strong) NSArray<PhotobookAsset *> *assetsToUpload;
@property (strong, nonatomic) NSMutableDictionary *options;
@end

@implementation OLProductPrintJob

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
        self.assetsForUploading = assets;
        self.assetsToUpload = [OLAsset photobookAssetsFromAssets:assets];
        self.templateId = templateId;
        
        NSString *countryCode = [OLCountry countryForCurrentLocale].codeAlpha3;
        self.selectedShippingMethod = self.template.availableShippingMethods[countryCode].firstObject;
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
        self.assetsForUploading = assets;
        self.assetsToUpload = [OLAsset photobookAssetsFromAssets:assets];
        self.templateId = templateId;
        
        NSString *countryCode = [OLCountry countryForCurrentLocale].codeAlpha3;
        self.selectedShippingMethod = self.template.availableShippingMethods[countryCode].firstObject;
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
        self.assetsForUploading = assets;
        self.assetsToUpload = [OLAsset photobookAssetsFromAssets:assets];
        self.templateId = templateId;
        
        NSString *countryCode = [OLCountry countryForCurrentLocale].codeAlpha3;
        self.selectedShippingMethod = self.template.availableShippingMethods[countryCode].firstObject;
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
    if ([OLProductTemplate templateWithId:self.templateId].templateUI == OLTemplateUINonCustomizable){
        return 1;
    }
    NSInteger count = 0;
    for (OLAsset *asset in self.assetsForUploading) {
        count += asset.extraCopies + 1;
    }
    return count;
}

- (NSString *)templateId {
    return _templateId;
}

- (NSArray *)currenciesSupported {
    return [OLProductTemplate templateWithId:self.templateId].currenciesSupported;
}

- (NSDictionary *)jsonRepresentation {
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    NSMutableArray *pdfs = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0; i < self.assetsForUploading.count; i++) {
        OLAsset *asset = self.assetsForUploading[i];
//        if (asset.mimeType == kOLMimeTypePDF){
//            [pdfs addObject:[NSString stringWithFormat:@"%lld", asset.assetId]];
//        }
//        else{
        for (NSInteger j = 0; j <= asset.extraCopies; j++) {
            if (i < self.assetsToUpload.count && self.assetsToUpload[i].uploadUrl) {
                [assets addObject:self.assetsToUpload[i].uploadUrl];
            } else {
                [assets addObject:@(asset.assetId)];
            }
        }
//        }
    }
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    json[@"template_id"] = self.templateId;
    json[@"assets"] = assets;
    if (pdfs.count > 0){
        json[@"pdf"] = [pdfs firstObject];
    }

    if (self.options != nil && self.options.count > 0) {
        json[@"options"] = self.options;
    }
    
    json[@"job_id"] = [self uuid];
    json[@"multiples"] = [NSNumber numberWithInteger:self.extraCopies + 1];
    json[@"shipping_class"] = [NSNumber numberWithInteger:selectedShippingMethod.id];
    
    return json;
}

- (id)copyWithZone:(NSZone *)zone {
    OLProductPrintJob *objectCopy = [[OLProductPrintJob allocWithZone:zone] init];
    // Copy over all instance variables from self to objectCopy.
    // Use deep copies for all strong pointers, shallow copies for weak.
    objectCopy.assetsForUploading = self.assetsForUploading;
    objectCopy.templateId = self.templateId;
    objectCopy.uuid = self.uuid;
    objectCopy.extraCopies = self.extraCopies;
    objectCopy.options = self.options;
    objectCopy.selectedShippingMethod = self.selectedShippingMethod;
    return objectCopy;
}

- (NSUInteger) hash {
    NSUInteger val = [self.templateId hash];
    for (id asset in self.assetsForUploading) {
        val = 37 * val + [asset hash];
    }
    
    val = 38 * val + self.extraCopies;
    
    for (NSString *key in self.options.allKeys){
        val = 39 * val + [self.options[key] hash] + [key hash];
    }
    
    val = 41 * val + [self.uuid hash];

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
    
    return [self.templateId isEqual:printJob.templateId] && [self.assetsForUploading isEqualToArray:printJob.assetsForUploading] && [self.options isEqualToDictionary:printJob.options] && (!self.selectedShippingMethod || [self.selectedShippingMethod isEqual:printJob.selectedShippingMethod]);
}


#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.templateId forKey:kKeyProductTemplateId];
    [aCoder encodeObject:self.template.availableShippingMethods forKey:kKeyTemplateShippingMethods];
    [aCoder encodeObject:self.template.countryToRegionMapping forKey:kKeyTemplateCountryToRegionMapping];
    [aCoder encodeObject:self.assetsForUploading forKey:kKeyImages];
    [aCoder encodeObject:self.uuid forKey:kKeyUUID];
    [aCoder encodeInteger:self.extraCopies forKey:kKeyExtraCopies];
    [aCoder encodeObject:self.options forKey:kKeyProductPrintJobOptions];
    [aCoder encodeObject:self.selectedShippingMethod forKey:@"selectedShippingMethod"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.templateId = [aDecoder decodeObjectForKey:kKeyProductTemplateId];
        if (!self.template) {
            return nil;
        }
        self.template.availableShippingMethods = [aDecoder decodeObjectForKey:kKeyTemplateShippingMethods];
        self.template.countryToRegionMapping = [aDecoder decodeObjectForKey:kKeyTemplateCountryToRegionMapping];
        self.assetsForUploading = [aDecoder decodeObjectForKey:kKeyImages];
        self.assetsToUpload = [OLAsset photobookAssetsFromAssets:self.assetsForUploading];
        self.uuid = [aDecoder decodeObjectForKey:kKeyUUID];
        self.extraCopies = [aDecoder decodeIntegerForKey:kKeyExtraCopies];
        self.options = [aDecoder decodeObjectForKey:kKeyProductPrintJobOptions];
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
