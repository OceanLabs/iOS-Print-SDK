//
//  Address.h
//  Kite SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
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

@end
