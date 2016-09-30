//
//  NSString+NXOAuth2.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 07.10.09.
//
//  Copyright 2010 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>


@interface NSString (OLOAuth2)

+ (NSString *)oloauth2_stringWithUUID;

+ (NSString *)oloauth2_stringWithEncodedQueryParameters:(NSDictionary *)parameters;
- (NSDictionary *)oloauth2_parametersFromEncodedQueryString;

- (NSString *)oloauth2_URLEncodedString;
- (NSString *)oloauth2_URLDecodedString;

@end
