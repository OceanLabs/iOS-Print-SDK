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

#ifdef COCOAPODS
#import <AFNetworking/AFNetworking.h>
#import <UICKeyChainStore/UICKeyChainStore.h>
#else
#import "AFNetworking.h"
#import "UICKeyChainStore.h"
#endif

#import "OLJudoPayCard.h"
#import "OLConstants.h"

static NSString *const kKeyNumberMasked = @"co.oceanlabs.judopay.kKeyNumberMasked";
static NSString *const kKeyCardType = @"co.oceanlabs.judopay.kKeyCardtype";
static NSString *const kKeyExpireMonth = @"co.oceanlabs.judopay.kKeyExpireMonth";
static NSString *const kKeyExpireYear = @"co.oceanlabs.judopay.kKeyExpireYear";
static NSString *const kKeyFirstName = @"co.oceanlabs.judopay.kKeyFirstName";
static NSString *const kKeyLastName = @"co.oceanlabs.judopay.kKeyLastName";
static NSString *const kKeyCardToken = @"co.oceanlabs.judopay.kKeyCardToken";
static NSString *const kKeyConsumerToken = @"co.oceanlabs.judopay.kKeyConsumerToken";

static NSString *const kErrorTypeUnexpected                 = @"0"; // Unexpexted error by Judo, a generic error message will accompany it
static NSString *const kErrorFriendlyMessage                = @"1"; // error message returned by Judo is friendly and appropriate to be shown to users
static NSString *const kErrorTypeInvalidCVV                 = @"9";
static NSString *const kErrorTypePaymentDeclined            = @"8";
static NSString *const kErrorTypePaymentFailed              = @"7";

static NSString *const kOLErrorDomainJudoPay = @"co.oceanlabs.judopay.kOLErrorDomainJudoPay";

static NSString *const kServiceName = @"co.oceanlabs.judopay.kServiceName";
static NSString *const kKeychainJudoPayLastUsedCardDetails = @"co.oceanlabs.judopay.kKeychainJudoPayCardDetails";

#define kErrorTitleGenericPaymentFailed      NSLocalizedStringFromTableInBundle(@"Payment Failed", @"KitePrintSDK", [OLConstants bundle], @"Generic payment failed error dialog title")
#define kErrorTitleInvalidCVV                NSLocalizedStringFromTableInBundle(@"Invalid CVV", @"KitePrintSDK", [OLConstants bundle], @"Invalid CVV payment failed error dialog title")
#define kErrorTitlePaymentDeclined           NSLocalizedStringFromTableInBundle(@"Payment Declined", @"KitePrintSDK", [OLConstants bundle], @"Payment declined error dialog title")

#define kErrorMessageGenericPaymentFailed    NSLocalizedStringFromTableInBundle(@"Unfortunately we failed to take a payment from your card. Please try again.", @"KitePrintSDK", [OLConstants bundle], @"Generic payment failed error dialog message")
#define kErrorMessageInvalidCVV              NSLocalizedStringFromTableInBundle(@"You have entered an invalid CVV number. Please check it and try again.", @"KitePrintSDK", [OLConstants bundle], @"Invalid CVV payment failed error dialog message")
#define kErrorMessagePaymentDeclined         NSLocalizedStringFromTableInBundle(@"Your payment has been declined. Please check your card details and try again.", @"KitePrintSDK", [OLConstants bundle], @"Payment declined error dialog message")

static const NSUInteger kStatusCodeSuccess = 200;
static const NSUInteger kStatusBadRequest  = 400;
//static const NSUInteger kStatusCodeConflict= 409;

static NSString *JudoPayClientId;
static OLJudoPayCard *lastUsedCard;
static OLJudoPayEnvironment environment;
static NSString *token, *secret;

@interface Card : NSObject
- (id)initWithCardNumber:(NSString *)number andExpiry:(NSString *)expiryDate andCV2:(NSString *)cv2;
@property (nonatomic, copy) NSString *cardToken, *number, *expiryDate, *cv2, *lastFour;
@end

@implementation Card
- (id)initWithCardNumber:(NSString *)number andExpiry:(NSString *)expiryDate andCV2:(NSString *)cv2 {
    if (self = [super init]) {
        self.number = number;
        self.expiryDate = expiryDate;
        self.cv2 = cv2;
    }
    
    return self;
}
@end

@implementation OLJudoPayCard

+ (void)setClientId:(NSString *)clientId token:(NSString *)_token secret:(NSString *)_secret withEnvironment:(OLJudoPayEnvironment)_environment {
    environment = _environment;
    token = _token;
    secret = _secret;
    JudoPayClientId = clientId;
}

+ (OLJudoPayCard *)lastUsedCard {
    if (!lastUsedCard) {
        NSData *data = [UICKeyChainStore dataForKey:kKeychainJudoPayLastUsedCardDetails service:kServiceName];
        if (data) {
            @try {
                lastUsedCard = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            } @catch (NSException *ex) {
                [UICKeyChainStore removeItemForKey:kKeychainJudoPayLastUsedCardDetails service:kServiceName];
            }
        }
    }
    
    return lastUsedCard;
}

+ (void)clearLastUsedCard {
    lastUsedCard = nil;
    [UICKeyChainStore removeItemForKey:kKeychainJudoPayLastUsedCardDetails service:kServiceName];
}

- (void)saveAsLastUsedCard {
    lastUsedCard = self;
    [UICKeyChainStore removeAllItemsForService:kServiceName];
    [UICKeyChainStore setData:[NSKeyedArchiver archivedDataWithRootObject:lastUsedCard] forKey:kKeychainJudoPayLastUsedCardDetails service:kServiceName];
}


- (void)setExpireMonth:(NSUInteger)expireMonth {
    NSAssert(expireMonth >= 1 && expireMonth <= 12, @"The expire month specified (%lu) must be between 1-12 inclusive", (unsigned long)expireMonth);
    _expireMonth = expireMonth;
}

- (void)setExpireYear:(NSUInteger)expireYear {
    if (expireYear > 2000) {
        expireYear -= 2000;
    }
    
    _expireYear = expireYear;
}

- (void)setNumber:(NSString *)number {
    NSAssert(number.length == 16, @"The card number must be supplied as 16 digits with no spaces");
    _number = number;
    _numberMasked = [NSString stringWithFormat:@"%@", [self.number substringFromIndex:12]];
}

- (Card *)createJudoPayCard {
    NSString *expiryDate = [NSString stringWithFormat:@"%02lu/%02lu", (unsigned long) self.expireMonth, (unsigned long) self.expireYear];
    Card *card = [[Card alloc] initWithCardNumber:self.number andExpiry:expiryDate andCV2:self.cvv2];
    card.cardToken = self.cardToken;
    
    if (self.number.length > 0) {
        card.lastFour = [self.number substringFromIndex:self.number.length - MIN(4, self.number.length)];
    } else if (self.numberMasked.length > 0) {
        card.lastFour = [self.numberMasked substringFromIndex:self.numberMasked.length - MIN(4, self.numberMasked.length)];
    }
    return card;
}

- (void)chargeCard:(NSDecimalNumber *)amount currency:(OLJudoPayCurrency)currency description:(NSString *)description completionHandler:(OLJudoPayCardChargeCompletionHandler)handler {
    
    Card *card = [self createJudoPayCard];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [[AFJSONRequestSerializer alloc] init];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:token password:secret];
    [manager.requestSerializer setValue:@"3.0.0" forHTTPHeaderField:@"Api-Version"];
    manager.responseSerializer.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 300)];
    
    NSDictionary *payload = nil;
    
    if (card.cardToken) {
        payload = @{@"yourConsumerReference": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                    @"cardToken": self.cardToken,
                    @"judoId": JudoPayClientId,
                    @"yourPaymentReference": @"yourPaymentReference",
                    @"amount": [NSString stringWithFormat:@"%.2f", [amount doubleValue]]
                    };
    } else {
        payload = @{@"cardnumber": card.number,
                    @"judoId": JudoPayClientId,
                    @"yourConsumerReference": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                    @"cv2": card.cv2,
                    @"amount": [NSString stringWithFormat:@"%.2f", [amount doubleValue]],
                    @"yourPaymentReference": @"yourPaymentReference",
                    @"expiryDate": card.expiryDate
                    };
    }
    
    [manager POST:[NSString stringWithFormat:@"https://%@/transactions/payments", environment == kOLJudoPayEnvironmentLive ? @"partnerapi.judopay.com" : @"partnerapi.judopay-sandbox.com"]
       parameters:payload progress:NULL
          success:^(NSURLSessionDataTask *task, id responseObject) {
              if ([task.response isKindOfClass:[NSHTTPURLResponse class]]){
                  NSInteger statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                  [self onSuccessWithStatusCode:(int) statusCode JSON:responseObject completionHandler:handler];
              }
              else{
                  [self onFailureWithStatusCode:(int) [(NSHTTPURLResponse *)task.response statusCode] error:([NSError errorWithDomain:kOLErrorDomainJudoPay code:kOLKiteSDKErrorCodeUnexpectedResponse userInfo:@{NSLocalizedDescriptionKey: kErrorMessageGenericPaymentFailed}]) completionHandler:handler];
              }
          } failure:^(NSURLSessionDataTask *task, NSError *error) {
              [self onFailureWithStatusCode: (int)kOLKiteSDKErrorCodeUnexpectedResponse error:error completionHandler:handler];
          }];
}

- (void)onFailureWithStatusCode:(int)statusCode error:(NSError *)error completionHandler:(OLJudoPayCardChargeCompletionHandler)handler {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (handler) handler(nil, error);
}

+ (NSString *)stringFromJSON:(NSDictionary *)json forKey:(NSString *)key {
    id val = [json objectForKey:key];
    if ([val isKindOfClass:[NSString class]]) {
        return val;
    }
    
    return nil;
}

+ (NSDictionary *)dictionaryFromJSON:(NSDictionary *)json forKey:(NSString *)key {
    id val = [json objectForKey:key];
    if ([val isKindOfClass:[NSDictionary class]]) {
        return val;
    }
    
    return nil;
}

- (void)onSuccessWithStatusCode:(int)statusCode JSON:(NSDictionary *)JSON completionHandler:(OLJudoPayCardChargeCompletionHandler)handler {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (statusCode == kStatusCodeSuccess) {
        NSString *result = [[JSON objectForKey:@"result"] lowercaseString];
        NSString *message = [JSON objectForKey:@"message"];
        if ([result isEqualToString:@"success"]) {
            // save card & consumer tokens to speed up future payments when using this card.
            NSDictionary *cardDetails = [OLJudoPayCard dictionaryFromJSON:JSON forKey:@"cardDetails"];
            if (cardDetails) {
                _cardToken = [OLJudoPayCard stringFromJSON:cardDetails forKey:@"cardToken"];
            }
            
            NSDictionary *consumerDetails = [OLJudoPayCard dictionaryFromJSON:JSON forKey:@"consumer"];
            if (consumerDetails) {
                //_consumerReference = [OLJudoPayCard stringFromJSON:consumerDetails forKey:@"yourConsumerReference"];
                _consumerToken     = [OLJudoPayCard stringFromJSON:consumerDetails forKey:@"consumerToken"];
            }
            
            NSString *receiptId = [JSON objectForKey:@"receiptId"];
            if (![receiptId isKindOfClass:[NSString class]]) {
                if ([receiptId isKindOfClass:[NSNumber class]]) {
                    receiptId = [(NSNumber *)receiptId stringValue];
                } else {
                    receiptId = @"";
                }
            }
            
            receiptId = [@"J-" stringByAppendingString:receiptId];
            
            if (handler) handler(receiptId, nil);
        } else if ([result isEqualToString:@"declined"]) {
            if (handler) handler(nil, [NSError errorWithDomain:kOLErrorDomainJudoPay code:99 userInfo:@{NSLocalizedDescriptionKey: kErrorMessagePaymentDeclined}]);
        } else {
            message = message ? message : kErrorMessageGenericPaymentFailed;
            if (handler) handler(nil, [NSError errorWithDomain:kOLErrorDomainJudoPay code:100 userInfo:@{NSLocalizedDescriptionKey: message}]);
        }
    } else if (statusCode == kStatusBadRequest) {
        id errorType = [JSON objectForKey:@"errorType"];
        if ([errorType isKindOfClass:[NSNumber class]]) {
            errorType = [(NSNumber *) errorType stringValue];
        }
        
        NSString *errorMessage = [JSON objectForKey:@"errorMessage"];
        NSString *errorTitle = kErrorTitleGenericPaymentFailed;
        if ([errorType isEqualToString:kErrorFriendlyMessage]) {
            id modelErrors = [JSON objectForKey:@"modelErrors"];
            if ([modelErrors isKindOfClass:[NSArray class]]) {
                for (id error in modelErrors) {
                    if ([error isKindOfClass:[NSDictionary class]]) {
                        id judoFriendlyErrorMessage = [error objectForKey:@"errorMessage"];
                        if ([judoFriendlyErrorMessage isKindOfClass:[NSString class]]) {
                            if (errorMessage) {
                                errorMessage = [errorMessage stringByAppendingFormat:@"\n\n• %@", judoFriendlyErrorMessage];
                            } else {
                                errorMessage = judoFriendlyErrorMessage;
                            }
                        }
                    }
                }
            }
        } else if ([errorType isEqualToString:kErrorTypePaymentDeclined]) {
            errorTitle = kErrorTitlePaymentDeclined;
            errorMessage = kErrorMessagePaymentDeclined;
        } else if ([errorType isEqualToString:kErrorTypeInvalidCVV]) {
            errorTitle = kErrorTitleInvalidCVV;
            errorMessage = kErrorMessageInvalidCVV;
        } else {
            errorMessage = errorMessage ? errorMessage : kErrorMessageGenericPaymentFailed;
        }
        
        if (!errorMessage) {
            errorMessage = kErrorMessageGenericPaymentFailed;
        }
        
        if (!errorTitle) {
            errorTitle = kErrorTitleGenericPaymentFailed;
        }
        
        if (handler) handler(nil, [NSError errorWithDomain:kOLErrorDomainJudoPay code:101 userInfo:@{NSLocalizedDescriptionKey: errorMessage}]);

    } else {
        if (handler) handler(nil, [NSError errorWithDomain:kOLErrorDomainJudoPay code:102 userInfo:@{NSLocalizedDescriptionKey: kErrorMessageGenericPaymentFailed}]);
    }
}

#pragma mark - NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.numberMasked forKey:kKeyNumberMasked];
    [aCoder encodeInteger:self.type forKey:kKeyCardType];
    [aCoder encodeInteger:self.expireMonth forKey:kKeyExpireMonth];
    [aCoder encodeInteger:self.expireYear forKey:kKeyExpireYear];
    [aCoder encodeObject:self.firstName forKey:kKeyFirstName];
    [aCoder encodeObject:self.lastName forKey:kKeyLastName];
    [aCoder encodeObject:self.cardToken forKey:kKeyCardToken];
    [aCoder encodeObject:self.consumerToken forKey:kKeyConsumerToken];
    
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.numberMasked = [aDecoder decodeObjectForKey:kKeyNumberMasked]; // Only store masked version (last 4 digits) of card number for PCI compliance
        self.type = [aDecoder decodeIntForKey:kKeyCardType];
        self.expireMonth = [aDecoder decodeIntegerForKey:kKeyExpireMonth];
        self.expireYear = [aDecoder decodeIntegerForKey:kKeyExpireYear];
        self.firstName = [aDecoder decodeObjectForKey:kKeyFirstName];
        self.lastName = [aDecoder decodeObjectForKey:kKeyLastName];
        _cardToken = [aDecoder decodeObjectForKey:kKeyCardToken];
        _consumerToken = [aDecoder decodeObjectForKey:kKeyConsumerToken];
    }
    
    return self;
}

@end

#endif
