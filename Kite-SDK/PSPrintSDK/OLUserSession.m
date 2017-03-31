//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "OLUserSession.h"
#import "OLKiteUtils.h"
#import "OLOAuth2AccountStore.h"
#import "OLAsset+Private.h"
#import "OLPayPalCard.h"
#import "OLStripeCard.h"
#import "OLKiteABTesting.h"
#import "OLAddress+AddressBook.h"
#import "OLFacebookSDKWrapper.h"
#import "OLImagePickerProvider.h"
#import "OLKiteViewController.h"
#import "OLCustomViewControllerPhotoProvider.h"
#import "OLKiteViewController+Private.h"

@interface OLPrintOrder (Private)
@property (weak, nonatomic) NSArray *userSelectedPhotos;
- (void)saveOrder;
+ (id)loadOrder;
@end

@interface OLImagePickerProviderCollection ()
@property (strong, nonatomic) NSMutableArray<OLAsset *> *array;
@end

@implementation OLUserSession

+ (instancetype)currentSession {
    static dispatch_once_t once;
    static OLUserSession * sharedInstance;
    dispatch_once(&once, ^ {
        sharedInstance = [[self alloc] init];
        sharedInstance.screenScale = 2.0;
    });
    return sharedInstance;
}

-(NSMutableArray *) userSelectedPhotos{
    if (!_userSelectedPhotos){
        _userSelectedPhotos = [[NSMutableArray alloc] init];
        
        if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
            [_userSelectedPhotos addObjectsFromArray:self.appAssets];
        }
    }
    return _userSelectedPhotos;
}

-(NSMutableArray *) recentPhotos{
    if (!_recentPhotos){
        _recentPhotos = [[NSMutableArray alloc] init];
    }
    return _recentPhotos;
}

-(OLPrintOrder *) printOrder{
    if (!_printOrder){
        _printOrder = [OLPrintOrder loadOrder];
    }
    if (!_printOrder){
        _printOrder = [[OLPrintOrder alloc] init];
    }
    _printOrder.userSelectedPhotos = self.userSelectedPhotos;
    return _printOrder;
}

- (void)resetUserSelectedPhotos{
    [self clearUserSelectedPhotos];
    [self.userSelectedPhotos addObjectsFromArray:self.appAssets];
}

- (void)clearUserSelectedPhotos{
    for (OLAsset *asset in self.userSelectedPhotos){
        asset.edits = nil;
        [asset unloadImage];
    }
    
    [self.userSelectedPhotos removeAllObjects];
    
    for (OLAsset *asset in self.recentPhotos){
        asset.edits = nil;
        [asset unloadImage];
    }
    [self.recentPhotos removeAllObjects];
    
    for (OLImagePickerProvider *provider in self.kiteVc.customImageProviders){
        for (OLImagePickerProviderCollection *collection in provider.collections){
            [collection.array removeAllObjects];
        }
    }
}

- (void)logoutOfFacebook{
    [OLFacebookSDKWrapper logout];
}

- (void)logoutOfInstagram{
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [NSArray arrayWithArray:[storage cookies]];
    for (cookie in cookies) {
        if ([cookie.domain containsString:@"instagram.com"]) {
            [storage deleteCookie:cookie];
        }
    }
    
    NSArray *instagramAccounts = [[OLOAuth2AccountStore sharedStore] accountsWithAccountType:@"instagram"];
    for (OLOAuth2Account *account in instagramAccounts) {
        [[OLOAuth2AccountStore sharedStore] removeAccount:account];
    }
}

- (void)cleanupUserSession:(OLUserSessionCleanupOption)cleanupOptions{
    if ((cleanupOptions & OLUserSessionCleanupOptionPhotos) == OLUserSessionCleanupOptionPhotos){
        [self clearUserSelectedPhotos];
        for (OLAsset *asset in self.appAssets){
            asset.edits = nil;
            [asset unloadImage];
        }
        
        self.appAssets = nil;
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionBasket) == OLUserSessionCleanupOptionBasket){
        self.printOrder = [[OLPrintOrder alloc] init];
        [self.printOrder saveOrder];
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionPayment) == OLUserSessionCleanupOptionPayment){
        [OLPayPalCard clearLastUsedCard];
        [OLStripeCard clearLastUsedCard];
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionSocial) == OLUserSessionCleanupOptionSocial){
        [self logoutOfInstagram];
        [self logoutOfFacebook];
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionPersonal) == OLUserSessionCleanupOptionPersonal){
        [OLKiteABTesting sharedInstance].theme.kioskShipToStoreAddress.recipientLastName = nil;
        [OLKiteABTesting sharedInstance].theme.kioskShipToStoreAddress.recipientFirstName = nil;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyEmailAddress"];
        [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyPhone"];
        [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyRecipientName"];
        [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyRecipientFirstName"];
        [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyLine1"];
        [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyLine2"];
        [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyCity"];
        [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyCounty"];
        [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyPostCode"];
        [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyCountry"];
        [defaults synchronize];
        
        [OLAddress clearAddressBook];
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionAll) == OLUserSessionCleanupOptionAll){
        [self cleanupUserSession:OLUserSessionCleanupOptionPhotos | OLUserSessionCleanupOptionBasket | OLUserSessionCleanupOptionSocial | OLUserSessionCleanupOptionPersonal];
    }
    
}

- (void)calcScreenScaleForTraitCollection:(UITraitCollection *)traitCollection{
    //TODO: Just check for the specific model and get rid of this image loading business
    
    //Should be [UIScreen mainScreen].scale but the 6 Plus with its 1GB RAM chokes on 3x images.
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale == 2.0 || scale == 1.0){
        self.screenScale = scale;
    }
    else{
        UIImage *ram1GbImage = [UIImage imageNamed:@"ram-1" inBundle:[OLKiteUtils kiteLocalizationBundle] compatibleWithTraitCollection:traitCollection];
        UIImage *ramThisDeviceImage = [UIImage imageNamed:@"ram" inBundle:[OLKiteUtils kiteLocalizationBundle] compatibleWithTraitCollection:traitCollection];
        NSData *ram1Gb = UIImagePNGRepresentation(ram1GbImage);
        NSData *ramThisDevice = UIImagePNGRepresentation(ramThisDeviceImage);
        if ([ram1Gb isEqualToData:ramThisDevice]){
            self.screenScale = 2.0;
        }
        else{
            self.screenScale = scale;
        }
    }
}

- (BOOL)shouldLoadTemplatesProgressively{
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        return NO;
    }
    if (self.kiteVc.filterProducts.count > 0){
        return NO;
    }
    
    return YES;
}

@end
