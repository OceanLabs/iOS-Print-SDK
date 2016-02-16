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

#import "OLAddress.h"
#import "OLCountry.h"

static NSString *const kKeyDisplayName = @"co.oceanlabs.pssdk.kKeyDisplayName";
static NSString *const kKeyAddressId = @"co.oceanlabs.pssdk.kKeyAddressId";
static NSString *const kKeyRecipientName = @"co.oceanlabs.pssdk.kKeyRecipientName";
static NSString *const kKeyRecipientFirstName = @"co.oceanlabs.pssdk.kKeyRecipientFirstName";
static NSString *const kKeyLine1 = @"co.oceanlabs.pssdk.kKeyLine1";
static NSString *const kKeyLine2 = @"co.oceanlabs.pssdk.kKeyLine2";
static NSString *const kKeyCity = @"co.oceanlabs.pssdk.kKeyCity";
static NSString *const kKeyStateOrCounty = @"co.oceanlabs.pssdk.kKeyStateOrCounty";
static NSString *const kKeyZipOrPostcode = @"co.oceanlabs.pssdk.kKeyZipOrPostcode";
static NSString *const kKeyCountryCode = @"co.oceanlabs.pssdk.kKeyCountryCode";

@interface OLAddress ()
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *addressId;
@end

@implementation OLAddress

+ (OLAddress *)kiteTeamAddress {
    OLAddress *addr = [[OLAddress alloc] init];
    addr.recipientFirstName = @"Kite";
    addr.recipientLastName = @"Team";
    addr.line1 = @"Eastcastle House";
    addr.line2 = @"27-28 Eastcastle St";
    addr.city  = @"London";
    addr.zipOrPostcode = @"W1W 8DH";
    addr.country = [OLCountry countryForCode:@"GBR"];
    return addr;
}

+ (OLAddressSearchRequest *)searchForAddressWithCountry:(OLCountry *)country query:(NSString *)q delegate:(id<OLAddressSearchRequestDelegate>)delegate {
    NSAssert(delegate != nil, @"please supply a non nil delegate");
    NSAssert(country != nil && q != nil, @"Please provide a country and query string at the very least when doing a search for an international address");
    OLAddressSearchRequest *req = [[OLAddressSearchRequest alloc] init];
    req.delegate = delegate;
    [req searchForAddressWithCountry:country query:q];
    return req;
}

- (id)initPartialAddressWithDisplayName:(NSString *)displayName addressId:(NSString *)addressId {
    if (self = [super init]) {
        self.displayName = displayName;
        self.addressId = addressId;
        _searchRequiredForFullDetails = YES;
    }
    
    return self;
}

+ (OLAddressSearchRequest *)searchForAddress:(OLAddress *)address delegate:(id<OLAddressSearchRequestDelegate>)delegate {
    OLAddressSearchRequest *req = [[OLAddressSearchRequest alloc] init];
    req.delegate = delegate;
    [req searchForAddress:address];
    return req;
}

- (NSString *)description {
    if (self.displayName) {
        return self.displayName;
    }
    
    NSString *displayName = self.descriptionWithoutRecipient;
    if (self.recipientFirstName || self.recipientLastName) {
        if (displayName.length > 0) {
            return [[self fullNameFromFirstAndLast] stringByAppendingFormat:@", %@", self.descriptionWithoutRecipient];
        } else {
            return [self fullNameFromFirstAndLast];
        }
    }
    
    return displayName;
}

- (NSString *)fullNameFromFirstAndLast{
    return [[NSString stringWithFormat:@"%@ %@", self.recipientFirstName ? self.recipientFirstName : @"", self.recipientLastName ? self.recipientLastName : @""] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
}

- (BOOL)isValidAddress{
    if (!self.recipientFirstName || [self.recipientFirstName isEqualToString:@""] || !self.recipientLastName || [self.recipientLastName isEqualToString:@""]){
        return NO;
    }
    else if (!self.line1 || [self.line1 isEqualToString:@""]){
        return NO;
    }
    else if (!self.zipOrPostcode || [self.zipOrPostcode isEqualToString:@""]){
        return NO;
    }
    else if (!self.country){
        return NO;
    }
    return YES;
}

- (NSString *)descriptionWithoutRecipient {
    NSString *displayName = @"";
    NSMutableArray *addrParts = [[NSMutableArray alloc] init];
    if (self.line1) [addrParts addObject:self.line1];
    if (self.line2) [addrParts addObject:self.line2];
    if (self.city) [addrParts addObject:self.city];
    if (self.stateOrCounty) [addrParts addObject:self.stateOrCounty];
    if (self.zipOrPostcode) [addrParts addObject:self.zipOrPostcode];
    if (self.country) [addrParts addObject:self.country.name];
    
    for (NSString *part in addrParts) {
        if (part.length > 0) {
            if (displayName.length > 0) {
                displayName = [displayName stringByAppendingString:@", "];
            }
            displayName = [displayName stringByAppendingString:part];
        }
    }
    
    return displayName;
}

static BOOL stringEqualOrBothNil(NSString *a, NSString *b) {
    if (a == nil && b == nil) {
        return YES;
    }
    
    return [a isEqualToString:b];
}

- (BOOL)isEqual:(id)object {
    if (![object isMemberOfClass:[OLAddress class]]) {
        return NO;
    }
    
    OLAddress *addr = object;
    return stringEqualOrBothNil(self.recipientFirstName, addr.recipientFirstName)
    && stringEqualOrBothNil(self.recipientLastName, addr.recipientLastName)
    && stringEqualOrBothNil(self.line1, addr.line1)
    && stringEqualOrBothNil(self.line2, addr.line2)
    && stringEqualOrBothNil(self.city, addr.city)
    && stringEqualOrBothNil(self.stateOrCounty, addr.stateOrCounty)
    && stringEqualOrBothNil(self.zipOrPostcode, addr.zipOrPostcode)
    && self.country == addr.country;
}

- (NSUInteger)hash {
    NSMutableArray *components = [[NSMutableArray alloc] init];
    if (self.recipientFirstName) [components addObject:self.recipientFirstName];
    if (self.recipientLastName) [components addObject:self.recipientLastName];
    if (self.line1) [components addObject:self.line1];
    if (self.line2) [components addObject:self.line2];
    if (self.city) [components addObject:self.city];
    if (self.stateOrCounty) [components addObject:self.stateOrCounty];
    if (self.zipOrPostcode) [components addObject:self.zipOrPostcode];
    if (self.country) [components addObject:self.country];
    
    NSUInteger hash = 17;
    for (id component in components) {
        hash = 31 * hash + [component hash];
    }
    
    return hash;
}

#pragma mark - NSCopying methods

- (id)copyWithZone:(NSZone *)zone {
    OLAddress *copy = [[OLAddress alloc] init];
    copy.displayName = self.displayName;
    copy.addressId = self.addressId;
    copy.recipientFirstName = self.recipientFirstName;
    copy.recipientLastName = self.recipientLastName;
    copy.line1 = self.line1;
    copy.line2 = self.line2;
    copy.city = self.city;
    copy.stateOrCounty = self.stateOrCounty;
    copy.zipOrPostcode = self.zipOrPostcode;
    copy.country = self.country;
    NSAssert([copy isEqual:self], @"oops that's some bad copying!");
    return copy;
}

#pragma mark - NSCoding methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.displayName forKey:kKeyDisplayName];
    [aCoder encodeObject:self.addressId forKey:kKeyAddressId];
    [aCoder encodeObject:self.recipientLastName forKey:kKeyRecipientName];
    [aCoder encodeObject:self.recipientFirstName forKey:kKeyRecipientFirstName];
    [aCoder encodeObject:self.line1 forKey:kKeyLine1];
    [aCoder encodeObject:self.line2 forKey:kKeyLine2];
    [aCoder encodeObject:self.city forKey:kKeyCity];
    [aCoder encodeObject:self.stateOrCounty forKey:kKeyStateOrCounty];
    [aCoder encodeObject:self.zipOrPostcode forKey:kKeyZipOrPostcode];
    [aCoder encodeObject:self.country.codeAlpha3 forKey:kKeyCountryCode];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.displayName = [aDecoder decodeObjectForKey:kKeyDisplayName];
        self.addressId = [aDecoder decodeObjectForKey:kKeyAddressId];
        self.recipientLastName = [aDecoder decodeObjectForKey:kKeyRecipientName];
        self.recipientFirstName = [aDecoder decodeObjectForKey:kKeyRecipientFirstName];
        self.line1 = [aDecoder decodeObjectForKey:kKeyLine1];
        self.line2 = [aDecoder decodeObjectForKey:kKeyLine2];
        self.city = [aDecoder decodeObjectForKey:kKeyCity];
        self.stateOrCounty = [aDecoder decodeObjectForKey:kKeyStateOrCounty];
        self.zipOrPostcode = [aDecoder decodeObjectForKey:kKeyZipOrPostcode];
        self.country = [OLCountry countryForCode:[aDecoder decodeObjectForKey:kKeyCountryCode]];
    }
    
    return self;
}


@end
