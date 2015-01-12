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
#import <UIImageView+WebCache.h>

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
    if ([self.coverImage isKindOfClass:[NSString class]]){
        image = [UIImage imageNamed:self.coverImage];
    }
    else if ([self.coverImage isKindOfClass:[UIImage class]]){
        image = self.coverImage;
    }
    
    if (image){
        imageView.image = image;
    }
    else if ([self.coverImage isKindOfClass:[NSURL class]]){
        [imageView sd_setImageWithPreviousCachedImageWithURL:self.coverImage andPlaceholderImage:nil options:SDWebImageRetryFailed progress:NULL completed:NULL];
    }
    else{
        [imageView sd_setImageWithPreviousCachedImageWithURL:self.productTemplate.coverImageURL andPlaceholderImage:nil options:SDWebImageRetryFailed progress:NULL completed:NULL];
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
        [imageView sd_setImageWithPreviousCachedImageWithURL:self.productPhotos[i] andPlaceholderImage:nil options:SDWebImageRetryFailed progress:NULL completed:NULL];
    }
    else{
        [imageView sd_setImageWithPreviousCachedImageWithURL:self.productTemplate.productsPhotoURLs[i % [self.productTemplate.productsPhotoURLs count]] andPlaceholderImage:nil options:SDWebImageRetryFailed progress:NULL completed:NULL];
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
            case kOLTemplateTypePostcard: return [UIColor colorWithRed:203.0/255.0 green:86.0/255.0 blue:157.0/255 alpha:1.0];
            case kOLTemplateTypeMiniPolaroids:return [UIColor colorWithRed:59.0/255.0 green:115.0/255.0 blue:211.0/255 alpha:1.0];
            case kOLTemplateTypePolaroids: return [UIColor colorWithRed:66.0/255.0 green:179.0/255.0 blue:227.0/255 alpha:1.0];
            case kOLTemplateTypeFrame2x2: return [UIColor colorWithRed:254.0/255.0 green:197.0/255.0 blue:68.0/255 alpha:1.0];
            case kOLTemplateTypeFrame3x3: return [UIColor colorWithRed:254.0/255.0 green:197.0/255.0 blue:68.0/255 alpha:1.0];
            case kOLTemplateTypeFrame4x4: return [UIColor colorWithRed:254.0/255.0 green:197.0/255.0 blue:68.0/255 alpha:1.0];
                return [UIColor clearColor];
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
        case kOLTemplateTypePostcard: return CGSizeMake(5.8, 4.1);
#warning todo
        case kOLTemplateTypeLargeFormatA1: return CGSizeMake(0, 0);
        case kOLTemplateTypeLargeFormatA2: return CGSizeMake(0, 0);
        case kOLTemplateTypeLargeFormatA3: return CGSizeMake(0, 0);
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
        case kOLTemplateTypePostcard: return CGSizeMake(14.9, 10.5);
#warning todo
        case kOLTemplateTypeLargeFormatA1: return CGSizeMake(0, 0);
        case kOLTemplateTypeLargeFormatA2: return CGSizeMake(0, 0);
        case kOLTemplateTypeLargeFormatA3: return CGSizeMake(0, 0);
            default: CGSizeMake(0, 0);
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

-(OLTemplateType)templateType{
    if ([[self templateId] isEqualToString:kOLDefaultTemplateForFrames2x2]){
        return kOLTemplateTypeFrame2x2;
    }
    else if ([[self templateId] isEqualToString:kOLDefaultTemplateForFrames3x3]){
        return kOLTemplateTypeFrame3x3;
    }
    else if ([[self templateId] isEqualToString:kOLDefaultTemplateForFrames4x4]){
        return kOLTemplateTypeFrame4x4;
    }
    else if ([[self templateId] isEqualToString:kOLDefaultTemplateForMagnets]){
        return kOLTemplateTypeMagnets;
    }
    else if ([[self templateId] isEqualToString:kOLDefaultTemplateForSquarePrints]){
        return kOLTemplateTypeSquares;
    }
    else if ([[self templateId] isEqualToString:kOLDefaultTemplateForSquareMiniPrints]){
        return kOLTemplateTypeMiniSquares;
    }
    else if ([[self templateId] isEqualToString:kOLDefaultTemplateForPolaroidStylePrints]){
        return kOLTemplateTypePolaroids;
    }
    else if ([[self templateId] isEqualToString:kOLDefaultTemplateForPolaroidStyleMiniPrints]){
        return kOLTemplateTypeMiniPolaroids;
    }
    else if ([[self templateId] isEqualToString:kOLDefaultTemplateForLargeFormatA1]){
        return kOLTemplateTypeLargeFormatA1;
    }
    else if ([[self templateId] isEqualToString:kOLDefaultTemplateForLargeFormatA2]){
        return kOLTemplateTypeLargeFormatA2;
    }
    else if ([[self templateId] isEqualToString:kOLDefaultTemplateForLargeFormatA3]){
        return kOLTemplateTypeLargeFormatA3;
    }
    else if ([[self templateId] isEqualToString:kOLDefaultTemplateForPostcard] || [[self templateId] isEqualToString:kOLDefaultTemplateForPsPostcard] || [[self templateId] isEqualToString:kOLDefaultTemplateFor60Postcard]){
        return kOLTemplateTypePostcard;
    }
    NSAssert(NO, @"Unrecognized template: %@", [self templateId]);
    return -1;
}

-(NSArray *)productPhotos{
    if (_productPhotos){
        return _productPhotos;
    }
    else{
        return self.productTemplate.productsPhotoURLs;
    }
}



@end
