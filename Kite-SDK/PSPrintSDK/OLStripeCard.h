//
//  OLStripeCard.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 05/11/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OLStripeCardStoreCompletionHandler)(NSError *error);
typedef void (^OLStripeCardChargeCompletionHandler)(NSString *proofOfPayment, NSError *error);

@interface OLStripeCard : NSObject <NSSecureCoding>

+ (void)setClientId:(NSString *)clientId;
+ (OLStripeCard *)lastUsedCard;
+ (void)clearLastUsedCard;
- (void)saveAsLastUsedCard;

//- (void)storeCardWithCompletionHandler:(OLStripeCardStoreCompletionHandler)handler;
- (void)chargeCard:(NSDecimalNumber *)amount currencyCode:(NSString *)currencyCode description:(NSString *)description completionHandler:(OLStripeCardChargeCompletionHandler)handler;

@property (nonatomic, copy) NSString *number;
@property (nonatomic, copy) NSString *numberMasked;
@property (nonatomic, assign) NSUInteger expireMonth;
@property (nonatomic, assign) NSUInteger expireYear;
@property (nonatomic, copy) NSString *cvv2;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *customerId;

@end
