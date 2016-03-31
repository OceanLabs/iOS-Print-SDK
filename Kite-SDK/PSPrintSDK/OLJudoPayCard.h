//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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

#ifdef OL_OFFER_JUDOPAY

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

#endif
