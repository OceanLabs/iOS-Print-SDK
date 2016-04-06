//
//  OLUpsellOffer.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 04/04/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLUpsellOffer.h"
#import "OLProductTemplate.h"

static NSString *const kKeyOfferIdentifier = @"co.oceanlabs.pssdk.kKeyOfferIdentifier";
static NSString *const kKeyOfferActive = @"co.oceanlabs.pssdk.kKeyOfferActive";
static NSString *const kKeyOfferDiscountPercentage = @"co.oceanlabs.pssdk.kKeyOfferDiscountPercentage";
static NSString *const kKeyOfferType = @"co.oceanlabs.pssdk.kKeyOfferType";
static NSString *const kKeyOfferPrepopulatePhotos = @"co.oceanlabs.pssdk.kKeyOfferPrepopulatePhotos";
static NSString *const kKeyOfferPriority = @"co.oceanlabs.pssdk.kKeyOfferPriority";
static NSString *const kKeyOfferTemplate = @"co.oceanlabs.pssdk.kKeyOfferTemplate";
static NSString *const kKeyOfferMinUnits = @"co.oceanlabs.pssdk.kKeyOfferMinUnits";
static NSString *const kKeyOfferMaxUnits = @"co.oceanlabs.pssdk.kKeyOfferMaxUnits";
static NSString *const kKeyOfferHeaderText = @"co.oceanlabs.pssdk.kKeyOfferHeaderText";
static NSString *const kKeyOfferText = @"co.oceanlabs.pssdk.kKeyOfferText";

@implementation OLUpsellOffer

+ (OLUpsellOffer *)upsellOfferWithDictionary:(NSDictionary *)offerDict{
    OLUpsellOffer *offer = [[OLUpsellOffer alloc] init];
    if ([offerDict[@"active"] isKindOfClass:[NSNumber class]]){
        offer.active = [offerDict[@"active"] boolValue];
    }
    if ([offerDict[@"discount_percentage"] isKindOfClass:[NSNumber class]]){
        offer.discountPercentage = offerDict[@"discount_percentage"];
    }
    if ([offerDict[@"id"] isKindOfClass:[NSNumber class]]){
        offer.identifier = [offerDict[@"id"] unsignedIntegerValue];
    }
    if ([offerDict[@"offer_template"] isKindOfClass:[NSString class]]){
        offer.offerTemplate = offerDict[@"offer_template"];
    }
    if ([offerDict[@"offer_type"] isKindOfClass:[NSString class]]){
        if ([offerDict[@"offer_type"] isEqualToString:@"ITEM_ADD"]){
            offer.type = OLUpsellOfferTypeItemAdd;
        }
    }
    if ([offerDict[@"prepopulate_photos"] isKindOfClass:[NSNumber class]]){
        offer.prepopulatePhotos = [offerDict[@"prepopulate_photos"] boolValue];
    }
    if ([offerDict[@"priority"] isKindOfClass:[NSNumber class]]){
        offer.priority = [offerDict[@"priority"] integerValue];
    }
    if ([offerDict[@"min_valid_units"] isKindOfClass:[NSNumber class]]){
        offer.minUnits = [offerDict[@"min_valid_units"] integerValue];
    }
    if ([offerDict[@"max_valid_units"] isKindOfClass:[NSNumber class]]){
        offer.maxUnits = [offerDict[@"max_valid_units"] integerValue];
    }
    if ([offerDict[@"upsell_header_text"] isKindOfClass:[NSString class]]){
        offer.headerText = offerDict[@"upsell_header_text"];
    }
    if ([offerDict[@"upsell_text"] isKindOfClass:[NSString class]]){
        offer.text = offerDict[@"upsell_text"];
    }
    
    return offer;
}

-(BOOL)prepopulatePhotos{
    OLProductTemplate *template = [OLProductTemplate templateWithId:self.offerTemplate];
    if (template.templateUI == kOLTemplateUINonCustomizable || template.templateUI == kOLTemplateUINA){
        return YES;
    }
    
    return _prepopulatePhotos;
}

- (id)copyWithZone:(NSZone *)zone{
    OLUpsellOffer *copy = [[OLUpsellOffer alloc] init];
    copy.active = self.active;
    copy.identifier = self.identifier;
    copy.discountPercentage = [self.discountPercentage copyWithZone:zone];
    copy.type = self.type;
    copy.prepopulatePhotos = self.prepopulatePhotos;
    copy.priority = self.priority;
    copy.offerTemplate = [self.offerTemplate copyWithZone:zone];
    copy.maxUnits = self.maxUnits;
    copy.minUnits = self.minUnits;
    copy.headerText = self.headerText;
    copy.text = self.text;
    
    return copy;
}

#pragma mark - NSCoding protocol methods
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:self.active forKey:kKeyOfferActive];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:self.identifier] forKey:kKeyOfferIdentifier];
    [aCoder encodeObject:self.discountPercentage forKey:kKeyOfferDiscountPercentage];
    [aCoder encodeInteger:self.type forKey:kKeyOfferType];
    [aCoder encodeBool:self.prepopulatePhotos forKey:kKeyOfferPrepopulatePhotos];
    [aCoder encodeInteger:self.priority forKey:kKeyOfferPriority];
    [aCoder encodeObject:self.offerTemplate forKey:kKeyOfferTemplate];
    [aCoder encodeInteger:self.maxUnits forKey:kKeyOfferMaxUnits];
    [aCoder encodeInteger:self.minUnits forKey:kKeyOfferMinUnits];
    [aCoder encodeObject:self.headerText forKey:kKeyOfferHeaderText];
    [aCoder encodeObject:self.text forKey:kKeyOfferText];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.active = [aDecoder decodeBoolForKey:kKeyOfferActive];
        self.identifier = [[aDecoder decodeObjectForKey:kKeyOfferIdentifier] unsignedIntegerValue];
        self.discountPercentage = [aDecoder decodeObjectForKey:kKeyOfferDiscountPercentage];
        self.type = (OLUpsellOfferType)[aDecoder decodeIntegerForKey:kKeyOfferType];
        self.prepopulatePhotos = [aDecoder decodeBoolForKey:kKeyOfferPrepopulatePhotos];
        self.priority = [aDecoder decodeIntegerForKey:kKeyOfferPriority];
        self.offerTemplate = [aDecoder decodeObjectForKey:kKeyOfferTemplate];
        self.minUnits = [aDecoder decodeIntegerForKey:kKeyOfferMinUnits];
        self.maxUnits = [aDecoder decodeIntegerForKey:kKeyOfferMaxUnits];
        self.headerText = [aDecoder decodeObjectForKey:kKeyOfferHeaderText];
        self.text = [aDecoder decodeObjectForKey:kKeyOfferText];
    }
    
    return self;
}

@end
