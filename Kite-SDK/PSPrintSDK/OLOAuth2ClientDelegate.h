//
//  NXOAuth2ClientDelegate.h
//  OAuth2Client
//
//  Created by Gernot Poetsch on 14.09.10.
//
//  Copyright 2010 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import "OLOAuth2Constants.h"
#import "OLOAuth2TrustDelegate.h"

@class OLOAuth2Client;

@protocol OLOAuth2ClientDelegate <OLOAuth2TrustDelegate>

@required
/*!
 * When this is called on the delegate, you are supposed to invoke the appropriate authentication method in the client.
 */
- (void)oauthClientNeedsAuthentication:(OLOAuth2Client *)client;

@optional
- (void)oauthClientDidGetAccessToken:(OLOAuth2Client *)client;
- (void)oauthClientDidLoseAccessToken:(OLOAuth2Client *)client;
- (void)oauthClientDidRefreshAccessToken:(OLOAuth2Client *)client;
- (void)oauthClient:(OLOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;

@end
