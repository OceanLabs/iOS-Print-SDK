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

#import "OLStripeCard.h"
#import "NSString+Formatting.h"

static NSString *const kKeyNumberMasked = @"co.oceanlabs.Stripe.kKeyNumberMasked";
static NSString *const kKeyCustomerId = @"co.oceanlabs.Stripe.kKeyCustomerId";

static NSString *const kOLErrorDomainStripe = @"co.oceanlabs.Stripe.kOLErrorDomainStripe";

#define kErrorMessageBadCardNumber NSLocalizedStringFromTableInBundle(@"Please enter a valid card number", @"KitePrintSDK", [OLConstants bundle], @"")
#define kErrorMessageBadExpiryDate NSLocalizedStringFromTableInBundle(@"Please enter a card expiry date in the future", @"KitePrintSDK", [OLConstants bundle], @"")


static NSString *clientId;

typedef void (^OLStripeCardAccessTokenCompletionHandler)(NSString *accessToken, NSError *error);

static OLStripeCard *lastUsedCard;

@implementation OLStripeCard

+ (void)setClientId:(NSString *)_clientId{
    clientId = _clientId;
}

+ (NSString *)lastUsedCardFilePath {
    NSArray * urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString *documentDirPath = [(NSURL *)[urls objectAtIndex:0] path];
    return [documentDirPath stringByAppendingPathComponent:@"co.oceanlabs.Stripe.luc"];
}

+ (OLStripeCard *)lastUsedCard {
    if (!lastUsedCard) {
        lastUsedCard = [NSKeyedUnarchiver unarchiveObjectWithFile:[OLStripeCard lastUsedCardFilePath]];
    }
    
    return lastUsedCard;
}

+ (void)clearLastUsedCard {
    lastUsedCard = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[OLStripeCard lastUsedCardFilePath] error:nil];
}

- (NSString *)numberMasked{
    return [self.number substringFromIndex:self.number.length - 5];
}

- (void)saveAsLastUsedCard {
    lastUsedCard = self;
    
    //Uncomment the following line when the Kite server sends us the customer ID that we can save as this card.
//    [NSKeyedArchiver archiveRootObject:lastUsedCard toFile:[OLStripeCard lastUsedCardFilePath]];
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

//- (void)storeCardWithCompletionHandler:(OLStripeCardStoreCompletionHandler)handler {
//   
//}

- (void)chargeCard:(NSDecimalNumber *)amount currencyCode:(NSString *)currencyCode description:(NSString *)description completionHandler:(OLStripeCardChargeCompletionHandler)handler {
    NSDictionary *params = @{@"number": self.number,
                             @"exp_month": [NSString stringWithFormat:@"%lu", (unsigned long) self.expireMonth],
                             @"exp_year": [NSString stringWithFormat:@"%lu", (unsigned long) self.expireYear],
                             @"cvc": self.cvv2
                             };
    
    NSMutableArray *parts = [NSMutableArray array];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id val, __unused BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"card[%@]=%@", key, [NSString stringByURLEncoding:val]]];
        
    }];
    
    NSData *data = [[parts componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.stripe.com/v1/tokens"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    [request setValue:[@"Bearer " stringByAppendingString:clientId] forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                  delegate:nil
                             delegateQueue:nil];
    [[session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error){
                NSError *error;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error){
                    handler(nil, [NSError errorWithDomain:@"com.stripe" code:400 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"There was an error trying to validate the card. Please try again later.", @"")}]);
                }
                else if (json[@"error"]){
                    handler(nil, [NSError errorWithDomain:@"com.stripe" code:400 userInfo:@{NSLocalizedDescriptionKey : json[@"error"][@"message"]}]);
                }
                else{
                    handler(json[@"id"], nil);
                }
            }
            else{
                handler(nil, error);
            }
        });
    }] resume];
}

#pragma mark - NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.numberMasked forKey:kKeyNumberMasked];
    [aCoder encodeObject:self.customerId forKey:kKeyCustomerId];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.numberMasked = [aDecoder decodeObjectOfClass:[NSString class] forKey:kKeyNumberMasked]; // Only store masked version (last 4 digits) of card number for PCI compliance
        self.customerId = [aDecoder decodeObjectOfClass:[NSString class] forKey:kKeyCustomerId];
    }
    
    return self;
}

+(BOOL)supportsSecureCoding{
    return YES;
}

@end
