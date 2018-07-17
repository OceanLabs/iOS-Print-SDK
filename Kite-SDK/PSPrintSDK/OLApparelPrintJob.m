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

#import "OLApparelPrintJob.h"
#import "OLProductTemplate.h"
#import "OLAsset+Private.h"
#import "OLImageDownloader.h"

static NSString *const kKeyApparelProductTemplateId = @"co.oceanlabs.pssdk.kKeyApparelProductTemplateId";
static NSString *const kKeyApparelImages = @"co.oceanlabs.pssdk.kKeyApparelImages";
static NSString *const kKeyFrontAsset = @"co.oceanlabs.pssdk.kKeyFrontAsset";
static NSString *const kKeyBackAsset = @"co.oceanlabs.pssdk.kKeyBackAsset";
static NSString *const kKeyApparelAddress = @"co.oceanlabs.pssdk.kKeyApparelAddress";
static NSString *const kKeyApparelUuid = @"co.oceanlabs.pssdk.kKeyApparelUuid";
static NSString *const kKeyApparelExtraCopies = @"co.oceanlabs.pssdk.kKeyApparelExtraCopies";
static NSString *const kKeyApparelPrintJobOptions = @"co.oceanlabs.pssdk.kKeyApparelPrintJobOptions";
static NSString *const kKeyDateAddedToBasket = @"co.oceanlabs.pssdk.kKeyDateAddedToBasket";

@interface OLApparelPrintJob ()
@property (nonatomic, strong) NSString *templateId;
@property (strong, nonatomic) NSMutableDictionary *options;
@end

@implementation OLApparelPrintJob

@synthesize uuid;
@synthesize extraCopies;
@synthesize dateAddedToBasket;

- (NSMutableDictionary *) options{
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
        self.selectedShippingMethod = self.template.availableShippingMethods.firstObject;
    }
    
    return self;
}

#pragma mark - OLPrintJob Protocol

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *pdfs = [[NSMutableDictionary alloc] init];
    
    json[@"template_id"] = self.templateId;
    
    NSMutableDictionary *assets = [[NSMutableDictionary alloc] init];
    for (NSString *key in [self.assets allKeys]){
        if ([self.assets[key] mimeType] == kOLMimeTypePDF){
            [pdfs setObject:[NSString stringWithFormat:@"%lld", [self.assets[key] assetId]] forKey:key];
        }
        else{
            [assets setObject:[NSString stringWithFormat:@"%lld", [self.assets[key] assetId]] forKey:key];
        }
    }
    if (pdfs.allKeys.count > 0){
        json[@"pdf"] = pdfs[pdfs.allKeys.firstObject];
    }
    json[@"assets"] = assets;
    json[@"options"] = self.options;
    json[@"job_id"] = [self uuid];
    json[@"multiples"] = [NSNumber numberWithInteger:self.extraCopies + 1];
    
    return json;
}

- (NSUInteger)quantity {
    return 1;
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
    
    if (![object isKindOfClass:[OLApparelPrintJob class]]) {
        return NO;
    }
    OLApparelPrintJob* printJob = (OLApparelPrintJob*)object;
    
    return [self.templateId isEqual:printJob.templateId] && [self.assets isEqualToDictionary:printJob.assets] && [self.options isEqualToDictionary:printJob.options];
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
    [aCoder encodeObject:self.options forKey:kKeyApparelPrintJobOptions];
    [aCoder encodeObject:self.dateAddedToBasket forKey:kKeyDateAddedToBasket];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.templateId = [aDecoder decodeObjectForKey:kKeyApparelProductTemplateId];
        self.assets = [aDecoder decodeObjectForKey:kKeyApparelImages];
        self.extraCopies = [aDecoder decodeIntegerForKey:kKeyApparelExtraCopies];
        self.uuid = [aDecoder decodeObjectForKey:kKeyApparelUuid];
        self.options = [aDecoder decodeObjectForKey:kKeyApparelPrintJobOptions];
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
