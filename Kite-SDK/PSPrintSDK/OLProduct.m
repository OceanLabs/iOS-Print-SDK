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
#import "OLCountry.h"
#import "OLProductTemplate.h"
#import "UIImageView+FadeIn.h"
#import "NSDecimalNumber+CostFormatter.h"
#import "OLKiteABTesting.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLProductTemplateOption.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"

typedef enum {
    kSizeUnitsInches,
    kSizeUnitsCentimetres
} SizeUnits;

@interface OLKitePrintSDK (Private)

+ (NSString *)qualityGuaranteeString;

@end

@interface OLProduct ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

@implementation OLProduct

-( NSMutableSet <OLUpsellOffer *> *) declinedOffers{
    if (!_declinedOffers){
        _declinedOffers = [[ NSMutableSet <OLUpsellOffer *> alloc] init];
    }
    return _declinedOffers;
}

-( NSMutableSet <OLUpsellOffer *> *) acceptedOffers{
    if (!_acceptedOffers){
        _acceptedOffers = [[ NSMutableSet <OLUpsellOffer *> alloc] init];
    }
    return _acceptedOffers;
}

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
            if (option.choices.count > 0){
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

-(void)setCoverImageToImageView:(UIImageView *)imageView size:(CGSize)size{
    UIImage *image;
    if ([self.coverPhoto isKindOfClass:[NSString class]]){
        image = [UIImage imageNamedInKiteBundle:self.coverPhoto];
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
        [imageView setAndFadeInImageWithURL:self.productTemplate.coverPhotoURL size:size];
    }
}

-(void)setClassImageToImageView:(UIImageView *)imageView size:(CGSize)size{
    UIImage *image;
    if ([self.coverPhoto isKindOfClass:[NSString class]]){
        image = [UIImage imageNamedInKiteBundle:self.coverPhoto];
    }
    else if ([self.coverPhoto isKindOfClass:[UIImage class]]){
        image = self.coverPhoto;
    }
    
    if (image){
        imageView.image = image;
    }
    else if ([self.coverPhoto isKindOfClass:[NSURL class]]){
        [imageView setAndFadeInImageWithURL:self.coverPhoto size:size];
    }
    else{
        OLProductTemplate *productTemplate = self.productTemplate;
        if (productTemplate.classPhotoURL && ![[productTemplate.classPhotoURL absoluteString] isEqualToString:@""]){
            [imageView setAndFadeInImageWithURL:self.productTemplate.classPhotoURL size:size];
        }
        else{
            [imageView setAndFadeInImageWithURL:self.productTemplate.coverPhotoURL size:size];
        }
        
    }
}

-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView{
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

- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier{
    for (OLUpsellOffer *acceptedOffer in self.acceptedOffers){
        if (acceptedOffer.identifier == identifier){
            return YES;
        }
    }
    for (OLUpsellOffer *declinedOffer in self.declinedOffers){
        if (declinedOffer.identifier == identifier){
            return YES;
        }
    }
    if (self.redeemedOffer.identifier == identifier){
        return YES;
    }
    return NO;
}

#pragma mark Product Info

- (NSString *)currencyCode {
    NSString *code = [OLCountry countryForCurrentLocale].currencyCode;
    OLProductTemplate *productTemplate = [OLProductTemplate templateWithId:self.templateId];
    if (![productTemplate.currenciesSupported containsObject:code]) {
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
    NSUInteger sheetQuanity = productTemplate.quantityPerSheet == 0 ? 1 : productTemplate.quantityPerSheet;
    NSUInteger numSheets = (NSUInteger) ceil(self.quantityToFulfillOrder / sheetQuanity);
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
    OLProductTemplate *productTemplate = [OLProductTemplate templateWithId:self.templateId];
    
    NSDecimalNumber *sheetCost = [productTemplate costPerSheetInCurrencyCode:[self currencyCode]];
    NSUInteger sheetQuanity = productTemplate.quantityPerSheet == 0 ? 1 : productTemplate.quantityPerSheet;
    NSUInteger numSheets = (NSUInteger) ceil(self.quantityToFulfillOrder / sheetQuanity);
    NSDecimalNumber *unitCost = [sheetCost decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%lu", (unsigned long)numSheets]]];
    return unitCost;
}

- (NSString *)templateId {
    return self.productTemplate.identifier;
}

- (NSString *) packInfo{
    if (self.productTemplate.templateUI == OLTemplateUICalendar || self.productTemplate.templateUI == OLTemplateUIFrame || self.productTemplate.templateUI == OLTemplateUIPoster || self.productTemplate.templateUI == OLTemplateUIPostcard || self.productTemplate.templateUI == OLTemplateUIPhotobook || self.quantityToFulfillOrder == 1 || self.quantityToFulfillOrder == 0){
        return @"";
    }
    NSString* packOfString = NSLocalizedStringFromTableInBundle(NSLocalizedStringFromTableInBundle(@"Pack of", @"KitePrintSDK", [OLKiteUtils kiteBundle], @""), @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    return [packOfString stringByAppendingFormat:@" %lu\n", (unsigned long)self.quantityToFulfillOrder];
}

- (BOOL)isMultipack{
    if (self.productTemplate.templateUI == OLTemplateUIFrame || self.productTemplate.templateUI == OLTemplateUICircle || self.productTemplate.templateUI == OLTemplateUIRectagle){
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
            unitsName =  NSLocalizedStringFromTableInBundle(@"cm", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
            break;
        case kSizeUnitsInches:
            dimensions = [self dimensionsInInches];
            unitsName =  NSLocalizedStringFromTableInBundle(@"inches", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
            if (dimensions.width < 0.1 && dimensions.height < 0.1){
                dimensions = [self dimensionsInCentimetres];
                unitsName = NSLocalizedStringFromTableInBundle(@"cm", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
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
        s = [s stringByAppendingString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"**Description**\n%@\n\n", @"KitePrintSDK", [OLKiteUtils kiteBundle], @""), [self.productTemplate.productDescription stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"]]];
    }
    
    //Add size info
    OLTemplateUI templateClass = self.productTemplate.templateUI;
    if (templateClass != OLTemplateUICase){
        s = [s stringByAppendingString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"**Size**\n%@\n\n", @"KitePrintSDK", [OLKiteUtils kiteBundle], @""), self.dimensions]];
    }
    
    //Add qty info
    if (self.packInfo && ![self.packInfo isEqualToString:@""]){
        s = [s stringByAppendingString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"**Quantity**\n%lu\n\n", @"KitePrintSDK", [OLKiteUtils kiteBundle], @""), (unsigned long)self.quantityToFulfillOrder]];
    }
    
    //Add price info
    if ([OLKiteABTesting sharedInstance].hidePrice){
        s = [s stringByAppendingString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"**Price**\n%@\n\n", @"KitePrintSDK", [OLKiteUtils kiteBundle], @""), self.unitCost]];
    }
    
    //Add shipping info
    NSDecimalNumber *shippingCost = [self.productTemplate shippingCostForCountry:[OLCountry countryForCurrentLocale]];
    if (shippingCost && [shippingCost doubleValue] != 0){
        if (![OLKiteABTesting sharedInstance].hidePrice){
            NSDecimalNumber *original = [self.productTemplate originalShippingCostForCountry:[OLCountry countryForCurrentLocale]];
            if (original){
                s = [s stringByAppendingString: [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"**Shipping**\n~%@~ %@\n\n", @"KitePrintSDK", [OLKiteUtils kiteBundle], @""), [original formatCostForCurrencyCode:[self.productTemplate currencyForCurrentLocale]], [shippingCost formatCostForCurrencyCode:[self.productTemplate currencyForCurrentLocale]]]];
            }
            else{
                s = [s stringByAppendingString: [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"**Shipping**\n%@\n\n", @"KitePrintSDK", [OLKiteUtils kiteBundle], @""), [shippingCost formatCostForCurrencyCode:[self.productTemplate currencyForCurrentLocale]]]];
            }
        }
    }
    else if (!shippingCost){ // ¯\_(ツ)_/¯ don't assume 0, don't add any shipping info
    }
    else{
        s = [s stringByAppendingString:NSLocalizedStringFromTableInBundle(@"**Shipping**\nFREE\n\n", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")];
    }
    
    //Add quality guarantee
    s = [s stringByAppendingString:[OLKitePrintSDK qualityGuaranteeString]];
    return s;
}

- (BOOL)isValidProductForUI{
    return self.labelColor && self.productTemplate.templateUI != OLTemplateUINA;
}



@end
