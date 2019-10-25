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
#import "OLAsset+Private.h"
#import "OLKiteABTesting.h"
#import "OLImagePickerProvider.h"
#import "OLKiteViewController.h"
#import "OLCustomViewControllerPhotoProvider.h"
#import "OLKiteViewController+Private.h"
#include <sys/sysctl.h>
#import "OLKitePrintSDK.h"
#import "OLImagePickerViewController.h"
#import "OLNavigationController.h"
#import "OLImagePickerNavigationControllerViewController.h"
#import "NSObject+Utils.h"

@import Photobook;

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

-(NSMutableArray *) userSelectedAssets{
    if (!_userSelectedAssets){
        _userSelectedAssets = [[NSMutableArray alloc] init];
    }
    return _userSelectedAssets;
}

-(NSMutableArray *) recentPhotos{
    if (!_recentPhotos){
        _recentPhotos = [[NSMutableArray alloc] init];
    }
    return _recentPhotos;
}

- (void)resetUserSelectedPhotos{
    [self clearUserSelectedPhotos];
    [self.userSelectedAssets addObjectsFromArray:[[NSArray alloc] initWithArray:self.appAssets copyItems:YES]];
}

- (void)clearUserSelectedPhotos{
    for (OLAsset *asset in self.userSelectedAssets){
        [asset unloadImage];
    }
    
    [self.userSelectedAssets removeAllObjects];
    
    for (OLAsset *asset in self.recentPhotos){
        [asset unloadImage];
    }
    [self.recentPhotos removeAllObjects];
    
    for (OLImagePickerProvider *provider in self.kiteVc.customImageProviders){
        if ([provider isKindOfClass:[OLCustomViewControllerPhotoProvider class]]){
            for (OLImagePickerProviderCollection *collection in provider.collections){
                [collection.array removeAllObjects];
            }
        }
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
        
        if ([OLKitePrintSDK isKiosk]){
            NSArray * urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
            NSString *documentDirPath = [[(NSURL *)[urls objectAtIndex:0] path] stringByAppendingPathComponent:@"kite-kiosk-photos"];
            [[NSFileManager defaultManager] removeItemAtPath:documentDirPath error:NULL];
        }
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionBasket) == OLUserSessionCleanupOptionBasket){
        [[PhotobookSDK shared] clearBasketOrder];
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionPayment) == OLUserSessionCleanupOptionPayment){
        
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionSocial) == OLUserSessionCleanupOptionSocial){
        [self logoutOfInstagram];
        [self logoutOfFacebook];
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionPersonal) == OLUserSessionCleanupOptionPersonal){
        
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
        
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionAll) == OLUserSessionCleanupOptionAll){
        [self cleanupUserSession:OLUserSessionCleanupOptionPhotos | OLUserSessionCleanupOptionBasket | OLUserSessionCleanupOptionSocial | OLUserSessionCleanupOptionPersonal];
    }
    
}

- (void)calcScreenScaleForTraitCollection:(UITraitCollection *)traitCollection{
    //Should be [UIScreen mainScreen].scale but the 6 Plus with its 1GB RAM chokes on 3x images.
    if ([[self getSysInfoByName:"hw.model"] isEqualToString:@"iPhone7,1"]){
        self.screenScale = 2.0;
    }
    else{
        self.screenScale = [UIScreen mainScreen].scale;
    }
}

- (BOOL)shouldLoadTemplatesProgressively{
    return NO;
}


// From: https://github.com/erica/uidevice-extension/blob/master/UIDevice-Hardware.m
- (NSString *) getSysInfoByName:(char *)typeSpecifier
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    
    free(answer);
    return results;
}

- (id<PhotobookAssetPicker>) assetPickerViewController {
    OLImagePickerViewController *vc = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
    vc.selectedAssets = [[NSMutableArray alloc] init];
    vc.maximumPhotos = 1;
    
    return [[OLImagePickerNavigationControllerViewController alloc] initWithRootViewController:vc];
}

@end
