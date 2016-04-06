//
//  OLUpsellOffer.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 04/04/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    OLUpsellOfferTypeItemNA,
    OLUpsellOfferTypeItemAdd
}OLUpsellOfferType;

@interface OLUpsellOffer : NSObject <NSCopying, NSCoding>

@property (assign, nonatomic) BOOL active;
@property (assign, nonatomic) NSUInteger identifier;
@property (strong, nonatomic) NSNumber *discountPercentage;
@property (assign, nonatomic) OLUpsellOfferType type;
@property (assign, nonatomic) BOOL prepopulatePhotos;
@property (assign, nonatomic) NSInteger priority;
@property (strong, nonatomic) NSString *offerTemplate;
@property (assign, nonatomic) NSInteger minUnits;
@property (assign, nonatomic) NSInteger maxUnits;
@property (strong, nonatomic) NSString *headerText;
@property (strong, nonatomic) NSString *text;

+ (OLUpsellOffer *)upsellOfferWithDictionary:(NSDictionary *)offerDict;


@end
