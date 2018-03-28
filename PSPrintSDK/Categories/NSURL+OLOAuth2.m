//
//  NSURL+NXOAuth2.m
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

#import "NSString+OLOAuth2.h"

#import "NSURL+OLOAuth2.h"


@implementation NSURL (OLOAuth2)

- (NSURL *)oloauth2_URLByAddingParameters:(NSDictionary *)parameterDictionary {
    if (!parameterDictionary || [parameterDictionary count] == 0) {
        return self;
    }

    NSString *newParameterString = [NSString oloauth2_stringWithEncodedQueryParameters:parameterDictionary];
    
    NSString *absoluteString = [self absoluteString];
    if ([absoluteString rangeOfString:@"?"].location == NSNotFound) {    // append parameters?
        absoluteString = [NSString stringWithFormat:@"%@?%@", absoluteString, newParameterString];
    } else {
        absoluteString = [NSString stringWithFormat:@"%@&%@", absoluteString, newParameterString];
    }

    return [NSURL URLWithString:absoluteString];
}

- (NSString *)oloauth2_valueForQueryParameterKey:(NSString *)key;
{
    //self may not contain a scheme
    //for instance Google API redirect url may look like urn:ietf:wg:oauth:2.0:oob
    //NSURL requires a valid scheme or query will return nil
    NSString *absoluteString = self.absoluteString;
    if ([absoluteString rangeOfString:@"://"].location == NSNotFound) {
        absoluteString = [NSString stringWithFormat:@"http://%@", absoluteString];
    }    
    NSURL *qualifiedURL = [NSURL URLWithString:absoluteString];
    
    NSString *queryString = [qualifiedURL query];
    NSDictionary *parameters = [queryString oloauth2_parametersFromEncodedQueryString];
    return [parameters objectForKey:key];
}

- (NSURL *)oloauth2_URLWithoutQueryString;
{
    return [NSURL URLWithString:[self oloauth2_URLStringWithoutQueryString]];
}

- (NSString *)oloauth2_URLStringWithoutQueryString;
{
    NSArray *parts = [[self absoluteString] componentsSeparatedByString:@"?"];
    return [parts objectAtIndex:0];
}

@end
