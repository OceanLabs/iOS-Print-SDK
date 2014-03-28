//
//  OLAddressSearchRequest.h
//  PS SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLCountry;
@class OLAddress;
@class OLAddressSearchRequest;

@protocol OLAddressSearchRequestDelegate <NSObject>
- (void)addressSearchRequest:(OLAddressSearchRequest *)req didSuceedWithMultipleOptions:(NSArray *)options;
- (void)addressSearchRequest:(OLAddressSearchRequest *)req didSuceedWithUniqueAddress:(OLAddress *)addr;
- (void)addressSearchRequest:(OLAddressSearchRequest *)req didFailWithError:(NSError *)error;
@end

@interface OLAddressSearchRequest : NSObject
- (void)cancelSearch;
- (void)searchForAddressWithCountry:(OLCountry *)country query:(NSString *)q;
- (void)searchForAddress:(OLAddress *)address;

@property (nonatomic, weak) id<OLAddressSearchRequestDelegate> delegate;
@end
