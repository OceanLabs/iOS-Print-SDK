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

#import <Foundation/Foundation.h>

#import "OLAddressSearchRequest.h"

@class OLAddress;

@interface OLAddress : NSObject <NSCopying, NSCoding>

+ (OLAddress *)kiteTeamAddress;

+ (OLAddressSearchRequest *)searchForAddressWithCountry:(OLCountry *)country query:(NSString *)q delegate:(id<OLAddressSearchRequestDelegate>)delegate;
+ (OLAddressSearchRequest *)searchForAddress:(OLAddress *)address delegate:(id<OLAddressSearchRequestDelegate>)delegate;

@property (nonatomic, copy) NSString *recipientFirstName;
@property (nonatomic, copy) NSString *recipientLastName;
@property (nonatomic, copy) NSString *line1;
@property (nonatomic, copy) NSString *line2;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *stateOrCounty;
@property (nonatomic, copy) NSString *zipOrPostcode;
@property (nonatomic, strong) OLCountry *country;

@property (nonatomic, readonly, getter = isSearchRequiredForFullDetails) BOOL searchRequiredForFullDetails;

@property (nonatomic, readonly) NSString *descriptionWithoutRecipient;

- (NSString *)fullNameFromFirstAndLast;
- (BOOL) isValidAddress;

@end
