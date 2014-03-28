//
//  OLPayPalCard.h
//  PS SDK
//
//  Created by Deon Botha on 10/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OLPayPalCardStoreCompletionHandler)(NSError *error);
typedef void (^OLPayPalCardChargeCompletionHandler)(NSString *proofOfPayment, NSError *error);

typedef enum {
    kOLPayPalCardTypeVisa,
    kOLPayPalCardTypeMastercard,
    kOLPayPalCardTypeDiscover,
    kOLPayPalCardTypeAmex
} OLPayPalCardType;

typedef enum {
    kOLPayPalEnvironmentSandbox,
    kOLPayPalEnvironmentLive
} OLPayPalEnvironment;

@interface OLPayPalCard : NSObject <NSCoding>

+ (void)setClientId:(NSString *)clientId withEnvironment:(OLPayPalEnvironment)environment;
+ (OLPayPalCard *)lastUsedCard;
+ (void)clearLastUsedCard;
- (void)saveAsLastUsedCard;

- (void)storeCardWithCompletionHandler:(OLPayPalCardStoreCompletionHandler)handler;
- (void)chargeCard:(NSDecimalNumber *)amount currencyCode:(NSString *)currencyCode description:(NSString *)description completionHandler:(OLPayPalCardChargeCompletionHandler)handler;

@property (nonatomic, copy) NSString *number;
@property (nonatomic, copy) NSString *numberMasked;
@property (nonatomic, assign) OLPayPalCardType type;
@property (nonatomic, assign) NSUInteger expireMonth;
@property (nonatomic, assign) NSUInteger expireYear;
@property (nonatomic, copy) NSString *cvv2;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, readonly) NSString *vaultId;
@property (nonatomic, readonly) NSDate *vaultExpireDate;

@property (nonatomic, readonly, getter = isStoredInVault) BOOL stored;
@property (nonatomic, readonly, getter = hasVaultStorageExpired) BOOL expired;

@end
