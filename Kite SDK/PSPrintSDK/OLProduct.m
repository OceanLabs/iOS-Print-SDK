//
//  OLProduct.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 12/23/14.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLProduct.h"
#import "OLCountry.h"
#import "OLProductTemplate.h"
#import "UIImageView+FadeIn.h"

typedef enum {
    kSizeUnitsInches,
    kSizeUnitsCentimetres
} SizeUnits;

@implementation OLProduct

+(NSArray *)products{
    static NSMutableArray *products = nil;
    NSArray *templates = [OLProductTemplate templates];
    products = [[NSMutableArray alloc] initWithCapacity:[templates count]];
    for (OLProductTemplate *template in templates){
        if (template.enabled){
            OLProduct *product = [[OLProduct alloc] initWithTemplate:template];
            [products addObject: product];
        }
    }
    
    return products;
}

+(NSArray *)productsWithFilters:(NSSet *)templateIds {
    NSArray *products = [self products];
    if (!templateIds || templateIds.count == 0) {
        return products;
    }
    
    NSMutableArray *filteredProducts = [[NSMutableArray alloc] init];
    for (OLProduct *product in products) {
        if ([templateIds containsObject:product.templateId]) {
            [filteredProducts addObject:product];
        }
    }
    return filteredProducts;
}

- (UIColor *)labelColor{
    return self.productTemplate.labelColor;
}

-(NSUInteger)quantityToFulfillOrder{
    return self.productTemplate.quantityPerSheet;
}

-(instancetype)initWithTemplate:(OLProductTemplate *)template{
    self = [super init];
    if (self) {
        _productTemplate = template;
    }
    return self;
}

+(OLProduct *) productWithTemplateId:(NSString *)templateId{
    return [[OLProduct alloc] initWithTemplate:[OLProductTemplate templateWithId:templateId]];
}

-(void)setCoverImageToImageView:(UIImageView *)imageView{
    UIImage *image;
    if ([self.coverPhoto isKindOfClass:[NSString class]]){
        image = [UIImage imageNamed:self.coverPhoto];
    }
    else if ([self.coverPhoto isKindOfClass:[UIImage class]]){
        image = self.coverPhoto;
    }
    
    if (image){
        imageView.image = image;
    }
    else if ([self.coverPhoto isKindOfClass:[NSURL class]]){
        [imageView setAndFadeInImageWithURL:self.coverPhoto];
    }
    else{
        [imageView setAndFadeInImageWithURL:self.productTemplate.coverPhotoURL];
    }
}

-(void)setClassImageToImageView:(UIImageView *)imageView{
    UIImage *image;
    if ([self.coverPhoto isKindOfClass:[NSString class]]){
        image = [UIImage imageNamed:self.coverPhoto];
    }
    else if ([self.coverPhoto isKindOfClass:[UIImage class]]){
        image = self.coverPhoto;
    }
    
    if (image){
        imageView.image = image;
    }
    else if ([self.coverPhoto isKindOfClass:[NSURL class]]){
        [imageView setAndFadeInImageWithURL:self.coverPhoto];
    }
    else{
        OLProductTemplate *template = self.productTemplate;
        if (template.classPhotoURL && ![[template.classPhotoURL absoluteString] isEqualToString:@""]){
            [imageView setAndFadeInImageWithURL:self.productTemplate.classPhotoURL];
        }
        else{
            [imageView setAndFadeInImageWithURL:self.productTemplate.coverPhotoURL];
        }
        
    }
}

-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView{
    UIImage *image;
    if ([self.productPhotos[i] isKindOfClass:[NSString class]]){
        image = [UIImage imageNamed:self.productPhotos[i]];
    }
    else if ([self.productPhotos[i] isKindOfClass:[UIImage class]]){
        image = self.productPhotos[i];
    }
    
    if (image){
        [imageView setImage:image];
    }
    else if ([self.productPhotos[i] isKindOfClass:[NSURL class]]){
        [imageView setAndFadeInImageWithURL:self.productPhotos[i]];
    }
    else{
        [imageView setAndFadeInImageWithURL:self.productTemplate.productPhotographyURLs[i % [self.productTemplate.productPhotographyURLs count]]];
    }
}

#pragma mark Product Info

+ (NSString*) unitCostWithCost:(NSDecimalNumber*)cost{
    NSString *code = [OLCountry countryForCurrentLocale].currencyCode;
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setCurrencyCode:code];
    return [formatter stringFromNumber:cost];
}

- (NSString *)unitCost {
    return [OLProduct unitCostWithCost:[self unitCostDecimalNumber]];
    
}

- (NSDecimalNumber*) unitCostDecimalNumber{
    OLProductTemplate *template = [OLProductTemplate templateWithId:self.templateId];
    
    NSString *code = [OLCountry countryForCurrentLocale].currencyCode;
    if (![template.currenciesSupported containsObject:code]) {
        if ([template.currenciesSupported containsObject:@"GBP"]) {
            code = @"GBP";
        } else {
            code = [template.currenciesSupported firstObject];
        }
    }
    
    NSDecimalNumber *sheetCost = [template costPerSheetInCurrencyCode:code];
    NSUInteger sheetQuanity = template.quantityPerSheet == 0 ? 1 : template.quantityPerSheet;
    NSUInteger numSheets = (NSUInteger) ceil(self.quantityToFulfillOrder / sheetQuanity);
    NSDecimalNumber *unitCost = [sheetCost decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%lu", (unsigned long)numSheets]]];
    return unitCost;
}

- (NSString *)templateId {
    return self.productTemplate.identifier;
}

- (NSString *) packInfo{
    if (self.productTemplate.templateUI == kOLTemplateUIFrame || self.productTemplate.templateUI == kOLTemplateUIFrame || self.quantityToFulfillOrder == 1){
        return @"";
    }
    NSString* packOfString = NSLocalizedString(@"PACK OF", @"Example pack of 22");
    return [packOfString stringByAppendingFormat:@" %lu", (unsigned long)self.quantityToFulfillOrder];
}

- (CGSize) dimensionsInInches{
    return self.productTemplate.sizeInches;
}

- (CGSize) dimensionsInCentimetres{
    return self.productTemplate.sizeCm;
}

- (NSString *) dimensionsInUnits:(SizeUnits)sizeUnits{
    CGSize dimensions;
    NSString* unitsName;
    switch (sizeUnits) {
        case kSizeUnitsCentimetres:
            dimensions = [self dimensionsInCentimetres];
            unitsName = @"cm";
            break;
        case kSizeUnitsInches:
            dimensions = [self dimensionsInInches];
            unitsName = NSLocalizedString(@"INCHES", "");
            break;
        default:
            break;
    }
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    [nf setLocale:[NSLocale currentLocale]];
    [nf setMaximumFractionDigits:1];
    
    return [NSString stringWithFormat:@"%@ X %@ %@", [nf stringFromNumber:[NSNumber numberWithDouble:dimensions.width]], [nf stringFromNumber:[NSNumber numberWithDouble:dimensions.height]], unitsName];
}

- (NSString *) dimensions{
    NSLocale *locale = [NSLocale currentLocale];
    BOOL isMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue] && ![[locale objectForKey:NSLocaleCountryCode] isEqualToString:@"GB"];
    return isMetric ? [self dimensionsInUnits:kSizeUnitsCentimetres] : [self dimensionsInUnits:kSizeUnitsInches];
}



-(NSArray *)productPhotos{
    if (_productPhotos){
        return _productPhotos;
    }
    else{
        return self.productTemplate.productPhotographyURLs;
    }
}

- (NSString *)description{
    return [self.productTemplate description];
}



@end
