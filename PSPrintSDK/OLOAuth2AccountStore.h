//
//  NXOAuth2AccountStore.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//
//  Copyright 2011 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>

#import "OLOAuth2TrustDelegate.h"

@class OLOAuth2Account;
@class OLOAuth2Connection;

#pragma mark Notifications

extern NSString * const OLOAuth2AccountStoreDidFailToRequestAccessNotification;
extern NSString * const OLOAuth2AccountStoreAccountsDidChangeNotification;

extern NSString * const OLOAuth2AccountStoreNewAccountUserInfoKey;

#pragma mark Configuration

extern NSString * const kOLOAuth2AccountStoreConfigurationClientID;
extern NSString * const kOLOAuth2AccountStoreConfigurationSecret;
extern NSString * const kOLOAuth2AccountStoreConfigurationAuthorizeURL;
extern NSString * const kOLOAuth2AccountStoreConfigurationTokenURL;
extern NSString * const kOLOAuth2AccountStoreConfigurationRedirectURL;
extern NSString * const kOLOAuth2AccountStoreConfigurationScope;
extern NSString * const kOLOAuth2AccountStoreConfigurationTokenType;
extern NSString * const kOLOAuth2AccountStoreConfigurationTokenRequestHTTPMethod;

/* 
 * Requires a NSDictionary as a value.
 * They are passed onto the authentication request as additional query parameters.
 * The dictionary may not contain the keys "grant_type", "client_id", "client_secret",
 * "username", "password", "redirect_uri", "code", "assertion_type" and "assertion" are not allowed.
 */
extern NSString * const kOLOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters;

/*
 * Requires a NSDictionary as a value.
 * They are passed onto the HTTP Header Fields request as additional parameters.
 * Example of a valid setup: @{ @"Content-type" : @"application/x-www-form-urlencoded" }
 */
extern NSString * const kOLOAuth2AccountStoreConfigurationCustomHeaderFields;


#pragma mark Account Type

extern NSString * const kOLOAuth2AccountStoreAccountType;


#pragma mark Handler

typedef OLOAuth2TrustMode(^OLOAuth2TrustModeHandler)(OLOAuth2Connection *connection, NSString *hostname);
typedef NSArray *(^OLOAuth2TrustedCertificatesHandler)(NSString *hostname);
typedef void(^OLOAuth2PreparedAuthorizationURLHandler)(NSURL *preparedURL);


#pragma mark -

@interface OLOAuth2AccountStore : NSObject {
@private
    NSMutableDictionary *pendingOAuthClients;
    NSMutableDictionary *accountsDict;
    NSMutableDictionary *configurations;
    NSMutableDictionary *trustModeHandler;
    NSMutableDictionary *trustedCertificatesHandler;
}

+ (id)sharedStore;

#pragma mark Accessors

@property(nonatomic, strong, readonly) NSArray *accounts;
- (NSArray *)accountsWithAccountType:(NSString *)accountType;
- (OLOAuth2Account *)accountWithIdentifier:(NSString *)identifier;


#pragma mark Configuration

- (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
   authorizationURL:(NSURL *)anAuthorizationURL
           tokenURL:(NSURL *)aTokenURL
        redirectURL:(NSURL *)aRedirectURL
     forAccountType:(NSString *)anAccountType;

- (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
              scope:(NSSet *)theScope
   authorizationURL:(NSURL *)anAuthorizationURL
           tokenURL:(NSURL *)aTokenURL
        redirectURL:(NSURL *)aRedirectURL
      keyChainGroup:(NSString *)aKeyChainGroup
     forAccountType:(NSString *)anAccountType;

- (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
              scope:(NSSet *)theScope
   authorizationURL:(NSURL *)anAuthorizationURL
           tokenURL:(NSURL *)aTokenURL
        redirectURL:(NSURL *)aRedirectURL
      keyChainGroup:(NSString *)aKeyChainGroup
          tokenType:(NSString *)aTokenType
     forAccountType:(NSString *)anAccountType;

- (void)setConfiguration:(NSDictionary *)configuration forAccountType:(NSString *)accountType;

- (NSDictionary *)configurationForAccountType:(NSString *)accountType;


#pragma Trust Mode Handler

- (void)setTrustModeHandlerForAccountType:(NSString *)accountType block:(OLOAuth2TrustModeHandler)handler;
- (OLOAuth2TrustModeHandler)trustModeHandlerForAccountType:(NSString *)accountType;

- (void)setTrustedCertificatesHandlerForAccountType:(NSString *)accountType block:(OLOAuth2TrustedCertificatesHandler)handler;
- (OLOAuth2TrustedCertificatesHandler)trustedCertificatesHandlerForAccountType:(NSString *)accountType;


#pragma mark Manage Accounts

- (void)requestAccessToAccountWithType:(NSString *)accountType;
- (void)requestAccessToAccountWithType:(NSString *)accountType withPreparedAuthorizationURLHandler:(OLOAuth2PreparedAuthorizationURLHandler)aPreparedAuthorizationURLHandler;
- (void)requestAccessToAccountWithType:(NSString *)accountType username:(NSString *)username password:(NSString *)password;
- (void)requestAccessToAccountWithType:(NSString *)accountType assertionType:(NSURL *)assertionType assertion:(NSString *)assertion;
- (void)requestClientCredentialsAccessWithType:(NSString *)accountType;
- (void)addAccount:(OLOAuth2Account *)account;
- (void)removeAccount:(OLOAuth2Account *)account;


#pragma mark Handle OAuth Redirects

- (BOOL)handleRedirectURL:(NSURL *)URL;

@end
