//
//  NXOAuth2Client.m
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

#import "OLOAuth2Connection.h"
#import "OLOAuth2ConnectionDelegate.h"
#import "OLOAuth2AccessToken.h"

#import "NSURL+OLOAuth2.h"

#import "OLOAuth2Client.h"


NSString * const OLOAuth2ClientConnectionContextTokenRequest = @"tokenRequest";
NSString * const OLOAuth2ClientConnectionContextTokenRefresh = @"tokenRefresh";


@interface OLOAuth2Client ()
@property (nonatomic, readwrite, getter = isAuthenticating) BOOL authenticating;

- (void)requestTokenWithAuthGrant:(NSString *)authGrant redirectURL:(NSURL *)redirectURL;
- (void)removeConnectionFromWaitingQueue:(OLOAuth2Connection *)aConnection;
@end


@implementation OLOAuth2Client


#pragma mark Lifecycle

- (id)initWithClientID:(NSString *)aClientId
          clientSecret:(NSString *)aClientSecret
          authorizeURL:(NSURL *)anAuthorizeURL
              tokenURL:(NSURL *)aTokenURL
              delegate:(NSObject<OLOAuth2ClientDelegate> *)aDelegate;
{
    return [self initWithClientID:aClientId
                     clientSecret:aClientSecret
                     authorizeURL:anAuthorizeURL
                         tokenURL:aTokenURL
                      accessToken:nil
                    keyChainGroup:nil
                       persistent:YES
                         delegate:aDelegate];
}

- (id)initWithClientID:(NSString *)aClientId
          clientSecret:(NSString *)aClientSecret
          authorizeURL:(NSURL *)anAuthorizeURL
              tokenURL:(NSURL *)aTokenURL
           accessToken:(OLOAuth2AccessToken *)anAccessToken
         keyChainGroup:(NSString *)aKeyChainGroup
            persistent:(BOOL)shouldPersist
              delegate:(NSObject<OLOAuth2ClientDelegate> *)aDelegate;
{
    return [self initWithClientID:aClientId
                     clientSecret:aClientSecret
                     authorizeURL:anAuthorizeURL
                         tokenURL:aTokenURL
                      accessToken:anAccessToken
                        tokenType:nil
                    keyChainGroup:aKeyChainGroup
                       persistent:shouldPersist
                         delegate:aDelegate];
}

- (id)initWithClientID:(NSString *)aClientId
          clientSecret:(NSString *)aClientSecret
          authorizeURL:(NSURL *)anAuthorizeURL
              tokenURL:(NSURL *)aTokenURL
           accessToken:(OLOAuth2AccessToken *)anAccessToken
             tokenType:(NSString *)aTokenType
         keyChainGroup:(NSString *)aKeyChainGroup
            persistent:(BOOL)shouldPersist
              delegate:(NSObject<OLOAuth2ClientDelegate> *)aDelegate;
{
    NSAssert(aTokenURL != nil && anAuthorizeURL != nil, @"No token or no authorize URL");
    self = [super init];
    if (self) {
        refreshConnectionDidRetryCount = 0;
        
        clientId = [aClientId copy];
        clientSecret = [aClientSecret copy];
        authorizeURL = [anAuthorizeURL copy];
        tokenURL = [aTokenURL copy];
        tokenType = [aTokenType copy];
        accessToken = anAccessToken;
        
        self.tokenRequestHTTPMethod = @"POST";
        self.acceptType = @"application/json";
        keyChainGroup = aKeyChainGroup;
        
        self.persistent = shouldPersist;
        self.delegate = aDelegate;
    }
    return self;
}

- (void)dealloc;
{
    [authConnection cancel];
}


#pragma mark Accessors

@synthesize clientId, clientSecret, tokenType;
@synthesize desiredScope, userAgent;
@synthesize delegate, persistent, accessToken, authenticating;
@synthesize additionalAuthenticationParameters;

- (void)setAdditionalAuthenticationParameters:(NSDictionary *)value;
{
    if (value == additionalAuthenticationParameters) return;
    
    NSArray *forbiddenKeys = @[ @"grant_type", @"client_id",
                                @"client_secret",
                                @"username", @"password",
                                @"redirect_uri", @"code",
                                @"assertion_type", @"assertion" ];
    
    for (id key in value) {
        if ([forbiddenKeys containsObject:key]) {
            [[NSException exceptionWithName:NSInvalidArgumentException
                                     reason:[NSString stringWithFormat:@"'%@' is not allowed as a key for additionalAuthenticationParameters", key]
                                   userInfo:nil] raise];
        }
    }
    
    additionalAuthenticationParameters = value;
    
    
}

- (void)setPersistent:(BOOL)shouldPersist;
{
    if (persistent == shouldPersist) return;
    
    if (shouldPersist && accessToken) {
        [self.accessToken storeInDefaultKeychainWithServiceProviderName:keyChainGroup ? keyChainGroup : [tokenURL host]];
    }
    
    if (persistent && !shouldPersist) {
        [accessToken removeFromDefaultKeychainWithServiceProviderName:keyChainGroup ? keyChainGroup : [tokenURL host]];
    }

    [self willChangeValueForKey:@"persistent"];
    persistent = shouldPersist;
    [self didChangeValueForKey:@"persistent"];
}

- (OLOAuth2AccessToken *)accessToken;
{
    if (accessToken) return accessToken;
    
    if (persistent) {
        accessToken = [OLOAuth2AccessToken tokenFromDefaultKeychainWithServiceProviderName:keyChainGroup ? keyChainGroup : [tokenURL host]];
        if (accessToken) {
            if ([delegate respondsToSelector:@selector(oauthClientDidGetAccessToken:)]) {
                [delegate oauthClientDidGetAccessToken:self];
            }
        }
        return accessToken;
    } else {
        return nil;
    }
}

- (void)setAccessToken:(OLOAuth2AccessToken *)value;
{
    if (self.accessToken == value) return;
    BOOL authorisationStatusChanged = ((accessToken == nil)    || (value == nil)); //They can't both be nil, see one line above. So they have to have changed from or to nil.
    
    if (!value) {
        [self.accessToken removeFromDefaultKeychainWithServiceProviderName:keyChainGroup ? keyChainGroup : [tokenURL host]];
    }
    
    [self willChangeValueForKey:@"accessToken"];
    accessToken = value;
    [self didChangeValueForKey:@"accessToken"];
    
    if (persistent) {
        [accessToken storeInDefaultKeychainWithServiceProviderName:keyChainGroup ? keyChainGroup : [tokenURL host]];
    }
    
    if (authorisationStatusChanged) {
        if (accessToken) {
            if ([delegate respondsToSelector:@selector(oauthClientDidGetAccessToken:)]) {
                [delegate oauthClientDidGetAccessToken:self];
            }
        } else {
            if ([delegate respondsToSelector:@selector(oauthClientDidLoseAccessToken:)]) {
                [delegate oauthClientDidLoseAccessToken:self];
            }
        }
    } else {
        if ([delegate respondsToSelector:@selector(oauthClientDidRefreshAccessToken:)]) {
            [delegate oauthClientDidRefreshAccessToken:self];
        }
    }
}

- (void)setDesiredScope:(NSSet *)aDesiredScope;
{
    if (desiredScope == aDesiredScope) {
        return;
    }
    
    desiredScope = [aDesiredScope copy];
}


#pragma mark Flow

- (void)requestAccess;
{
    if (!self.accessToken) {
        [delegate oauthClientNeedsAuthentication:self];
    }
}

- (NSURL *)authorizationURLWithRedirectURL:(NSURL *)redirectURL;
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"code", @"response_type",
                                       clientId, @"client_id",
                                       [redirectURL absoluteString], @"redirect_uri",
                                       nil];
    
    if (self.additionalAuthenticationParameters) {
        [parameters addEntriesFromDictionary:self.additionalAuthenticationParameters];
    }
    
    if (self.desiredScope.count > 0) {
        [parameters setObject:[[self.desiredScope allObjects] componentsJoinedByString:@" "] forKey:@"scope"];
    }
    
    return [authorizeURL oloauth2_URLByAddingParameters:parameters];
}


// Web Server Flow only
- (BOOL)openRedirectURL:(NSURL *)URL;
{
    NSString *accessGrant = [URL oloauth2_valueForQueryParameterKey:@"code"];
    if (accessGrant) {
        [self requestTokenWithAuthGrant:accessGrant redirectURL:[URL oloauth2_URLWithoutQueryString]];
        return YES;
    }
    
    NSString *errorString = [URL oloauth2_valueForQueryParameterKey:@"error"];
    if (errorString) {
        NSInteger errorCode = 0;
        NSString *localizedError = nil;
        
        if ([errorString caseInsensitiveCompare:@"invalid_request"] == NSOrderedSame) {
            errorCode = OLOAuth2InvalidRequestErrorCode;
            localizedError = @"Invalid request to OAuth2 Server"; //LocalizedString(@"Invalid request to OAuth2 Server", @"OLOAuth2InvalidRequestErrorCode description");
            
        } else if ([errorString caseInsensitiveCompare:@"invalid_client"] == NSOrderedSame) {
            errorCode = OLOAuth2InvalidClientErrorCode;
            localizedError = @"Invalid OAuth2 Client"; //LocalizedString(@"Invalid OAuth2 Client", @"OLOAuth2InvalidClientErrorCode description");
            
        } else if ([errorString caseInsensitiveCompare:@"unauthorized_client"] == NSOrderedSame) {
            errorCode = OLOAuth2UnauthorizedClientErrorCode;
            localizedError = @"Unauthorized Client"; //LocalizedString(@"Unauthorized Client", @"OLOAuth2UnauthorizedClientErrorCode description");
            
        } else if ([errorString caseInsensitiveCompare:@"redirect_uri_mismatch"] == NSOrderedSame) {
            errorCode = OLOAuth2RedirectURIMismatchErrorCode;
            localizedError = @"Redirect URI mismatch"; //LocalizedString(@"Redirect URI mismatch", @"OLOAuth2RedirectURIMismatchErrorCode description");
            
        } else if ([errorString caseInsensitiveCompare:@"access_denied"] == NSOrderedSame) {
            errorCode = OLOAuth2AccessDeniedErrorCode;
            localizedError = @"Access denied"; //LocalizedString(@"Access denied", @"OLOAuth2AccessDeniedErrorCode description");
            
        } else if ([errorString caseInsensitiveCompare:@"unsupported_response_type"] == NSOrderedSame) {
            errorCode = OLOAuth2UnsupportedResponseTypeErrorCode;
            localizedError = @"Unsupported response type"; //LocalizedString(@"Unsupported response type", @"OLOAuth2UnsupportedResponseTypeErrorCode description");
            
        } else if ([errorString caseInsensitiveCompare:@"invalid_scope"] == NSOrderedSame) {
            errorCode = OLOAuth2InvalidScopeErrorCode;
            localizedError = @"Invalid scope"; //LocalizedString(@"Invalid scope", @"OLOAuth2InvalidScopeErrorCode description");
        }
        
        if (errorCode != 0) {
            NSDictionary *userInfo = nil;
            if (localizedError) {
                userInfo = [NSDictionary dictionaryWithObject:localizedError forKey:NSLocalizedDescriptionKey];
            }
            if ([delegate respondsToSelector:@selector(oauthClient:didFailToGetAccessTokenWithError:)]) {
                [delegate oauthClient:self didFailToGetAccessTokenWithError:[NSError errorWithDomain:OLOAuth2ErrorDomain
                                                                                                code:errorCode
                                                                                            userInfo:userInfo]];
            }
        }
    }
    return NO;
}

#pragma mark Request Token

// Web Server Flow only
- (void)requestTokenWithAuthGrant:(NSString *)authGrant redirectURL:(NSURL *)redirectURL;
{
    NSAssert1(!authConnection, @"authConnection already running with: %@", authConnection);
    
    NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
    [tokenRequest setHTTPMethod:self.tokenRequestHTTPMethod];
    [authConnection cancel];  // just to be sure

    self.authenticating = YES;

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"authorization_code", @"grant_type",
                                       clientId, @"client_id",
                                       clientSecret, @"client_secret",
                                       [redirectURL absoluteString], @"redirect_uri",
                                       authGrant, @"code",
                                       nil];
    if (self.desiredScope) {
        [parameters setObject:[[self.desiredScope allObjects] componentsJoinedByString:@" "] forKey:@"scope"];
    }
    
    if (self.customHeaderFields) {
        [self.customHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            [tokenRequest addValue:obj forHTTPHeaderField:key];
        }];
    }
    
    if (self.additionalAuthenticationParameters) {
        [parameters addEntriesFromDictionary:self.additionalAuthenticationParameters];
    }
    
    authConnection = [[OLOAuth2Connection alloc] initWithRequest:tokenRequest
                                               requestParameters:parameters
                                                     oauthClient:self
                                                        delegate:self];
    authConnection.context = OLOAuth2ClientConnectionContextTokenRequest;
}

// Client Credential Flow
- (void)authenticateWithClientCredentials;
{
    NSAssert1(!authConnection, @"authConnection already running with: %@", authConnection);
    
    NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
    [tokenRequest setHTTPMethod:self.tokenRequestHTTPMethod];
    [authConnection cancel];  // just to be sure
    
    self.authenticating = YES;
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"client_credentials", @"grant_type",
                                       clientId, @"client_id",
                                       clientSecret, @"client_secret",
                                       nil];
    if (self.desiredScope) {
        [parameters setObject:[[self.desiredScope allObjects] componentsJoinedByString:@" "] forKey:@"scope"];
    }
    
    if (self.customHeaderFields) {
        [self.customHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            [tokenRequest addValue:obj forHTTPHeaderField:key];
        }];
    }
    
    authConnection = [[OLOAuth2Connection alloc] initWithRequest:tokenRequest
                                               requestParameters:parameters
                                                     oauthClient:self
                                                        delegate:self];
    authConnection.context = OLOAuth2ClientConnectionContextTokenRequest;
}

// User Password Flow Only
- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password;
{
    NSAssert1(!authConnection, @"authConnection already running with: %@", authConnection);
    
    NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
    [tokenRequest setHTTPMethod:self.tokenRequestHTTPMethod];
    [authConnection cancel];  // just to be sure

    self.authenticating = YES;

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"password", @"grant_type",
                                       clientId, @"client_id",
                                       clientSecret, @"client_secret",
                                       username, @"username",
                                       password, @"password",
                                       nil];
    if (self.desiredScope) {
        [parameters setObject:[[self.desiredScope allObjects] componentsJoinedByString:@" "] forKey:@"scope"];
    }
    
    if (self.additionalAuthenticationParameters) {
        [parameters addEntriesFromDictionary:self.additionalAuthenticationParameters];
    }
    
    if (self.customHeaderFields) {
        [self.customHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            [tokenRequest addValue:obj forHTTPHeaderField:key];
        }];
    }
    
    authConnection = [[OLOAuth2Connection alloc] initWithRequest:tokenRequest
                                               requestParameters:parameters
                                                     oauthClient:self
                                                        delegate:self];
    authConnection.context = OLOAuth2ClientConnectionContextTokenRequest;
}

// Assertion
- (void)authenticateWithAssertionType:(NSURL *)anAssertionType assertion:(NSString *)anAssertion;
{
    NSAssert1(!authConnection, @"authConnection already running with: %@", authConnection);
    NSParameterAssert(anAssertionType);
    NSParameterAssert(anAssertion);
    
    NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
    [tokenRequest setHTTPMethod:self.tokenRequestHTTPMethod];
    [authConnection cancel];  // just to be sure
    
    self.authenticating = YES;
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"assertion", @"grant_type",
                                       clientId, @"client_id",
                                       clientSecret, @"client_secret",
                                       anAssertionType.absoluteString, @"assertion_type",
                                       anAssertion, @"assertion",
                                       nil];
    if (self.desiredScope) {
        [parameters setObject:[[self.desiredScope allObjects] componentsJoinedByString:@" "] forKey:@"scope"];
    }
    authConnection = [[OLOAuth2Connection alloc] initWithRequest:tokenRequest
                                               requestParameters:parameters
                                                     oauthClient:self
                                                        delegate:self];
    authConnection.context = OLOAuth2ClientConnectionContextTokenRequest;
}

#pragma mark Public

- (void)refreshAccessToken
{
    [self refreshAccessTokenAndRetryConnection:nil];
}

- (void)refreshAccessTokenAndRetryConnection:(OLOAuth2Connection *)retryConnection;
{
    if (retryConnection) {
        if (!waitingConnections) waitingConnections = [[NSMutableArray alloc] init];
        [waitingConnections addObject:retryConnection];
    }
    if (!authConnection) {
        NSAssert((accessToken.refreshToken != nil), @"invalid state");
        NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:tokenURL];
        [tokenRequest setHTTPMethod:self.tokenRequestHTTPMethod];
        [authConnection cancel]; // not needed, but looks more clean to me :)
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           @"refresh_token", @"grant_type",
                                           clientId, @"client_id",
                                           clientSecret, @"client_secret",
                                           accessToken.refreshToken, @"refresh_token",
                                           nil];
        if (self.desiredScope) {
            [parameters setObject:[[self.desiredScope allObjects] componentsJoinedByString:@" "] forKey:@"scope"];
        }
        authConnection = [[OLOAuth2Connection alloc] initWithRequest:tokenRequest
                                                   requestParameters:parameters
                                                         oauthClient:self
                                                            delegate:self];
        authConnection.context = OLOAuth2ClientConnectionContextTokenRefresh;
    }
}

- (void)removeConnectionFromWaitingQueue:(OLOAuth2Connection *)aConnection;
{
    if (!aConnection) return;
    [waitingConnections removeObject:aConnection];
}


#pragma mark OLOAuth2ConnectionDelegate

- (void)oauthConnection:(OLOAuth2Connection *)connection didFinishWithData:(NSData *)data;
{
    if (connection == authConnection) {
        self.authenticating = NO;

        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        OLOAuth2AccessToken *newToken = [OLOAuth2AccessToken tokenWithResponseBody:result tokenType:self.tokenType
                                         ];
        NSAssert(newToken != nil, @"invalid response?");
        
        [newToken restoreWithOldToken:self.accessToken];
        
        self.accessToken = newToken;
        
        for (OLOAuth2Connection *retryConnection in waitingConnections) {
            [retryConnection retry];
        }
        [waitingConnections removeAllObjects];
        
        authConnection = nil;
        
        refreshConnectionDidRetryCount = 0;    // reset
    }
}

- (void)oauthConnection:(OLOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
    NSString *body = [[NSString alloc] initWithData:connection.data encoding:NSUTF8StringEncoding];
    NSLog(@"oauthConnection Error: %@", body);
    
    
    if (connection == authConnection) {
        self.authenticating = NO;

        id context = connection.context;
        authConnection = nil;
        
        if ([context isEqualToString:OLOAuth2ClientConnectionContextTokenRefresh]
            && [[error domain] isEqualToString:OLOAuth2HTTPErrorDomain]
            && error.code >= 500 && error.code < 600
            && refreshConnectionDidRetryCount < 4) {
            
            // no token refresh because of a server issue. don't give up just yet.
            [self performSelector:@selector(refreshAccessToken) withObject:nil afterDelay:1];
            refreshConnectionDidRetryCount++;
            
        } else {
            if ([context isEqualToString:OLOAuth2ClientConnectionContextTokenRefresh]) {
                NSError *retryFailedError = [NSError errorWithDomain:OLOAuth2ErrorDomain
                                                                code:OLOAuth2CouldNotRefreshTokenErrorCode
                                                            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                      @"Access token could not be refreshed", NSLocalizedDescriptionKey,
                                                                      nil]];
                
                NSArray *failedConnections = [waitingConnections copy];
                [waitingConnections removeAllObjects];
                for (OLOAuth2Connection *connection in failedConnections) {
                    id<OLOAuth2ConnectionDelegate> connectionDelegate = connection.delegate;
                        if ([connectionDelegate respondsToSelector:@selector(oauthConnection:didFailWithError:)]) {
                        [connectionDelegate oauthConnection:connection didFailWithError:retryFailedError];
                    }
                }
            }
            
            if ([[error domain] isEqualToString:OLOAuth2HTTPErrorDomain]
                && error.code == 401) {
                self.accessToken = nil;        // reset the token since it got invalid
            }
            
            if ([delegate respondsToSelector:@selector(oauthClient:didFailToGetAccessTokenWithError:)]) {
                [delegate oauthClient:self didFailToGetAccessTokenWithError:error];
            }
        }
    }
}

@end
