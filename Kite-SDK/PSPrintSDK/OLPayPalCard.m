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

#import "OLPayPalCard.h"
#import "OLConstants.h"
#import "NSString+Formatting.h"

static NSString *const kKeyNumberMasked = @"co.oceanlabs.paypal.kKeyNumberMasked";
static NSString *const kKeyCardType = @"co.oceanlabs.paypal.kKeyCardtype";
static NSString *const kKeyExpireMonth = @"co.oceanlabs.paypal.kKeyExpireMonth";
static NSString *const kKeyExpireYear = @"co.oceanlabs.paypal.kKeyExpireYear";
static NSString *const kKeyFirstName = @"co.oceanlabs.paypal.kKeyFirstName";
static NSString *const kKeyLastName = @"co.oceanlabs.paypal.kKeyLastName";
static NSString *const kKeyVaultId = @"co.oceanlabs.paypal.kKeyVaultId";
static NSString *const kKeyVaultExpireDate = @"co.oceanlabs.paypal.kKeyVaultExpireDate";

static NSString *const kOLErrorDomainPayPal = @"co.oceanlabs.paypal.kOLErrorDomainPayPal";

#define kErrorMessageGenericPayPalVaultFailure NSLocalizedStringFromTableInBundle(@"Failed to store card details with PayPal. Please try again.", @"KitePrintSDK", [OLConstants bundle], @"")
#define kErrorMessageBadCardNumber NSLocalizedStringFromTableInBundle(@"Please enter a valid card number", @"KitePrintSDK", [OLConstants bundle], @"")
#define kErrorMessageBadExpiryDate NSLocalizedStringFromTableInBundle(@"Please enter a card expiry date in the future", @"KitePrintSDK", [OLConstants bundle], @"")


static NSString *clientId;

typedef void (^OLPayPalCardAccessTokenCompletionHandler)(NSString *accessToken, NSError *error);

static OLPayPalCard *lastUsedCard;
static OLPayPalEnvironment environment;

static NSString *typeToString(OLPayPalCardType type) {
    switch (type) {
        case kOLPayPalCardTypeAmex: return @"amex";
        case kOLPayPalCardTypeDiscover: return @"discover";
        case kOLPayPalCardTypeMastercard: return @"mastercard";
        case kOLPayPalCardTypeVisa: return @"visa";
    }
}

@implementation OLPayPalCard

+ (void)setClientId:(NSString *)_clientId withEnvironment:(OLPayPalEnvironment)_environment {
    clientId = _clientId;
    environment = _environment;
}

+ (NSString *)lastUsedCardFilePath {
    NSArray * urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString *documentDirPath = [(NSURL *)[urls objectAtIndex:0] path];
    return [documentDirPath stringByAppendingPathComponent:@"co.oceanlabs.paypal.luc"];
}

+ (OLPayPalCard *)lastUsedCard {
    if (!lastUsedCard) {
        lastUsedCard = [NSKeyedUnarchiver unarchiveObjectWithFile:[OLPayPalCard lastUsedCardFilePath]];
    }
    
    return lastUsedCard;
}

+ (void)clearLastUsedCard {
    lastUsedCard = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[OLPayPalCard lastUsedCardFilePath] error:nil];
}

- (void)saveAsLastUsedCard {
    // TODO: store securely
    lastUsedCard = self;
    [NSKeyedArchiver archiveRootObject:lastUsedCard toFile:[OLPayPalCard lastUsedCardFilePath]];
}

- (BOOL)isStoredInVault {
    return _vaultId != nil;
}

- (BOOL)hasVaultStorageExpired {
    return [[NSDate date] timeIntervalSinceDate:self.vaultExpireDate] > 0;
}

- (void)setExpireMonth:(NSUInteger)expireMonth {
    NSAssert(expireMonth >= 1 && expireMonth <= 12, @"The expire month specified (%lu) must be between 1-12 inclusive", (unsigned long) expireMonth);
    _expireMonth = expireMonth;
}

- (void)setExpireYear:(NSUInteger)expireYear {
    if (expireYear <= 99) {
        expireYear += 2000;
    }
    
    _expireYear = expireYear;
}

- (void)getAccessTokenWithCompletionHandler:(OLPayPalCardAccessTokenCompletionHandler)handler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/v1/oauth2/token", environment == kOLPayPalEnvironmentLive ? @"api.paypal.com" : @"api.sandbox.paypal.com"]]];
    [request setHTTPMethod:@"POST"];
    
    NSData *basicAuthCredentials = [[NSString stringWithFormat:@"%@:%@", clientId, @""] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64AuthCredentials = [basicAuthCredentials base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
    [request setValue:[NSString stringWithFormat:@"Basic %@", base64AuthCredentials] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[@"grant_type=client_credentials" dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:nil
                                                     delegateQueue:nil];
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error){
                handler(nil, error);
            }
            else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSError *JSONError = nil;
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                           options:0
                                                                             error:&JSONError];
                
                id accessToken = [dictionary objectForKey:@"access_token"];
                if ([accessToken isKindOfClass:[NSString class]] && !JSONError) {
                    handler(accessToken, nil);
                } else {
                    // TODO: real response here :)
                    NSError *error = [NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to validate card details, please try again.", @"")}];
                    handler(nil, error);
                }
            }
        });
    }] resume];
}

- (void)storeCardWithCompletionHandler:(OLPayPalCardStoreCompletionHandler)handler {
    [self getAccessTokenWithCompletionHandler:^(NSString *accessToken, NSError *error) {
        NSDictionary *params = @{@"number": self.number,
                                 @"type": typeToString(self.type),
                                 @"expire_month": [NSString stringWithFormat:@"%lu", (unsigned long) self.expireMonth],
                                 @"expire_year": [NSString stringWithFormat:@"%lu", (unsigned long) self.expireYear],
                                 @"cvv2": self.cvv2
                                 };
        
        NSError *jsonError;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&jsonError];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/v1/vault/credit-card", environment == kOLPayPalEnvironmentLive ? @"api.paypal.com" : @"api.sandbox.paypal.com"]]];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:jsonData];
        [request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"en" forHTTPHeaderField:@"Accept-Language"];
        
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                              delegate:nil
                                                         delegateQueue:nil];
        
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error){
                    {
                        NSError *JSONError = nil;
                        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                                   options:0
                                                                                     error:&JSONError];
                        if ([response isKindOfClass:[NSHTTPURLResponse class]]){
                            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                            if (statusCode >= 200 && statusCode <= 299) {
                                id number = [dictionary objectForKey:@"number"];
                                id vaultId = [dictionary objectForKey:@"id"];
                                id vaultExpireDate = [dictionary objectForKey:@"valid_until"];
                                if (![number isKindOfClass:[NSString class]] || ![vaultId isKindOfClass:[NSString class]] || ![vaultExpireDate isKindOfClass:[NSString class]]) {
                                    handler([NSError errorWithDomain:kOLErrorDomainPayPal code:statusCode userInfo:@{NSLocalizedDescriptionKey: kErrorMessageGenericPayPalVaultFailure}]);
                                    return;
                                }
                                
                                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                                [dateFormatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ssZ"];
                                
                                self.numberMasked = number;
                                _vaultId = vaultId;
                                _vaultExpireDate = [dateFormatter dateFromString:vaultExpireDate];
                                
                                handler(nil);
                            } else {
                                id errorMessage = [dictionary objectForKey:@"message"];
                                if (![errorMessage isKindOfClass:[NSString class]]) {
                                    errorMessage = kErrorMessageGenericPayPalVaultFailure;
                                }
                                
                                handler([NSError errorWithDomain:kOLErrorDomainPayPal code:statusCode userInfo:@{NSLocalizedDescriptionKey: errorMessage}]);
                            }
                        }
                        else{
                            handler([NSError errorWithDomain:kOLErrorDomainPayPal code:kOLKiteSDKErrorCodeUnexpectedResponse userInfo:@{NSLocalizedDescriptionKey: kErrorMessageGenericPayPalVaultFailure}]);
                        }
                    }
                }
                else{
                    handler(error);
                }
            });
        }] resume];
    }];
}

- (void)chargeCard:(NSDecimalNumber *)amount currencyCode:(NSString *)currencyCode description:(NSString *)description completionHandler:(OLPayPalCardChargeCompletionHandler)handler {
    [self getAccessTokenWithCompletionHandler:^(NSString *accessToken, NSError *error) {
        NSDictionary *fundingInstrument = nil;
        if (self.number) {
            // take payment directly using full card number
            fundingInstrument = @{@"credit_card": @{
                                          @"number": self.number,
                                          @"type": typeToString(self.type),
                                          @"expire_month": [NSString stringWithFormat:@"%lu", (unsigned long) self.expireMonth],
                                          @"expire_year": [NSString stringWithFormat:@"%lu", (unsigned long) self.expireYear],
                                          @"cvv2": self.cvv2
                                          }
                                  };
        } else {
            // take payment with credit card token i.e. vault id
            fundingInstrument = @{
                                  @"credit_card_token":@{
                                          @"credit_card_id": self.vaultId                                          }
                                  };
        }
        
        NSString *total = [NSString stringWithFormat:@"%.2f", [amount doubleValue]];
        if ([[currencyCode lowercaseString] isEqualToString:@"jpy"]) {
            total = [NSString stringWithFormat:@"%.0f", [amount doubleValue]]; // no decimal places allowed for YEN
        }
        
        NSDictionary *paymentJSON = @{@"intent": @"authorize",
                                      @"payer": @{
                                              @"payment_method": @"credit_card",
                                              @"funding_instruments": @[fundingInstrument]
                                              },
                                      @"transactions": @[
                                              @{
                                                  @"amount": @{
                                                          @"total": total,
                                                          @"currency": currencyCode
                                                          },
                                                  @"description": description
                                                  }
                                              ]
                                      };
        
        NSError *jsonError;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:paymentJSON options:NSJSONWritingPrettyPrinted error:&jsonError];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/v1/payments/payment", environment == kOLPayPalEnvironmentLive ? @"api.paypal.com" : @"api.sandbox.paypal.com"]]];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:jsonData];
        [request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"en" forHTTPHeaderField:@"Accept-Language"];
        
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                              delegate:nil
                                                         delegateQueue:nil];
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error){
                    if ([response isKindOfClass:[NSHTTPURLResponse class]]){
                        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                        
                        NSError *JSONError = nil;
                        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                                   options:0
                                                                                     error:&JSONError];
                        
                        if (statusCode >= 200 && statusCode <= 299) {
                            id paymentId = dictionary[@"id"];
                            id paymentState = dictionary[@"state"];
                            if (![paymentId isKindOfClass:[NSString class]] || ![paymentState isKindOfClass:[NSString class]]) {
                                handler(nil, [NSError errorWithDomain:kOLErrorDomainPayPal code:statusCode userInfo:@{NSLocalizedDescriptionKey: kErrorMessageGenericPayPalVaultFailure}]);
                                return;
                            }
                            
                            if (![paymentState isEqualToString:@"approved"]) {
                                NSError *error = [NSError errorWithDomain:kOLErrorDomainPayPal code:statusCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Your payment was not approved (transaction state: %@). Please try again.", @"KitePrintSDK", [OLConstants bundle], @""), paymentState]}];
                                handler(nil, error);
                                return;
                            }
                            
                            NSString *token = paymentId;
                            token = [token stringByReplacingCharactersInRange:NSMakeRange(0, 3) withString:@"PAUTH"];
                            handler(token, nil);
                            
                        } else {
                            id errorMessage = [dictionary objectForKey:@"message"];
                            if (![errorMessage isKindOfClass:[NSString class]]) {
                                errorMessage = kErrorMessageGenericPayPalVaultFailure;
                            }
                            
                            if ([dictionary[@"details"] isKindOfClass:[NSArray class]]) {
                                NSArray *details = dictionary[@"details"];
                                if (details.count > 0) {
                                    if ([details[0] isKindOfClass:[NSDictionary class]]) {
                                        NSDictionary *detail = details[0];
                                        NSString *field = detail[@"field"];
                                        NSString *issue = detail[@"issue"];
                                        if ([field isKindOfClass:[NSString class]] && [issue isKindOfClass:[NSString class]]) {
                                            if ([field isEqualToString:@"payer.funding_instruments[0].credit_card.number"]) {
                                                errorMessage = kErrorMessageBadCardNumber;
                                            } else if ([field isEqualToString:@"payer.funding_instruments[0].credit_card"]
                                                       && [issue isEqualToString:@"Invalid expiration (cannot be in the past)"]) {
                                                errorMessage = kErrorMessageBadExpiryDate;
                                            }
                                        }
                                    }
                                }
                            }
                            
                            handler(nil, [NSError errorWithDomain:kOLErrorDomainPayPal code:statusCode userInfo:@{NSLocalizedDescriptionKey: errorMessage}]);
                        }
                    }
                    else{
                        handler(nil, [NSError errorWithDomain:kOLErrorDomainPayPal code:kOLKiteSDKErrorCodeUnexpectedResponse userInfo:@{NSLocalizedDescriptionKey: kErrorMessageGenericPayPalVaultFailure}]);
                    }
                }
                else{
                    handler(nil, error);
                }
            });
        }] resume];
    }];
}

#pragma mark - NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.numberMasked forKey:kKeyNumberMasked];
    [aCoder encodeInteger:self.type forKey:kKeyCardType];
    [aCoder encodeInteger:self.expireMonth forKey:kKeyExpireMonth];
    [aCoder encodeInteger:self.expireYear forKey:kKeyExpireYear];
    [aCoder encodeObject:self.firstName forKey:kKeyFirstName];
    [aCoder encodeObject:self.lastName forKey:kKeyLastName];
    [aCoder encodeObject:self.vaultId forKey:kKeyVaultId];
    [aCoder encodeObject:self.vaultExpireDate forKey:kKeyVaultExpireDate];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.numberMasked = [aDecoder decodeObjectForKey:kKeyNumberMasked]; // Only store masked version (last 4 digits) of card number for PCI compliance
        self.type = [aDecoder decodeIntForKey:kKeyCardType];
        self.expireMonth = [aDecoder decodeIntegerForKey:kKeyExpireMonth];
        self.expireYear = [aDecoder decodeIntegerForKey:kKeyExpireYear];
        self.firstName = [aDecoder decodeObjectForKey:kKeyFirstName];
        self.lastName = [aDecoder decodeObjectForKey:kKeyLastName];
        _vaultId = [aDecoder decodeObjectForKey:kKeyVaultId];
        _vaultExpireDate = [aDecoder decodeObjectForKey:kKeyVaultExpireDate];
    }
    
    return self;
}

@end
