//
//  NSData+NXOAuth2.h
//  OAuth2Client
//
//  Created by Thomas Kollbach on 18.05.11
//
//  Copyright 2011 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>


@interface NSData (OLOAuth2)


#pragma mark Digest

- (NSData *)ol_SHA1Digest;
- (NSString *)ol_SHA1Hexdigest;

@end
