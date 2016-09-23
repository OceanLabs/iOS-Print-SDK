//
//  NXOAuth2AccountStore.m
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

#import <UIKit/UIKit.h>

#import "OLOAuth2Client.h"
#import "OLOAuth2Connection.h"
#import "OLOAuth2Account.h"
#import "OLOAuth2Account+Private.h"

#import "OLOAuth2AccountStore.h"


#pragma mark Notifications

NSString * const OLOAuth2AccountStoreDidFailToRequestAccessNotification = @"OLOAuth2AccountStoreDidFailToRequestAccessNotification";
NSString * const OLOAuth2AccountStoreAccountsDidChangeNotification = @"OLOAuth2AccountStoreAccountsDidChangeNotification";

NSString * const OLOAuth2AccountStoreNewAccountUserInfoKey = @"OLOAuth2AccountStoreNewAccountUserInfoKey";

#pragma mark Configuration

NSString * const kOLOAuth2AccountStoreConfigurationClientID = @"kOLOAuth2AccountStoreConfigurationClientID";
NSString * const kOLOAuth2AccountStoreConfigurationSecret = @"kOLOAuth2AccountStoreConfigurationSecret";
NSString * const kOLOAuth2AccountStoreConfigurationAuthorizeURL = @"kOLOAuth2AccountStoreConfigurationAuthorizeURL";
NSString * const kOLOAuth2AccountStoreConfigurationTokenURL = @"kOLOAuth2AccountStoreConfigurationTokenURL";
NSString * const kOLOAuth2AccountStoreConfigurationRedirectURL = @"kOLOAuth2AccountStoreConfigurationRedirectURL";
NSString * const kOLOAuth2AccountStoreConfigurationScope = @"kOLOAuth2AccountStoreConfigurationScope";
NSString * const kOLOAuth2AccountStoreConfigurationTokenType = @"kOLOAuth2AccountStoreConfigurationTokenType";
NSString * const kOLOAuth2AccountStoreConfigurationTokenRequestHTTPMethod = @"kOLOAuth2AccountStoreConfigurationTokenRequestHTTPMethod";
NSString * const kOLOAuth2AccountStoreConfigurationKeyChainGroup = @"kOLOAuth2AccountStoreConfigurationKeyChainGroup";
NSString * const kOLOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters = @"kOLOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters";
NSString * const kOLOAuth2AccountStoreConfigurationCustomHeaderFields = @"kOLOAuth2AccountStoreConfigurationCustomHeaderFields";

#pragma mark Account Type

NSString * const kOLOAuth2AccountStoreAccountType = @"kOLOAuth2AccountStoreAccountType";

#pragma mark -


@interface OLOAuth2AccountStore () <OLOAuth2ClientDelegate, OLOAuth2TrustDelegate>
@property (nonatomic, strong, readwrite) NSMutableDictionary *pendingOAuthClients;
@property (nonatomic, strong, readwrite) NSMutableDictionary *accountsDict;

@property (nonatomic, strong, readwrite) NSMutableDictionary *configurations;
@property (nonatomic, strong, readwrite) NSMutableDictionary *trustModeHandler;
@property (nonatomic, strong, readwrite) NSMutableDictionary *trustedCertificatesHandler;

#pragma mark OAuthClient to AccountType Relation
- (OLOAuth2Client *)pendingOAuthClientForAccountType:(NSString *)accountType;
- (NSString *)accountTypeOfPendingOAuthClient:(OLOAuth2Client *)oauthClient;


#pragma mark Notification Handler
- (void)accountDidChangeUserData:(NSNotification *)aNotification;
- (void)accountDidChangeAccessToken:(NSNotification *)aNotification;
- (void)accountDidLoseAccessToken:(NSNotification *)aNotification;


#pragma mark Keychain Support

+ (NSString *)keychainServiceName;
+ (NSDictionary *)accountsFromDefaultKeychain;
+ (void)storeAccountsInDefaultKeychain:(NSDictionary *)accounts;
+ (void)removeFromDefaultKeychain;

@end


@implementation OLOAuth2AccountStore

#pragma mark Lifecycle

+ (id)sharedStore;
{
    static OLOAuth2AccountStore *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [OLOAuth2AccountStore new];
    });
    return shared;
}

- (id)init;
{
    self = [super init];
    if (self) {
        self.pendingOAuthClients = [NSMutableDictionary dictionary];
        self.accountsDict = [NSMutableDictionary dictionaryWithDictionary:[OLOAuth2AccountStore accountsFromDefaultKeychain]];
        self.configurations = [NSMutableDictionary dictionary];
        self.trustModeHandler = [NSMutableDictionary dictionary];
        self.trustedCertificatesHandler = [NSMutableDictionary dictionary];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountDidChangeUserData:)
                                                     name:OLOAuth2AccountDidChangeUserDataNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountDidChangeAccessToken:)
                                                     name:OLOAuth2AccountDidChangeAccessTokenNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountDidLoseAccessToken:)
                                                     name:OLOAuth2AccountDidLoseAccessTokenNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark Accessors

@synthesize pendingOAuthClients;
@synthesize accountsDict;

@synthesize configurations;
@synthesize trustModeHandler;
@synthesize trustedCertificatesHandler;

- (NSArray *)accounts;
{
    NSArray *result = nil;
    @synchronized (self.accountsDict) {
        result = [self.accountsDict allValues];
    }
    return result;
}

- (NSArray *)accountsWithAccountType:(NSString *)accountType;
{
    NSMutableArray *result = [NSMutableArray array];
    for (OLOAuth2Account *account in self.accounts) {
        if ([account.accountType isEqualToString:accountType]) {
            [result addObject:account];
        }
    }
    return result;
}

- (OLOAuth2Account *)accountWithIdentifier:(NSString *)identifier;
{
    OLOAuth2Account *result = nil;
    @synchronized (self.accountsDict) {
        result = [self.accountsDict objectForKey:identifier];
    }
    return result;
}


#pragma mark Manage Accounts

- (void)requestAccessToAccountWithType:(NSString *)accountType;
{
    OLOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];
    [client requestAccess];
}

- (void)requestAccessToAccountWithType:(NSString *)accountType
   withPreparedAuthorizationURLHandler:(OLOAuth2PreparedAuthorizationURLHandler)aPreparedAuthorizationURLHandler;
{
    NSAssert(aPreparedAuthorizationURLHandler, @"Prepared Authorization Handler must not be nil.");

    OLOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];

    NSDictionary *configuration;
    @synchronized (self.configurations) {
        configuration = [self.configurations objectForKey:accountType];
    }

    NSURL *redirectURL = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationRedirectURL];
    NSURL *preparedURL = [client authorizationURLWithRedirectURL:redirectURL];

    aPreparedAuthorizationURLHandler(preparedURL);
}

- (void)requestAccessToAccountWithType:(NSString *)accountType username:(NSString *)username password:(NSString *)password;
{
    OLOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];
    [client authenticateWithUsername:username password:password];
}

- (void)requestAccessToAccountWithType:(NSString *)accountType assertionType:(NSURL *)assertionType assertion:(NSString *)assertion;
{
    OLOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];
    [client authenticateWithAssertionType:assertionType assertion:assertion];
}

- (void)requestClientCredentialsAccessWithType:(NSString *)accountType;
{
    OLOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];
    [client authenticateWithClientCredentials];
}

- (void)removeAccount:(OLOAuth2Account *)account;
{
    if (account) {
        @synchronized (self.accountsDict) {
            [self.accountsDict removeObjectForKey:account.identifier];
            [OLOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:OLOAuth2AccountStoreAccountsDidChangeNotification object:self];
    }
}

#pragma mark Configuration

- (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
   authorizationURL:(NSURL *)anAuthorizationURL
           tokenURL:(NSURL *)aTokenURL
        redirectURL:(NSURL *)aRedirectURL
     forAccountType:(NSString *)anAccountType;
{
    [self setConfiguration:[NSDictionary dictionaryWithObjectsAndKeys:
                            aClientID, kOLOAuth2AccountStoreConfigurationClientID,
                            aSecret, kOLOAuth2AccountStoreConfigurationSecret,
                            anAuthorizationURL, kOLOAuth2AccountStoreConfigurationAuthorizeURL,
                            aTokenURL, kOLOAuth2AccountStoreConfigurationTokenURL,
                            aRedirectURL, kOLOAuth2AccountStoreConfigurationRedirectURL, nil]
            forAccountType:anAccountType];
}

- (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
              scope:(NSSet *)theScope
   authorizationURL:(NSURL *)anAuthorizationURL
           tokenURL:(NSURL *)aTokenURL
        redirectURL:(NSURL *)aRedirectURL
      keyChainGroup:(NSString *)aKeyChainGroup
     forAccountType:(NSString *)anAccountType;
{
    [self setConfiguration:[NSDictionary dictionaryWithObjectsAndKeys:
                            aClientID, kOLOAuth2AccountStoreConfigurationClientID,
                            aSecret, kOLOAuth2AccountStoreConfigurationSecret,
                            theScope, kOLOAuth2AccountStoreConfigurationScope,
                            anAuthorizationURL, kOLOAuth2AccountStoreConfigurationAuthorizeURL,
                            aTokenURL, kOLOAuth2AccountStoreConfigurationTokenURL,
                            aKeyChainGroup, kOLOAuth2AccountStoreConfigurationKeyChainGroup,
                            aRedirectURL, kOLOAuth2AccountStoreConfigurationRedirectURL, nil]
            forAccountType:anAccountType];
}

- (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
              scope:(NSSet *)theScope
   authorizationURL:(NSURL *)anAuthorizationURL
           tokenURL:(NSURL *)aTokenURL
        redirectURL:(NSURL *)aRedirectURL
      keyChainGroup:(NSString *)aKeyChainGroup
          tokenType:(NSString *)aTokenType
     forAccountType:(NSString *)anAccountType;
{
    [self setConfiguration:[NSDictionary dictionaryWithObjectsAndKeys:
                            aClientID, kOLOAuth2AccountStoreConfigurationClientID,
                            aSecret, kOLOAuth2AccountStoreConfigurationSecret,
                            theScope, kOLOAuth2AccountStoreConfigurationScope,
                            anAuthorizationURL, kOLOAuth2AccountStoreConfigurationAuthorizeURL,
                            aTokenURL, kOLOAuth2AccountStoreConfigurationTokenURL,
                            aTokenType, kOLOAuth2AccountStoreConfigurationTokenType,
                            aKeyChainGroup, kOLOAuth2AccountStoreConfigurationKeyChainGroup,
                            aRedirectURL, kOLOAuth2AccountStoreConfigurationRedirectURL, nil]
            forAccountType:anAccountType];
}

- (void)setConfiguration:(NSDictionary *)configuration
          forAccountType:(NSString *)accountType;
{
    NSAssert1([configuration objectForKey:kOLOAuth2AccountStoreConfigurationClientID], @"Missing OAuth2 client ID for account type '%@'.", accountType);
    NSAssert1([configuration objectForKey:kOLOAuth2AccountStoreConfigurationSecret], @"Missing OAuth2 client secret for account type '%@'.", accountType);
    NSAssert1([configuration objectForKey:kOLOAuth2AccountStoreConfigurationAuthorizeURL], @"Missing OAuth2 authorize URL for account type '%@'.", accountType);
    NSAssert1([configuration objectForKey:kOLOAuth2AccountStoreConfigurationTokenURL], @"Missing OAuth2 token URL for account type '%@'.", accountType);

    @synchronized (self.configurations) {
        [self.configurations setObject:configuration forKey:accountType];
    }
}

- (NSDictionary *)configurationForAccountType:(NSString *)accountType;
{
    NSDictionary *result = nil;
    @synchronized (self.configurations) {
        result = [self.configurations objectForKey:accountType];
    }
    return result;
}


#pragma mark Trust Mode Handler

- (void)setTrustModeHandlerForAccountType:(NSString *)accountType
                                    block:(OLOAuth2TrustModeHandler)handler;
{
    @synchronized (self.trustModeHandler) {
        [self.trustModeHandler setObject:[handler copy] forKey:accountType];
    }
}

- (void)setTrustedCertificatesHandlerForAccountType:(NSString *)accountType
                                              block:(OLOAuth2TrustedCertificatesHandler)handler;
{
    @synchronized (self.trustedCertificatesHandler) {
        [self.trustedCertificatesHandler setObject:[handler copy] forKey:accountType];
    }
}

- (OLOAuth2TrustModeHandler)trustModeHandlerForAccountType:(NSString *)accountType;
{
    return [self.trustModeHandler objectForKey:accountType];
}

- (OLOAuth2TrustedCertificatesHandler)trustedCertificatesHandlerForAccountType:(NSString *)accountType;
{
    OLOAuth2TrustedCertificatesHandler handler = [self.trustedCertificatesHandler objectForKey:accountType];
    NSAssert(handler, @"You need to provied a OLOAuth2TrustedCertificatesHandler for account type '%@' because you are using 'OLOAuth2TrustModeSpecificCertificate' as trust mode for that account type.", accountType);
    return handler;
}


#pragma mark Handle OAuth Redirects

- (BOOL)handleRedirectURL:(NSURL *)aURL;
{
    __block NSURL *fixedRedirectURL = nil;
    NSSet *accountTypes;

    @synchronized (self.configurations) {
        accountTypes = [self.configurations keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop) {
            NSDictionary *configuration = obj;
            NSURL *redirectURL = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationRedirectURL];
            if ( [[[aURL absoluteString] lowercaseString] hasPrefix:[[redirectURL absoluteString] lowercaseString]]) {

                // WORKAROUND: The URL which is passed to this method may be lower case also the scheme is registered in camel case. Therefor replace the prefix with the stored redirectURL.
                if (fixedRedirectURL == nil) {
                    if ([aURL.scheme isEqualToString:redirectURL.scheme]) {
                        fixedRedirectURL = aURL;
                    } else {
                        NSRange prefixRange;
                        prefixRange.location = 0;
                        prefixRange.length = [redirectURL.absoluteString length];
                        fixedRedirectURL = [NSURL URLWithString:[aURL.absoluteString stringByReplacingCharactersInRange:prefixRange
                                                                                                             withString:redirectURL.absoluteString]];
                    }
                }

                return YES;
            } else {
                return NO;
            }
        }];
    }

    for (NSString *accountType in accountTypes) {
        OLOAuth2Client *client = [self pendingOAuthClientForAccountType:accountType];
        if ([client openRedirectURL:fixedRedirectURL]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark OAuthClient to AccountType Relation

- (OLOAuth2Client *)pendingOAuthClientForAccountType:(NSString *)accountType;
{
    OLOAuth2Client *client = nil;
    @synchronized (self.pendingOAuthClients) {
        client = [self.pendingOAuthClients objectForKey:accountType];

        if (!client) {
            NSDictionary *configuration;
            @synchronized (self.configurations) {
                configuration = [self.configurations objectForKey:accountType];
            }

            NSString *clientID = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationClientID];
            NSString *clientSecret = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationSecret];
            NSSet *scope = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationScope];
            NSURL *authorizeURL = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationAuthorizeURL];
            NSURL *tokenURL = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationTokenURL];
            NSString *tokenType = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationTokenType];
            NSString *tokenRequestHTTPMethod = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationTokenRequestHTTPMethod];
            NSString *keychainGroup = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationKeyChainGroup];
            NSDictionary *additionalAuthenticationParameters = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters];
            NSDictionary *customHeaderFields = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationCustomHeaderFields];

            client = [[OLOAuth2Client alloc] initWithClientID:clientID
                                                 clientSecret:clientSecret
                                                 authorizeURL:authorizeURL
                                                     tokenURL:tokenURL
                                                  accessToken:nil
                                                    tokenType:tokenType
                                                keyChainGroup:keychainGroup
                                                   persistent:YES
                                                     delegate:self];

            client.persistent = NO;

            if (tokenRequestHTTPMethod != nil) {
                client.tokenRequestHTTPMethod = tokenRequestHTTPMethod;
            }
            if (additionalAuthenticationParameters != nil) {
                NSAssert([additionalAuthenticationParameters isKindOfClass:[NSDictionary class]], @"additionalAuthenticationParameters have to be a NSDictionary");
                client.additionalAuthenticationParameters = additionalAuthenticationParameters;
            }
            if (customHeaderFields) {
                client.customHeaderFields = customHeaderFields;
            }

            if (scope != nil) {
                client.desiredScope = scope;
            }

            [self.pendingOAuthClients setObject:client forKey:accountType];
        }
    }
    return client;
}

- (NSString *)accountTypeOfPendingOAuthClient:(OLOAuth2Client *)oauthClient;
{
    NSString *result = nil;
    @synchronized (self.pendingOAuthClients) {
        NSSet *accountTypes = [self.pendingOAuthClients keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop){
            if ([obj isEqual:oauthClient]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        result = [accountTypes anyObject];
    }
    return result;
}


#pragma mark OLOAuth2ClientDelegate

- (void)oauthClientNeedsAuthentication:(OLOAuth2Client *)client;
{
    NSString *accountType = [self accountTypeOfPendingOAuthClient:client];

    NSDictionary *configuration;
    @synchronized (self.configurations) {
        configuration = [self.configurations objectForKey:accountType];
    }

    NSURL *redirectURL = [configuration objectForKey:kOLOAuth2AccountStoreConfigurationRedirectURL];
    NSURL *preparedURL = [client authorizationURLWithRedirectURL:redirectURL];

#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] openURL:preparedURL];
#else
        [[NSWorkspace sharedWorkspace] openURL:preparedURL];
#endif
}

- (void)oauthClientDidGetAccessToken:(OLOAuth2Client *)client;
{
    NSString *accountType;
    @synchronized (self.pendingOAuthClients) {
        accountType = [self accountTypeOfPendingOAuthClient:client];
        [self.pendingOAuthClients removeObjectForKey:accountType];
    }

    OLOAuth2Account *account = [[OLOAuth2Account alloc] initAccountWithOAuthClient:client accountType:accountType];

    [self addAccount:account];
}

- (void)addAccount:(OLOAuth2Account *)account;
{
    @synchronized (self.accountsDict) {
        [self.accountsDict setValue:account forKey:account.identifier];
        [OLOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
    }

    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:account
                                                         forKey:OLOAuth2AccountStoreNewAccountUserInfoKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:OLOAuth2AccountStoreAccountsDidChangeNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)oauthClientDidLoseAccessToken:(OLOAuth2Client *)client;
{
    // This delegate method should never be called because the account store
    // does not act as an delegate for established connections.

    // If there is one case that was overlooked, we will remove the oauth
    // client from the list of pending oauth clients as a precaution.
    NSString *accountType;
    @synchronized (self.pendingOAuthClients) {
        accountType = [self accountTypeOfPendingOAuthClient:client];
        if (accountType) {
            [self.pendingOAuthClients removeObjectForKey:accountType];
        }
    }
}

- (void)oauthClient:(OLOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;
{
    NSString *accountType;
    @synchronized (self.pendingOAuthClients) {
        accountType = [self accountTypeOfPendingOAuthClient:client];
        [self.pendingOAuthClients removeObjectForKey:accountType];
    }

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              accountType, kOLOAuth2AccountStoreAccountType,
                              error, OLOAuth2AccountStoreErrorKey, nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:OLOAuth2AccountStoreDidFailToRequestAccessNotification
                                                        object:self
                                                      userInfo:userInfo];
}


#pragma mark OLOAuth2TrustDelegate

-(OLOAuth2TrustMode)connection:(OLOAuth2Connection *)connection trustModeForHostname:(NSString *)hostname;
{
    NSString *accountType = [self accountTypeOfPendingOAuthClient:connection.client];
    OLOAuth2TrustModeHandler handler = [self trustModeHandlerForAccountType:accountType];
    if (handler) {
        return handler(connection, hostname);
    } else {
        return OLOAuth2TrustModeSystem;
    }
}

-(NSArray *)connection:(OLOAuth2Connection *)connection trustedCertificatesForHostname:(NSString *)hostname;
{
    NSString *accountType = [self accountTypeOfPendingOAuthClient:connection.client];
    OLOAuth2TrustedCertificatesHandler handler = [self trustedCertificatesHandlerForAccountType:accountType];
    return handler(hostname);
}

#pragma mark Notification Handler

- (void)accountDidChangeUserData:(NSNotification *)aNotification;
{
    @synchronized (self.accountsDict) {
        // The user data of an account has been changed.
        // Save all accounts in the default keychain.
        [OLOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
    }
}

- (void)accountDidChangeAccessToken:(NSNotification *)aNotification;
{
    @synchronized (self.accountsDict) {
        // An access token of an account has been changed.
        // Save all accounts in the default keychain.
        [OLOAuth2AccountStore storeAccountsInDefaultKeychain:self.accountsDict];
    }
}

- (void)accountDidLoseAccessToken:(NSNotification *)aNotification;
{
    NSLog(@"Removing account with id '%@' from account store because it lost its access token.", [aNotification.object identifier]);
    [self removeAccount:aNotification.object];
}

#pragma mark Keychain Support

+ (NSString *)keychainServiceName;
{
    NSString *appName = [[NSBundle mainBundle] bundleIdentifier];
    return [NSString stringWithFormat:@"%@::OLOAuth2AccountStore", appName];
}

#if TARGET_OS_IPHONE

+ (NSDictionary *)accountsFromDefaultKeychain;
{
    NSString *serviceName = [self keychainServiceName];

    NSDictionary *result = nil;
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, kSecClass,
                           serviceName, kSecAttrService,
                           kCFBooleanTrue, kSecReturnAttributes,
                           nil];
    CFTypeRef cfResult = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &cfResult);
    result = (__bridge_transfer NSDictionary *)cfResult;

    if (status != noErr) {
        NSAssert1(status == errSecItemNotFound, @"Unexpected error while fetching accounts from keychain: %zd", status);
        return nil;
    }

    return [NSKeyedUnarchiver unarchiveObjectWithData:[result objectForKey:(__bridge NSString *)kSecAttrGeneric]];
}

+ (void)storeAccountsInDefaultKeychain:(NSDictionary *)accounts;
{
    [self removeFromDefaultKeychain];

    NSString *serviceName = [self keychainServiceName];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:accounts];
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, kSecClass,
                           serviceName, kSecAttrService,
                           @"OAuth 2 Account Store", kSecAttrLabel,
                           data, kSecAttrGeneric,
                           nil];
    OSStatus __attribute__((unused)) err = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    NSAssert1(err == noErr, @"Error while adding token to keychain: %zd", err);
}

+ (void)removeFromDefaultKeychain;
{
    NSString *serviceName = [self keychainServiceName];
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, kSecClass,
                           serviceName, kSecAttrService,
                           nil];
    OSStatus __attribute__((unused)) err = SecItemDelete((__bridge CFDictionaryRef)query);
    NSAssert1((err == noErr || err == errSecItemNotFound), @"Error while deleting token from keychain: %zd", err);

}

#else

+ (NSDictionary *)accountsFromDefaultKeychain;
{
    NSString *serviceName = [self keychainServiceName];

    SecKeychainItemRef item = nil;
    OSStatus err = SecKeychainFindGenericPassword(NULL,
                                                  strlen([serviceName UTF8String]),
                                                  [serviceName UTF8String],
                                                  0,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  &item);
    if (err != noErr) {
        NSAssert1(err == errSecItemNotFound, @"Unexpected error while fetching accounts from keychain: %d", err);
        return nil;
    }

    // from Advanced Mac OS X Programming, ch. 16
    UInt32 length;
    char *password;
    NSData *result = nil;
    SecKeychainAttribute attributes[8];
    SecKeychainAttributeList list;

    attributes[0].tag = kSecAccountItemAttr;
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[2].tag = kSecLabelItemAttr;
    attributes[3].tag = kSecModDateItemAttr;

    list.count = 4;
    list.attr = attributes;

    err = SecKeychainItemCopyContent(item, NULL, &list, &length, (void **)&password);
    if (err == noErr) {
        if (password != NULL) {
            result = [NSData dataWithBytes:password length:length];
        }
        SecKeychainItemFreeContent(&list, password);
    } else {
        // TODO find out why this always works in i386 and always fails on ppc
        NSLog(@"Error from SecKeychainItemCopyContent: %d", err);
        return nil;
    }
    CFRelease(item);
    return [NSKeyedUnarchiver unarchiveObjectWithData:result];
}

+ (void)storeAccountsInDefaultKeychain:(NSDictionary *)accounts;
{
    [self removeFromDefaultKeychain];

    NSString *serviceName = [self keychainServiceName];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:accounts];

    OSStatus __attribute__((unused))err = SecKeychainAddGenericPassword(NULL,
                                                                        strlen([serviceName UTF8String]),
                                                                        [serviceName UTF8String],
                                                                        0,
                                                                        NULL,
                                                                        [data length],
                                                                        [data bytes],
                                                                        NULL);

    NSAssert1(err == noErr, @"Error while storing accounts in keychain: %d", err);
}

+ (void)removeFromDefaultKeychain;
{
    NSString *serviceName = [self keychainServiceName];

    SecKeychainItemRef item = nil;
    OSStatus err = SecKeychainFindGenericPassword(NULL,
                                                  strlen([serviceName UTF8String]),
                                                  [serviceName UTF8String],
                                                  0,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  &item);
    NSAssert1((err == noErr || err == errSecItemNotFound), @"Error while deleting accounts from keychain: %d", err);
    if (err == noErr) {
        err = SecKeychainItemDelete(item);
    }
    if (item) {
        CFRelease(item);
    }
    NSAssert1((err == noErr || err == errSecItemNotFound), @"Error while deleting accounts from keychain: %d", err);
}

#endif

@end

