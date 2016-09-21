//
//  NXOAuth2Account+Private.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 19.07.11.
//
//  Copyright 2011 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import "OLOAuth2Account.h"

@interface OLOAuth2Account (Private)

- (id)initAccountWithOAuthClient:(OLOAuth2Client *)oauthClient accountType:(NSString *)accountType;
- (id)initAccountWithAccessToken:(OLOAuth2AccessToken *)accessToken accountType:(NSString *)accountType;

@end
