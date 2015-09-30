//
//  OLPhotobookPrintJob.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 23/6/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPhotobookPrintJob.h"
#import "OLProductTemplate.h"
#import "OLAsset.h"

static NSString *const kKeyPhotobookProductTemplateId = @"co.oceanlabs.pssdk.kKeyPhotobookProductTemplateId";
static NSString *const kKeyPhotobookImages = @"co.oceanlabs.pssdk.kKeyPhotobookImages";
static NSString *const kKeyFrontAsset = @"co.oceanlabs.pssdk.kKeyFrontAsset";
static NSString *const kKeyPhotobookAddress = @"co.oceanlabs.pssdk.kKeyPhotobookAddress";
static NSString *const kKeyPhotobookUuid = @"co.oceanlabs.pssdk.kKeyPhotobookUuid";
static NSString *const kKeyPhotobookExtraCopies = @"co.oceanlabs.pssdk.kKeyPhotobookExtraCopies";

@interface OLPhotobookPrintJob ()
@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) NSArray *assets;
@property (strong, nonatomic) NSString *spineColor;
@end

@implementation OLPhotobookPrintJob

@synthesize address;
@synthesize uuid;
@synthesize extraCopies;

- (id)initWithTemplateId:(NSString *)templateId OLAssets:(NSArray/*<OLAssets>*/ *)assets{
    if (self = [super init]){
#ifdef DEBUG
        for (id asset in assets) {
            NSAssert([asset isKindOfClass:[OLAsset class]], @"OLPhotobookPrintJob initWithProduct:OLAssets: requires an NSArray of OLAsset not: %@", [asset class]);
        }
#endif
        
        self.assets = assets;
        self.templateId = templateId;
        self.spineColor = @"#FFFFFF";
    }
    
    return self;
}

#pragma mark - OLPrintJob Protocol

- (NSDictionary *)jsonRepresentation {
    NSMutableArray *pages = [[NSMutableArray alloc] init];
    for (OLAsset *asset in self.assets) {
        [pages addObject:@{
                           @"layout" : @"single_centered",
                           @"asset" : [NSString stringWithFormat:@"%lld", asset.assetId]
                           }];
    }
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    json[@"template_id"] = [OLProductTemplate templateWithId:self.templateId].identifier;
    json[@"assets"] = @{
                        @"front_cover" : self.frontCover ? [NSString stringWithFormat:@"%lld", self.frontCover.assetId] : @"",
//                        @"back_cover" : @"",
                        @"pages" : pages
                        };
    json[@"options"] = @{
                         @"spine_color" : self.spineColor
                         };
    
    return json;
}

- (NSUInteger)quantity {
    return self.assets.count;
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

- (NSString *)productName {
    return [OLProductTemplate templateWithId:self.templateId].name;
}

- (NSArray *)assetsForUploading {
    if (self.frontCover){
        return [self.assets arrayByAddingObject:self.frontCover];
    }
    else{
        return self.assets;
    }
}

- (NSUInteger) hash {
    NSUInteger val = [self.templateId hash];
    val = 39 * val + [self.frontCover hash];
    for (id asset in self.assets) {
        val = 37 * val + [asset hash];
    }
    
    return val;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[OLPhotobookPrintJob class]]) {
        return NO;
    }
    OLPhotobookPrintJob* printJob = (OLPhotobookPrintJob*)object;
    
    return [self.templateId isEqual:printJob.templateId] && [self.assets isEqual:printJob.assets] && [self.frontCover isEqual:printJob.frontCover];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    OLPhotobookPrintJob *objectCopy = [[OLPhotobookPrintJob allocWithZone:zone] init];
    // Copy over all instance variables from self to objectCopy.
    // Use deep copies for all strong pointers, shallow copies for weak.
    objectCopy.assets = self.assets;
    objectCopy.templateId = self.templateId;
    return objectCopy;
}

#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.templateId forKey:kKeyPhotobookProductTemplateId];
    [aCoder encodeObject:self.assets forKey:kKeyPhotobookImages];
    [aCoder encodeObject:self.frontCover forKey:kKeyFrontAsset];
    [aCoder encodeObject:self.uuid forKey:kKeyPhotobookUuid];
    [aCoder encodeInteger:self.extraCopies forKey:kKeyPhotobookExtraCopies];
    [aCoder encodeObject:self.address forKey:kKeyPhotobookAddress];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.templateId = [aDecoder decodeObjectForKey:kKeyPhotobookProductTemplateId];
        self.assets = [aDecoder decodeObjectForKey:kKeyPhotobookImages];
        self.frontCover = [aDecoder decodeObjectForKey:kKeyFrontAsset];
        self.extraCopies = [aDecoder decodeIntegerForKey:kKeyPhotobookExtraCopies];
        self.uuid = [aDecoder decodeObjectForKey:kKeyPhotobookUuid];
        self.address = [aDecoder decodeObjectForKey:kKeyPhotobookAddress];
    }
    
    return self;
}

@end
