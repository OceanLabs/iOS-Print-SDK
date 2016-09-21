//
//  NXOAuth2Client.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//
//  Copyright 2010 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>

#import "OLOAuth2ClientDelegate.h"
#import "OLOAuth2ConnectionDelegate.h"

extern NSString * const OLOAuth2ClientConnectionContextTokenRequest;
extern NSString * const OLOAuth2ClientConnectionContextTokenRefresh;

@class OLOAuth2Connection, OLOAuth2AccessToken;

/*!
 * The OAuth 2.0 client
 * Only supports WebServer & Password flow at the moment
 *
 * - oauth2 draft 10 http://tools.ietf.org/html/draft-ietf-oauth-v2-10
 * - not thread save
 */

//TODO: Link to documentation

@interface OLOAuth2Client : NSObject <OLOAuth2ConnectionDelegate> {
@protected
    BOOL authenticating;
    BOOL persistent;

    NSString    *clientId;
    NSString    *clientSecret;
    
    NSSet       *desiredScope;
    NSString    *userAgent;
    NSString    *assertion;
    NSString    *keyChainGroup;
    
    // server information
    NSURL        *authorizeURL;
    NSURL        *tokenURL;
    NSString     *tokenType;
    
    // token exchange
    OLOAuth2Connection    *authConnection;
    OLOAuth2AccessToken    *accessToken;
    NSMutableArray    *waitingConnections; //for connections that are waiting for successful authorisation
    NSInteger        refreshConnectionDidRetryCount;
    
    // delegates
    NSObject<OLOAuth2ClientDelegate>*    __unsafe_unretained delegate;    // assigned
}

@property (nonatomic, readonly, getter = isAuthenticating) BOOL authenticating;

@property (nonatomic, copy, readonly) NSString *clientId;
@property (nonatomic, copy, readonly) NSString *clientSecret;
@property (nonatomic, copy, readonly) NSString *tokenType;
@property (nonatomic, strong, readwrite) NSDictionary *additionalAuthenticationParameters;
@property (nonatomic, strong, readwrite) NSDictionary *customHeaderFields;

@property (nonatomic, copy) NSSet *desiredScope;
@property (nonatomic, copy) NSString *tokenRequestHTTPMethod; // defaults to POST
@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, copy) NSString *acceptType; // defaults to application/json

@property (nonatomic, strong) OLOAuth2AccessToken    *accessToken;
@property (nonatomic, unsafe_unretained) NSObject<OLOAuth2ClientDelegate>*    delegate;


/*!
 * If set to NO, the access token is not stored any keychain, will be removed if it was.
 * Defaults to YES
 */
@property (nonatomic, assign, readwrite, getter=isPersistent) BOOL persistent;

/*!
 * Initializes the Client
 */
- (id)initWithClientID:(NSString *)clientId
          clientSecret:(NSString *)clientSecret
          authorizeURL:(NSURL *)authorizeURL
              tokenURL:(NSURL *)tokenURL
              delegate:(NSObject<OLOAuth2ClientDelegate> *)delegate;

- (id)initWithClientID:(NSString *)clientId
          clientSecret:(NSString *)clientSecret
          authorizeURL:(NSURL *)authorizeURL
              tokenURL:(NSURL *)tokenURL
           accessToken:(OLOAuth2AccessToken *)accessToken
         keyChainGroup:(NSString *)keyChainGroup
            persistent:(BOOL)shouldPersist
              delegate:(NSObject<OLOAuth2ClientDelegate> *)delegate;

- (id)initWithClientID:(NSString *)clientId
          clientSecret:(NSString *)clientSecret
          authorizeURL:(NSURL *)authorizeURL
              tokenURL:(NSURL *)tokenURL
           accessToken:(OLOAuth2AccessToken *)accessToken
             tokenType:(NSString *)tokenType
         keyChainGroup:(NSString *)keyChainGroup
            persistent:(BOOL)shouldPersist
              delegate:(NSObject<OLOAuth2ClientDelegate> *)delegate;

- (BOOL)openRedirectURL:(NSURL *)URL;


#pragma mark Authorisation Methods

/*---------------------------------*
 * Use ONE of the following flows: *
 *---------------------------------*/

/*!
 * Authenticate usind a web URL (Web Server Flow)
 * returns the URL to be opened to get access grant
 */
- (NSURL *)authorizationURLWithRedirectURL:(NSURL *)redirectURL;

/*!
 * Authenticate with username & password (User Credentials Flow)
 */
- (void)authenticateWithClientCredentials;
- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password;

/*!
 * Authenticate with assertion (Assertion Flow)
 */
- (void)authenticateWithAssertionType:(NSURL *)assertionType assertion:(NSString *)assertion;


#pragma mark Public

- (void)requestAccess;

- (void)refreshAccessToken;
- (void)refreshAccessTokenAndRetryConnection:(OLOAuth2Connection *)retryConnection;

@end
