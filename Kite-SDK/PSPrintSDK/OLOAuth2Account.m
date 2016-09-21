//
//  NXOAuth2Account.m
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

#import "NSString+OLOAuth2.h"

#import "OLOAuth2ClientDelegate.h"
#import "OLOAuth2TrustDelegate.h"
#import "OLOAuth2AccessToken.h"

#import "OLOAuth2Client.h"
#import "OLOAuth2AccountStore.h"

#import "OLOAuth2Account.h"


#pragma mark Notifications

NSString * const OLOAuth2AccountDidChangeUserDataNotification = @"OLOAuth2AccountDidChangeUserDataNotification";
NSString * const OLOAuth2AccountDidChangeAccessTokenNotification = @"OLOAuth2AccountDidChangeAccessTokenNotification";
NSString * const OLOAuth2AccountDidLoseAccessTokenNotification = @"OLOAuth2AccountDidLoseAccessTokenNotification";
NSString * const OLOAuth2AccountDidFailToGetAccessTokenNotification = @"OLOAuth2AccountDidFailToGetAccessTokenNotification";

#pragma mark -

@interface OLOAuth2Account () <OLOAuth2ClientDelegate, OLOAuth2TrustDelegate>
@end

#pragma mark -

@implementation OLOAuth2Account (Private)

#pragma mark Lifecycle

- (id)initAccountWithOAuthClient:(OLOAuth2Client *)anOAuthClient accountType:(NSString *)anAccountType;
{
    self = [self initAccountWithAccessToken:anOAuthClient.accessToken
                                accountType:anAccountType];
    if (self) {
        oauthClient = anOAuthClient;
    }
    return self;
}

- (id)initAccountWithAccessToken:(OLOAuth2AccessToken *)anAccessToken accountType:(NSString *)anAccountType;
{
    self = [super init];
    if (self) {
        accountType = anAccountType;
        accessToken = anAccessToken;
        oauthClient.delegate = self;
        identifier = [NSString oloauth2_stringWithUUID];
    }
    return self;
}

@end


#pragma mark -

@implementation OLOAuth2Account

@synthesize accountType;
@synthesize identifier;
@synthesize userData;
@synthesize oauthClient;
@synthesize accessToken;


#pragma mark Accessors

- (OLOAuth2Client *)oauthClient;
{
    @synchronized (oauthClient) {
        if (oauthClient == nil) {
            NSDictionary *configuration = [[OLOAuth2AccountStore sharedStore] configurationForAccountType:self.accountType];
            
            NSString *clientID = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationClientID];
            NSString *clientSecret = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationSecret];
            NSURL *authorizeURL = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationAuthorizeURL];
            NSURL *tokenURL = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationTokenURL];
            NSString *tokenType = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationTokenType];
            NSString *keychainGroup = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationTokenType];
            NSDictionary *additionalQueryParams = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters];
            NSDictionary *customHeaderFields = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationCustomHeaderFields];

            oauthClient = [[OLOAuth2Client alloc] initWithClientID:clientID
                                                      clientSecret:clientSecret
                                                      authorizeURL:authorizeURL
                                                          tokenURL:tokenURL
                                                       accessToken:self.accessToken
                                                         tokenType:tokenType
                                                     keyChainGroup:keychainGroup
                                                        persistent:NO
                                                          delegate:self];
            if (additionalQueryParams) {
                oauthClient.additionalAuthenticationParameters = additionalQueryParams;
            }
            
            if (customHeaderFields) {
                oauthClient.customHeaderFields = customHeaderFields;
            }
            
        }
    }
    return oauthClient;
}

- (void)setUserData:(id<NSObject,NSCoding,NSCopying>)someUserData;
{
    if (userData != someUserData) {
        @synchronized (userData) {
            userData = someUserData;
            [[NSNotificationCenter defaultCenter] postNotificationName:OLOAuth2AccountDidChangeUserDataNotification
                                                                object:self];
        }
    }
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<OLOAuth2Account identifier:'%@' accountType:'%@' accessToken:%@ userData:%@>", self.identifier, self.accountType, self.accessToken, self.userData];
}


#pragma mark OLOAuth2TrustDelegate

-(OLOAuth2TrustMode)connection:(OLOAuth2Connection *)connection trustModeForHostname:(NSString *)hostname;
{
    OLOAuth2TrustModeHandler handler = [[OLOAuth2AccountStore sharedStore] trustModeHandlerForAccountType:self.accountType];
    if (handler) {
        return handler(connection, hostname);
    } else {
        return OLOAuth2TrustModeSystem;
    }
}

-(NSArray *)connection:(OLOAuth2Connection *)connection trustedCertificatesForHostname:(NSString *)hostname;
{
    OLOAuth2TrustedCertificatesHandler handler = [[OLOAuth2AccountStore sharedStore] trustedCertificatesHandlerForAccountType:self.accountType];
    return handler(hostname);
}


#pragma mark OLOAuth2ClientDelegate

- (void)oauthClientNeedsAuthentication:(OLOAuth2Client *)client;
{
    // This delegate method will never be called, because an account
    // contains only an authenticated oauch client.
}

- (void)oauthClientDidGetAccessToken:(OLOAuth2Client *)client;
{
    accessToken = oauthClient.accessToken;
    [[NSNotificationCenter defaultCenter] postNotificationName:OLOAuth2AccountDidChangeAccessTokenNotification
                                                        object:self];
}

- (void)oauthClientDidLoseAccessToken:(OLOAuth2Client *)client;
{
    accessToken = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:OLOAuth2AccountDidLoseAccessTokenNotification
                                                        object:self];
}

- (void)oauthClientDidRefreshAccessToken:(OLOAuth2Client *)client;
{
    accessToken = oauthClient.accessToken;
    [[NSNotificationCenter defaultCenter] postNotificationName:OLOAuth2AccountDidChangeAccessTokenNotification
                                                        object:self];
}

- (void)oauthClient:(OLOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;
{
    accessToken = nil;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error
                                                         forKey:OLOAuth2AccountStoreErrorKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:OLOAuth2AccountDidFailToGetAccessTokenNotification
                                                        object:self
                                                      userInfo:userInfo];
}


#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:identifier forKey:@"identifier"];
    [aCoder encodeObject:accountType forKey:@"accountType"];
    [aCoder encodeObject:accessToken forKey:@"accessToken"];
    [aCoder encodeObject:userData forKey:@"userData"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        userData = [aDecoder decodeObjectForKey:@"userData"];
        accessToken = [aDecoder decodeObjectForKey:@"accessToken"];
        accountType = [[aDecoder decodeObjectForKey:@"accountType"] copy];
        identifier = [[aDecoder decodeObjectForKey:@"identifier"] copy];
    }
    return self;
}

@end
