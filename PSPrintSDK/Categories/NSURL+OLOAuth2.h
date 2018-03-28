//
//  NSURL+NXOAuth2.h
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

@interface NSURL (OLOAuth2)

- (NSURL *)oloauth2_URLByAddingParameters:(NSDictionary *)parameters;

/*!
 * returns the value of the first parameter on the query string that matches the key
 * returns nil if key was not found
 */
- (NSString *)oloauth2_valueForQueryParameterKey:(NSString *)key;

- (NSURL *)oloauth2_URLWithoutQueryString;
- (NSString *)oloauth2_URLStringWithoutQueryString;

@end
