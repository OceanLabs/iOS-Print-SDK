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

#import "OLProduct.h"
#import "OLProductTemplate.h"
#import "UIImageView+FadeIn.h"
#import "NSDecimalNumber+CostFormatter.h"
#import "OLKiteABTesting.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLProductTemplateOption.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLUserSession.h"
#import "OLCountry.h"

typedef enum {
    kSizeUnitsInches,
    kSizeUnitsCentimetres
} SizeUnits;

@interface OLKitePrintSDK (Private)

+ (NSString *)qualityGuaranteeString;

@end

@implementation OLProduct

+(NSArray *)products{
    static NSMutableArray *products = nil;
    NSArray *templates = [OLProductTemplate templates];
    products = [[NSMutableArray alloc] initWithCapacity:[templates count]];
    for (OLProductTemplate *productTemplate in templates){
        if (productTemplate.enabled){
            OLProduct *product = [[OLProduct alloc] initWithTemplate:productTemplate];
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

-(NSMutableDictionary *) selectedOptions{
    if (!_selectedOptions){
        _selectedOptions = [[NSMutableDictionary alloc] init];
        
        for (OLProductTemplateOption *option in self.productTemplate.options){
            if (option.choices.count > 0 && ![option.code isEqualToString:@"garment_size"]){
                _selectedOptions[option.code] = option.choices.firstObject.code;
            }
        }
    }
    return _selectedOptions;
}

- (UIColor *)labelColor{
    return self.productTemplate.labelColor;
}

-(NSUInteger)quantityToFulfillOrder{
    if (self.productTemplate.templateUI == OLTemplateUIPhotobook){
        return self.productTemplate.productRepresentation.numberOfPhotos;
    }
    if (self.productTemplate.templateUI == OLTemplateUICalendar){
        return self.productTemplate.gridCountX * self.productTemplate.gridCountY * 12;
    }
    return MAX(self.productTemplate.quantityPerSheet, 1);
}

-(instancetype)initWithTemplate:(OLProductTemplate *)productTemplate{
    self = [super init];
    if (self) {
        _productTemplate = productTemplate;
    }
    return self;
}

+(OLProduct *) productWithTemplateId:(NSString *)templateId{
    return [[OLProduct alloc] initWithTemplate:[OLProductTemplate templateWithId:templateId]];
}

-(OLAsset *)coverPhotoAsset{
    if ([_coverPhoto isKindOfClass:[NSString class]]){
        return [OLAsset assetWithImageAsPNG:[UIImage imageNamedInKiteBundle:_coverPhoto]];
    }
    else if ([_coverPhoto isKindOfClass:[UIImage class]]){
        return [OLAsset assetWithImageAsPNG:_coverPhoto];
    }
    else if ([_coverPhoto isKindOfClass:[NSURL class]]){
        return [OLAsset assetWithURL:_coverPhoto size:CGSizeZero];
    }
    else{
        return [OLAsset assetWithURL:self.productTemplate.coverPhotoURL size:CGSizeZero];
    }
}

-(OLAsset *)classImageAsset{
    if (self.productTemplate.classPhotoURL && ![[self.productTemplate.classPhotoURL absoluteString] isEqualToString:@""]){
        return [OLAsset assetWithURL:self.productTemplate.classPhotoURL size:CGSizeZero];
    }
    else{
        return self.coverPhotoAsset;
    }
}

- (void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView{
    UIImage *image;
    if ([self.productPhotos[i] isKindOfClass:[NSString class]]){
        image = [UIImage imageNamedInKiteBundle:self.productPhotos[i]];
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
        [imageView setAndFadeInImageWithURL:[NSURL URLWithString:self.productTemplate.productPhotographyURLs[i % [self.productTemplate.productPhotographyURLs count]]]];
    }
}

#pragma mark Product Info

- (NSString *)currencyCode {
    NSString *code = [[OLCountry countryForCurrentLocale] currencyCode];
    OLProductTemplate *productTemplate = [OLProductTemplate templateWithId:self.templateId];
    if (!code || ![productTemplate.currenciesSupported containsObject:code]) {
        // preferred currency fallback order if users local currency isn't supported: USD, GBP, EUR
        if ([productTemplate.currenciesSupported containsObject:@"USD"]) {
            code = @"USD";
        } else if ([productTemplate.currenciesSupported containsObject:@"GBP"]) {
            code = @"GBP";
        } else if ([productTemplate.currenciesSupported containsObject:@"EUR"]) {
            code = @"EUR";
        } else{
            code = productTemplate.currenciesSupported.firstObject;
        }
    }
    
    return code;
}

- (NSString *)originalUnitCost {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setCurrencyCode:[self currencyCode]];
    NSDecimalNumber *cost = [self originalUnitCostDecimalNumber];
    if (!cost){
        return nil;
    }
    return [formatter stringFromNumber:cost];
}

- (NSDecimalNumber*) originalUnitCostDecimalNumber {
    OLProductTemplate *productTemplate = [OLProductTemplate templateWithId:self.templateId];
    
    NSDecimalNumber *sheetCost = productTemplate.originalCostsByCurrencyCode[[self currencyCode]];
    if (!sheetCost){
        return nil;
    }
    NSUInteger sheetQuantity = productTemplate.quantityPerSheet == 0 ? 1 : productTemplate.quantityPerSheet;
    NSUInteger numSheets = (NSUInteger) ceil(self.quantityToFulfillOrder / sheetQuantity);
    NSDecimalNumber *unitCost = [sheetCost decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%lu", (unsigned long)numSheets]]];
    return unitCost;
}

- (NSString *)unitCost {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setCurrencyCode:[self currencyCode]];
    return [formatter stringFromNumber:[self unitCostDecimalNumber]];
}

- (NSDecimalNumber*) unitCostDecimalNumber {
    NSString *currencyCode = [self currencyCode];
    OLProductTemplate *productTemplate = [OLProductTemplate templateWithId:self.templateId];
    
    NSDecimalNumber *sheetCost = [productTemplate costPerSheetInCurrencyCode:currencyCode];
    NSUInteger sheetQuanity = productTemplate.quantityPerSheet == 0 ? 1 : productTemplate.quantityPerSheet;
    NSUInteger numSheets = (NSUInteger) ceil(self.quantityToFulfillOrder / sheetQuanity);
    NSDecimalNumber *unitCost = [sheetCost decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%lu", (unsigned long)numSheets]]];
    
    if (self.productTemplate.fulfilmentItems.count > 1){
        for (OLFulfilmentItem *item in self.productTemplate.fulfilmentItems){
            if (((([item.identifier isEqualToString:@"center_chest"] || [item.identifier isEqualToString:@"front_image"]))) && [item hasCostForCurrency:currencyCode]){
                unitCost = [unitCost decimalNumberByAdding:[item costForCurrency:currencyCode]];
            }
        }
    }
    
    return unitCost;
}

- (NSString *)templateId {
    return self.productTemplate.identifier;
}

- (NSString *) packInfo{
    if (self.productTemplate.templateUI == OLTemplateUICalendar || self.productTemplate.templateUI == OLTemplateUIFrame || self.productTemplate.templateUI == OLTemplateUIPoster || self.productTemplate.templateUI == OLTemplateUIPostcard || self.productTemplate.templateUI == OLTemplateUIPhotobook || self.quantityToFulfillOrder == 1 || self.quantityToFulfillOrder == 0){
        return @"";
    }
    NSString* packOfString = NSLocalizedStringFromTableInBundle(@"Pack of", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Pack of [20 square photos]");
    return [packOfString stringByAppendingFormat:@" %lu\n", (unsigned long)self.quantityToFulfillOrder];
}

- (BOOL)isMultipack{
    if (self.productTemplate.templateUI == OLTemplateUIFrame || self.productTemplate.templateUI == OLTemplateUICircle || self.productTemplate.templateUI == OLTemplateUIRectangle || (self.productTemplate.templateUI == OLTemplateUIPoster && self.quantityToFulfillOrder > 1)){
        return YES;
    }
    
    return NO;
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
            unitsName =  NSLocalizedStringFromTableInBundle(@"cm", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Centimeters");
            break;
        case kSizeUnitsInches:
            dimensions = [self dimensionsInInches];
            unitsName =  NSLocalizedStringFromTableInBundle(@"inches", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
            if (dimensions.width < 0.1 && dimensions.height < 0.1){
                dimensions = [self dimensionsInCentimetres];
                unitsName = NSLocalizedStringFromTableInBundle(@"cm", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Centimeters");
            }
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
    BOOL isMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
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
    if (self.productTemplate.productDescriptionMarkdown && ![self.productTemplate.productDescriptionMarkdown isEqualToString:@""]){
        return [self.productTemplate.productDescriptionMarkdown stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    }
    
    //Fall back to the old field
    NSString *s = @"";
    
    //Add description
    if (self.productTemplate.productDescription && ![self.productTemplate.productDescription isEqualToString:@""]){
        NSString *descriptionString = NSLocalizedStringFromTableInBundle(@"Description", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Product description");
        s = [s stringByAppendingString:[NSString stringWithFormat:@"**%@**\n%@\n\n", descriptionString, [self.productTemplate.productDescription stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"]]];
    }
    
    //Add size info
    OLTemplateUI templateClass = self.productTemplate.templateUI;
    if (templateClass != OLTemplateUICase){
        NSString *sizeString = NSLocalizedStringFromTableInBundle(@"Size", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Physical size of the product");
        s = [s stringByAppendingString:[NSString stringWithFormat:@"**%@**\n%@\n\n", sizeString, self.dimensions]];
    }
    
    //Add qty info
    if (self.packInfo && ![self.packInfo isEqualToString:@""]){
        NSString *qtyString = NSLocalizedStringFromTableInBundle(@"Quantity", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Quantity of photos");
        s = [s stringByAppendingString:[NSString stringWithFormat:@"**%@**\n%lu\n\n", qtyString, (unsigned long)self.quantityToFulfillOrder]];
    }
    
    //Add price info
    if ([OLKiteABTesting sharedInstance].hidePrice){
        NSString *priceString = NSLocalizedStringFromTableInBundle(@"Price", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        s = [s stringByAppendingString:[NSString stringWithFormat:@"**%@**\n%@\n\n", priceString, self.unitCost]];
    }
    
//    //Add shipping info
//    NSString *shippingString = NSLocalizedStringFromTableInBundle(@"Shipping", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
//    NSString *fromString = NSLocalizedStringFromTableInBundle(@"From", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
//    NSString *shippingLabel = [NSString stringWithFormat:@"**%@**\n", shippingString];
//    
//    NSDecimalNumber *minCost;
//    
//    NSString *currencyCode = [self currencyCode];
//    NSString *region = self.productTemplate.countryMapping[[OLCountry countryForCurrentLocale].codeAlpha3];
//    if (region){
//        if (self.productTemplate.shippingClasses[region].count == 1){
//            fromString = nil;
//        }
//        for (OLShippingClass *shippingClass in self.productTemplate.shippingClasses[region]){
//            NSDecimalNumber *cost = [NSDecimalNumber decimalNumberWithDecimal:[shippingClass.costs[currencyCode] decimalValue]];
//            if (!minCost || [minCost compare:cost] == NSOrderedDescending){
//                minCost = cost;
//            }
//        }
//        
//        if (minCost){
//            if (shippingLabel){
//                s = [s stringByAppendingString:shippingLabel];
//                shippingLabel = nil;
//            }
//            
//            if (fromString){
//                s = [s stringByAppendingString: [NSString stringWithFormat:@"%@ %@\n\n", fromString, [minCost formatCostForCurrencyCode:currencyCode]]];
//            }
//            else{
//                s = [s stringByAppendingString: [NSString stringWithFormat:@"%@\n\n", [minCost formatCostForCurrencyCode:currencyCode]]];
//            }
//        }
//    }
    
    //Add quality guarantee
    s = [s stringByAppendingString:[OLKitePrintSDK qualityGuaranteeString]];
    return s;
}

- (BOOL)isValidProductForUI{
    return self.labelColor && self.productTemplate.templateUI != OLTemplateUINA;
}

@end
