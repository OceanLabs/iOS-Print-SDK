//
//  NXOAuth2TrustDelegate.h
//  OAuth2Client
//
//  Created by Thomas Kollbach on 24.05.11.
//
//  Copyright 2011 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>
#import "OLOAuth2Constants.h"

@class OLOAuth2Connection;

/*!
 * The delegate of the OLOAuth2Connection or the OLOAuth2Client can both
 * optionally implement this protocol to ensure specific trust modes.
 *
 * If a OLOAuth2Connection is created with a OLOAuth2Client set and both
 * delegates conform to the OLOAuth2TrustDelegate protocol, the OLOAuth2Client's
 * delegate is used.
 */

@protocol OLOAuth2TrustDelegate <NSObject>

@optional

/*!
 * Specifies Trust mode for the specific hostname. See OLOAuth2Constants.h for constants
 */
-(OLOAuth2TrustMode)connection:(OLOAuth2Connection *)connection trustModeForHostname:(NSString *)hostname;

/*!
 * Array of NSData objects that contains the trusted certificates for the hostname.
 */
-(NSArray *)connection:(OLOAuth2Connection *)connection trustedCertificatesForHostname:(NSString *)hostname;

@end
