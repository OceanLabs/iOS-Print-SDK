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

@interface OLProductPrintJob ()
@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) NSArray *assets;
@end

@implementation OLProductPrintJob

- (id)initWithTemplateId:(NSString *)templateId imageFilePaths:(NSArray/*<NSString>*/ *)imageFilePaths {
    if (self = [super init]) {
        NSMutableArray *assets = [[NSMutableArray alloc] init];
        for (id imagePath in imageFilePaths) {
            NSAssert([imagePath isKindOfClass:[NSString class]], @"OLProductPrintJob initWithProduct:imageFilePaths: requires an NSArray of NSString not: %@", [imagePath class]);
            [assets addObject:[OLAsset assetWithFilePath:imagePath]];
        }
        
        self.assets = assets;
        self.templateId = templateId;
    }
    
    return self;
}

- (id)initWithTemplateId:(NSString *)templateId images:(NSArray/*<UIImage>*/ *)images {
    if (self = [super init]) {
        NSMutableArray *assets = [[NSMutableArray alloc] init];
        for (id image in images) {
            NSAssert([image isKindOfClass:[UIImage class]], @"OLProductPrintJob initWithProduct:images: requires an NSArray of UIImage not: %@", [image class]);
            [assets addObject:[OLAsset assetWithImageAsJPEG:image]];
        }
        
        self.assets = assets;
        self.templateId = templateId;
    }
    
    return self;
}

- (id)initWithTemplateId:(NSString *)templateId OLAssets:(NSArray/*<OLAssets>*/ *)assets {
    if (self = [super init]) {
        for (id asset in assets) {
            NSAssert([asset isKindOfClass:[OLAsset class]], @"OLProductPrintJob initWithProduct:OLAssets: requires an NSArray of OLAsset not: %@", [asset class]);
        }
        
        self.assets = assets;
        self.templateId = templateId;
    }
    
    return self;
}

- (id)initWithTemplateId:(NSString *)templateId dataSources:(NSArray/*<id<OLAssetDataSource> >*/ *)dataSources {
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
    OLProductTemplate *template = [OLProductTemplate templateWithId:self.templateId];
    NSUInteger expectedQuantity = template.quantityPerSheet;
    NSDecimalNumber *cost = [template costPerSheetInCurrencyCode:currencyCode];
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
    
    return json;
}

- (id)copyWithZone:(NSZone *)zone {
    OLProductPrintJob *objectCopy = [[OLProductPrintJob allocWithZone:zone] init];
    // Copy over all instance variables from self to objectCopy.
    // Use deep copies for all strong pointers, shallow copies for weak.
    objectCopy.assets = self.assets;
    objectCopy.templateId = self.templateId;
    return objectCopy;
}

- (NSUInteger) hash {
    NSUInteger val = [self.templateId hash];
    for (id asset in self.assets) {
        val = 37 * val + [asset hash];
    }

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
    
    return [self.templateId isEqual:printJob.templateId] && [self.assets isEqual:printJob.assets];
}


#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.templateId forKey:kKeyProductTemplateId];
    [aCoder encodeObject:self.assets forKey:kKeyImages];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.templateId = [aDecoder decodeObjectForKey:kKeyProductTemplateId];
        self.assets = [aDecoder decodeObjectForKey:kKeyImages];
    }
    
    return self;
}


@end
