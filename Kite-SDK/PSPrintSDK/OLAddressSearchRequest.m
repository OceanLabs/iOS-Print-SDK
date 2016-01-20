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

#import "OLAddressSearchRequest.h"
#import "OLBaseRequest.h"
#import "OLConstants.h"
#import "OLAddress.h"
#import "OLCountry.h"
#import "OLKitePrintSDK.h"

@interface OLKitePrintSDK (Private)

+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;

@end

static NSString *urlEscapeString(NSString *string) {
    NSString * escaped = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                               NULL,
                                                                                               (CFStringRef)string,
                                                                                               NULL,
                                                                                               CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                               kCFStringEncodingUTF8));
    return escaped;
}


@interface OLAddress (PrivateInitialiser)
- (id)initPartialAddressWithDisplayName:(NSString *)displayName addressId:(NSString *)addressId;
- (NSString *)addressId;
@end

@interface OLAddressSearchRequest ()
@property (nonatomic, strong) OLBaseRequest *inProgressSearchRequest;
@end

@implementation OLAddressSearchRequest

- (void)cancelSearch {
    [self.inProgressSearchRequest cancel];
    self.inProgressSearchRequest = nil;
    self.delegate = nil;
}

- (void)searchForAddressWithCountry:(OLCountry *)country query:(NSString *)q {
    NSString *queryParms = [NSString stringWithFormat:@"search_term=%@&country_code=%@", urlEscapeString(q), urlEscapeString(country.codeAlpha3)];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/address/search?%@", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion], queryParms]];
    [self startSearch:[[OLBaseRequest alloc] initWithURL:url httpMethod:kOLHTTPMethodGET headers:@{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLKitePrintSDK apiKey]]} body:nil] country:country];
}

- (void)searchForAddress:(OLAddress *)address {
    NSString *addressId = [address performSelector:@selector(addressId)];
    NSString *queryParms = nil;
    if (!addressId) {
        if ([address.country.codeAlpha3 isEqualToString:@"GBR"] && address.zipOrPostcode.length > 0) {
            // do a UK search address search
            queryParms = [NSString stringWithFormat:@"postcode=%@&address_line_1=%@&country_code=GBR", urlEscapeString(address.zipOrPostcode), (address.line1 ? urlEscapeString(address.line1) : @"")];
        } else {
            // do an international address search
            queryParms = [NSString stringWithFormat:@"search_term=%@&country_code=%@", urlEscapeString(address.descriptionWithoutRecipient), urlEscapeString(address.country.codeAlpha3)];
        }
    } else {
        // do a search using the address id (these id's are passed back in search results).
        queryParms = [NSString stringWithFormat:@"address_id=%@&country_code=%@", urlEscapeString(addressId), urlEscapeString(address.country.codeAlpha3)];
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/address/search?%@", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion], queryParms]];
    [self startSearch:[[OLBaseRequest alloc] initWithURL:url
                                              httpMethod:kOLHTTPMethodGET
                                                 headers:@{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLKitePrintSDK apiKey]]}
                                                    body:nil]
              country:address.country];
}

- (void)startSearch:(OLBaseRequest *)searchRequest country:(OLCountry *)country {
    NSAssert(self.inProgressSearchRequest == nil, @"Trying to start a new request whilst an existing one is in progress. Cancel first");
    self.inProgressSearchRequest = searchRequest;
    [searchRequest startWithCompletionHandler:^(NSInteger httpStatusCode, id json, NSError *error) {
        self.inProgressSearchRequest = nil;
        if (error) {
            [self.delegate addressSearchRequest:self didFailWithError:error];
            return;
        }
        
        id errorResponse = json[@"error"];
        id choices = json[@"choices"];
        id unique = json[@"unique"];
        
        if (errorResponse) {
            NSString *errorMessage = errorResponse[@"message"];
            [self.delegate addressSearchRequest:self didFailWithError:[NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: errorMessage}]];
        } else if (choices) {
            NSMutableArray *addresses = [[NSMutableArray alloc] init];
            for (id addrComponents in choices) {
                if ([addrComponents isKindOfClass:[NSArray class]]) {
                    OLAddress *partialAddress = [[OLAddress alloc] initPartialAddressWithDisplayName:addrComponents[1] addressId:addrComponents[0]];
                    partialAddress.country = country;
                    [addresses addObject:partialAddress];
                } else if ([addrComponents isKindOfClass:[NSDictionary class]]) {
                    OLAddress *partialAddress = [[OLAddress alloc] initPartialAddressWithDisplayName:addrComponents[@"display_address"] addressId:addrComponents[@"address_id"]];
                    partialAddress.country = country;
                    [addresses addObject:partialAddress];
                }
            }
            
            [self.delegate addressSearchRequest:self didSuceedWithMultipleOptions:addresses];
        } else if (unique) {
            OLAddress *address = [[OLAddress alloc] init];
            address.country = [OLCountry countryForCode:[unique objectForKey:@"country_code"]];
            address.zipOrPostcode = [unique objectForKey:@"postcode"];
            address.line1  = [unique objectForKey:@"address_line_1"];
            address.line2  = [unique objectForKey:@"address_line_2"];
            address.city  = [unique objectForKey:@"city"];
            address.stateOrCounty  = [unique objectForKey:@"county_state"];
            
            [self.delegate addressSearchRequest:self didSuceedWithUniqueAddress:address];
        }
    }];
}





@end
