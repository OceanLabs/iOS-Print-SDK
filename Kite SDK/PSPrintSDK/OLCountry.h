//
//  OLCountry.h
//  Kite SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLCountry : NSObject
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *codeAlpha2;
@property (nonatomic, readonly) NSString *codeAlpha3;
@property (nonatomic, readonly) NSString *currencyCode;
@property (nonatomic, readonly, getter=isInEurope) BOOL inEurope;

+ (NSArray *)countries;
+ (OLCountry *)countryForCode:(NSString *)code;
+ (OLCountry *)countryForCurrentLocale;
+ (OLCountry *)countryForName:(NSString *)name;

@end
