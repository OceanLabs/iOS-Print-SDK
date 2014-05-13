//
//  OLJudoPayCard.h
//  Kite SDK
//
//  Created by Deon Botha on 25/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OLJudoPayCardStoreCompletionHandler)(NSError *error);
typedef void (^OLJudoPayCardChargeCompletionHandler)(NSString *proofOfPayment, NSError *error);

typedef enum {
    kOLJudoPayCardTypeVisa,
    kOLJudoPayCardTypeMastercard,
    kOLJudoPayCardTypeDiscover,
    kOLJudoPayCardTypeAmex
} OLJudoPayCardType;

typedef enum {
    kOLJudoPayCurrencyGBP,
    kOLJudoPayCurrencyUSD
} OLJudoPayCurrency;

typedef enum {
    kOLJudoPayEnvironmentSandbox,
    kOLJudoPayEnvironmentLive
} OLJudoPayEnvironment;

@interface OLJudoPayCard : NSObject <NSCoding>

+ (void)setClientId:(NSString *)clientId token:(NSString *)token secret:(NSString *)secret withEnvironment:(OLJudoPayEnvironment)environment;
+ (OLJudoPayCard *)lastUsedCard;
+ (void)clearLastUsedCard;
- (void)saveAsLastUsedCard;

- (void)chargeCard:(NSDecimalNumber *)amount currency:(OLJudoPayCurrency)currency description:(NSString *)description completionHandler:(OLJudoPayCardChargeCompletionHandler)handler;

@property (nonatomic, copy) NSString *number;
@property (nonatomic, copy) NSString *numberMasked;
@property (nonatomic, assign) OLJudoPayCardType type;
@property (nonatomic, assign) NSUInteger expireMonth;
@property (nonatomic, assign) NSUInteger expireYear;
@property (nonatomic, copy) NSString *cvv2;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;

// When a successful payment is made the JudoPay backend will tokenise the card for us to speed up future payments
// using this card. We will not need to ask the user for all it's details again.
@property (nonatomic, readonly) NSString *cardToken;
@property (nonatomic, readonly) NSString *consumerToken;

@property (nonatomic, readonly, getter = isTokenised) BOOL tokenised;

@end
