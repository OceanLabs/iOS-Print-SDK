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
    if (!products) {
        NSArray *templates = [OLProductTemplate templates];
        products = [[NSMutableArray alloc] initWithCapacity:[templates count]];
        for (OLProductTemplate *template in templates){
            if (template.enabled){
                [products addObject:[[OLProduct alloc] initWithTemplate:template]];
            }
        }
    }
    
    return products;
}

-(CGSize)serverImageSize{
    CGFloat pointsToPixels = 1.38;
    if (self.templateType == kOLTemplateTypeLargeFormatA1){
            return CGSizeMake(1564.724409288 * pointsToPixels, 2264.881889531 * pointsToPixels);
    }
    else if (self.templateType == kOLTemplateTypeLargeFormatA2){
        return CGSizeMake(1088.503936896 * pointsToPixels, 1581.732283302 * pointsToPixels);
    }
    else if (self.templateType == kOLTemplateTypeLargeFormatA3){
        return CGSizeMake(785.196850313 * pointsToPixels, 1133.8582676 * pointsToPixels);
    }
    else if (self.templateType == kOLTemplateTypePolaroids){
            return CGSizeMake(945, 945);
    }
    else if (self.templateType == kOLTemplateTypeSquares){
        return CGSizeMake(1111, 1111);
    }
    else if (self.templateType == kOLTemplateTypeMagnets){
        return CGSizeMake(733, 733);
    }
    else if (self.templateType == kOLTemplateTypeMiniSquares){
        return CGSizeMake(750, 750);
    }
    else if (self.templateType == kOLTemplateTypeStickersSquare){
        return CGSizeMake(702, 702);
    }
    else if (self.templateType == kOLTemplateTypeStickersCircle){
        return CGSizeMake(748, 748);
    }
    else if (self.templateType == kOLTemplateTypeMiniPolaroids){
        return CGSizeMake(656, 656);
    }
    else if (self.templateType == kOLTemplateTypeFrame || self.templateType == kOLTemplateTypeFrame2x2 || self.templateType == kOLTemplateTypeFrame3x3 || self.templateType == kOLTemplateTypeFrame4x4){
        return CGSizeMake(1651, 1651);
    }
    else{
        return CGSizeMake(0, 0);
    }

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
        [imageView setAndFadeInImageWithURL:self.productTemplate.coverImageURL];
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
        [imageView setAndFadeInImageWithURL:self.productTemplate.productsPhotoURLs[i % [self.productTemplate.productsPhotoURLs count]]];
    }
}

-(UIColor *)labelColor{
    if (_labelColor){
        return _labelColor;
    }
    else{
        switch (self.templateType) {
            case kOLTemplateTypeMagnets: return [UIColor colorWithRed:243.0/255.0 green:174.0/255.0 blue:52.0/255 alpha:1.0];
            case kOLTemplateTypeMiniSquares: return [UIColor colorWithRed:50.0/255.0 green:159.0/255.0 blue:209.0/255 alpha:1.0];
            case kOLTemplateTypeSquares: return [UIColor colorWithRed:48.0/255.0 green:177.0/255.0 blue:137.0/255 alpha:1.0];
            case kOLTemplateTypeLargeFormatA1: return [UIColor colorWithRed:203.0/255.0 green:86.0/255.0 blue:157.0/255 alpha:1.0];
            case kOLTemplateTypeLargeFormatA2: return [UIColor colorWithRed:203.0/255.0 green:86.0/255.0 blue:157.0/255 alpha:1.0];
            case kOLTemplateTypeLargeFormatA3: return [UIColor colorWithRed:203.0/255.0 green:86.0/255.0 blue:157.0/255 alpha:1.0];
            case kOLTemplateTypeStickersSquare: return [UIColor colorWithRed:55.0/255.0 green:188.0/255.0 blue:155.0/255 alpha:1.0];
            case kOLTemplateTypeStickersCircle: return [UIColor colorWithRed:79.0/255.0 green:193.0/255.0 blue:233.0/255 alpha:1.0];
            case kOLTemplateTypePostcard: return [UIColor colorWithRed:203.0/255.0 green:86.0/255.0 blue:157.0/255 alpha:1.0];
            case kOLTemplateTypeMiniPolaroids:return [UIColor colorWithRed:59.0/255.0 green:115.0/255.0 blue:211.0/255 alpha:1.0];
            case kOLTemplateTypePolaroids: return [UIColor colorWithRed:66.0/255.0 green:179.0/255.0 blue:227.0/255 alpha:1.0];
            case kOLTemplateTypeFrame: return [UIColor colorWithRed:254.0/255.0 green:197.0/255.0 blue:68.0/255 alpha:1.0];
            default: return nil;
        }
    }
}

- (NSUInteger) quantityToFulfillOrder{
    if (self.templateType == kOLTemplateTypeFrame4x4){
        return 16;
    }
    else if (self.templateType == kOLTemplateTypeFrame3x3){
        return 9;
    }
    else if (self.templateType == kOLTemplateTypeFrame2x2){
        return 4;
    }
    else if (self.templateType == kOLTemplateTypeFrame){
        return 1;
    }
    
    OLProductTemplate *template = [OLProductTemplate templateWithId:self.templateId];
    return template.quantityPerSheet == 0 ? 1 : template.quantityPerSheet;
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
    return [OLProduct unitCostWithCost:[self decimalNumberUnitCost]];
    
}

- (NSDecimalNumber*) decimalNumberUnitCost{
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
    if ([[self templateId] hasSuffix:@"_poster"] || [[self templateId] hasPrefix:@"frames_"]){
        return @"";
    }
    NSString* packOfString = NSLocalizedString(@"PACK OF", @"Example pack of 22");
    return [packOfString stringByAppendingFormat:@" %lu", (unsigned long)self.quantityToFulfillOrder];
}

- (CGSize) dimensionsInInches{
    switch (self.templateType) {
        case kOLTemplateTypeMagnets: return CGSizeMake(2.4, 2.4);
        case kOLTemplateTypeMiniSquares: return CGSizeMake(2.5, 2.5);
        case kOLTemplateTypeSquares: return CGSizeMake(3.7, 3.7);
        case kOLTemplateTypeMiniPolaroids:return CGSizeMake(2.5, 2.1);
        case kOLTemplateTypePolaroids: return CGSizeMake(3.7, 3.1);
        case kOLTemplateTypeFrame2x2: return CGSizeMake(19.6, 19.6);
        case kOLTemplateTypeFrame3x3: return CGSizeMake(19.6, 19.6);
        case kOLTemplateTypeFrame4x4: return CGSizeMake(19.6, 19.6);
        case kOLTemplateTypeFrame: return CGSizeMake(19.6, 19.6);
        case kOLTemplateTypePostcard: return CGSizeMake(5.8, 4.1);
        case kOLTemplateTypeLargeFormatA1: return CGSizeMake(23.4, 33.1);
        case kOLTemplateTypeLargeFormatA2: return CGSizeMake(16.5, 23.4);
        case kOLTemplateTypeLargeFormatA3: return CGSizeMake(11.7, 16.5);
        case kOLTemplateTypeStickersCircle: return CGSizeMake(2.6, 2.6);
        case kOLTemplateTypeStickersSquare: return CGSizeMake(2.4, 2.4);
            default: return CGSizeMake(0, 0);
    }
}

- (CGSize) dimensionsInCentimetres{
    switch (self.templateType) {
        case kOLTemplateTypeMagnets: return CGSizeMake(6.9, 6.9);
        case kOLTemplateTypeMiniSquares: return CGSizeMake(6.8, 6.8);
        case kOLTemplateTypeSquares: return CGSizeMake(9.8, 9.8);
        case kOLTemplateTypeMiniPolaroids:return CGSizeMake(6.2, 7.1);
        case kOLTemplateTypePolaroids: return CGSizeMake(8.7, 10);
        case kOLTemplateTypeFrame2x2: return CGSizeMake(50, 50);
        case kOLTemplateTypeFrame3x3: return CGSizeMake(50, 50);
        case kOLTemplateTypeFrame4x4: return CGSizeMake(50, 50);
        case kOLTemplateTypeFrame: return CGSizeMake(50, 50);
        case kOLTemplateTypePostcard: return CGSizeMake(14.9, 10.5);
        case kOLTemplateTypeLargeFormatA1: return CGSizeMake(594, 841);
        case kOLTemplateTypeLargeFormatA2: return CGSizeMake(420, 594);
        case kOLTemplateTypeLargeFormatA3: return CGSizeMake(297, 420);
        case kOLTemplateTypeStickersCircle: return CGSizeMake(6.59, 6.59);
        case kOLTemplateTypeStickersSquare: return CGSizeMake(6.19, 6.19);
            default: return CGSizeMake(0, 0);
    }
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
        return self.productTemplate.productsPhotoURLs;
    }
}

-(OLTemplateType)templateType{
    return [OLProductTemplate templateTypeWithIdentifier:self.templateId];
}



@end
