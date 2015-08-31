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
#import "NSDecimalNumber+CostFormatter.h"
#import "OLKiteABTesting.h"

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

+(NSArray *)productsWithFilters:(NSArray *)templateIds {
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

- (NSString *)currencyCode {
    NSString *code = [OLCountry countryForCurrentLocale].currencyCode;
    OLProductTemplate *template = [OLProductTemplate templateWithId:self.templateId];
    if (![template.currenciesSupported containsObject:code]) {
        // preferred currency fallback order if users local currency isn't supported: USD, GBP, EUR
        if ([template.currenciesSupported containsObject:@"USD"]) {
            code = @"USD";
        } else if ([template.currenciesSupported containsObject:@"GBP"]) {
            code = @"GBP";
        } else if ([template.currenciesSupported containsObject:@"EUR"]) {
            code = @"EUR";
        }
    }
    
    return code;
}

- (NSString *)unitCost {
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setCurrencyCode:[self currencyCode]];
    return [formatter stringFromNumber:[self unitCostDecimalNumber]];
}

- (NSDecimalNumber*) unitCostDecimalNumber {
    OLProductTemplate *template = [OLProductTemplate templateWithId:self.templateId];
    
    NSDecimalNumber *sheetCost = [template costPerSheetInCurrencyCode:[self currencyCode]];
    NSUInteger sheetQuanity = template.quantityPerSheet == 0 ? 1 : template.quantityPerSheet;
    NSUInteger numSheets = (NSUInteger) ceil(self.quantityToFulfillOrder / sheetQuanity);
    NSDecimalNumber *unitCost = [sheetCost decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%lu", (unsigned long)numSheets]]];
    return unitCost;
}

- (NSString *)templateId {
    return self.productTemplate.identifier;
}

- (NSString *) packInfo{
    if (self.productTemplate.templateUI == kOLTemplateUIFrame || self.productTemplate.templateUI == kOLTemplateUIPoster || self.productTemplate.templateUI == kOLTemplateUIPostcard || self.productTemplate.templateUI == kOLTemplateUIPhotobook || self.quantityToFulfillOrder == 1 || self.quantityToFulfillOrder == 0){
        return @"";
    }
    NSString* packOfString = NSLocalizedString(@"Pack of", @"Example pack of 22");
    return [packOfString stringByAppendingFormat:@" %lu\n", (unsigned long)self.quantityToFulfillOrder];
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
            unitsName = NSLocalizedString(@"inches", "");
            break;
        default:
            break;
    }
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    [nf setLocale:[NSLocale currentLocale]];
    [nf setMaximumFractionDigits:1];
    
    return [NSString stringWithFormat:@"%@ x %@ %@", [nf stringFromNumber:[NSNumber numberWithDouble:dimensions.width]], [nf stringFromNumber:[NSNumber numberWithDouble:dimensions.height]], unitsName];
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

- (NSString *)detailsString{
    NSString *s = @"";
    
    //Add description
    if (self.productTemplate.productDescription && ![self.productTemplate.productDescription isEqualToString:@""]){
        s = [s stringByAppendingString:[NSString stringWithFormat:@"**Description**\n%@\n\n", self.productTemplate.productDescription]];
    }
    
    //Add size info
    OLTemplateUI templateClass = self.productTemplate.templateUI;
    if (templateClass != kOLTemplateUICase){
        s = [s stringByAppendingString:[NSString stringWithFormat:@"**Size**\n%@\n\n", self.dimensions]];
    }
    
    //Add qty info
    if (self.packInfo && ![self.packInfo isEqualToString:@""]){
        s = [s stringByAppendingString:[NSString stringWithFormat:@"**Quantity**\n%lu\n\n", (unsigned long)self.quantityToFulfillOrder]];
    }
    
    //Add price info
    if ([OLKiteABTesting sharedInstance].hidePrice){
        s = [s stringByAppendingString:[NSString stringWithFormat:@"**Price**\n%@\n\n", self.unitCost]];
    }
    
    //Add shipping info
    NSDecimalNumber *shippingCost = [self.productTemplate shippingCostForCountry:[OLCountry countryForCurrentLocale]];
    if (shippingCost && [shippingCost doubleValue] != 0){
        if (![OLKiteABTesting sharedInstance].hidePrice){
            s = [s stringByAppendingString: [NSString stringWithFormat:NSLocalizedString(@"**Shipping**\n%@\n\n", @""), [shippingCost formatCostForCurrencyCode:[self.productTemplate currencyForCurrentLocale]]]];
        }
    }
    else if (!shippingCost){ // ¯\_(ツ)_/¯ don't assume 0, don't add any shipping info
    }
    else{
        s = [s stringByAppendingString:NSLocalizedString(@"**Shipping**\nFREE\n\n", @"")];
    }
    
    //Add quality guarantee
    s = [s stringByAppendingString:NSLocalizedString(@"**Quality Guarantee**\nOur products are of the highest quality and we’re confident you will love yours. If not, we offer a no quibble money back guarantee. Enjoy!", @"")];
    return s;
}



@end