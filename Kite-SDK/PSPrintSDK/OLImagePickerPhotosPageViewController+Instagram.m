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

#import "OLImagePickerPhotosPageViewController+Instagram.h"
#import "OLInstagramImagePickerConstants.h"
#import "OLInstagramImage.h"
#import "OLImagePickerProviderCollection.h"
#import "OLKiteUtils.h"

@import NXOAuth2Client;

@interface OLImagePickerProviderCollection ()
@property (strong, nonatomic) NSMutableArray<OLAsset *> *array;
@end

@interface OLImagePickerPhotosPageViewController () <UICollectionViewDataSource>

@end

@implementation OLImagePickerPhotosPageViewController (Instagram)

- (void)startImageLoading {
    self.loadingIndicator.hidden = NO;
    self.media = [[NSMutableArray alloc] init];
    self.nextMediaRequest = [[OLInstagramMediaRequest alloc] init];
    self.overflowMedia = @[];
    [self.collectionView reloadData];
    [self.provider.collections addObject:[[OLImagePickerProviderCollection alloc] initWithArray:@[] name:NSLocalizedStringFromTableInBundle(@"All Photos", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")]];
    [self loadNextInstagramPage];
}

- (void)loadNextInstagramPage {
    if (self.inProgressRequest){
        [self.inProgressRequest cancel];
    }
    self.inProgressMediaRequest = self.nextMediaRequest;
    self.nextMediaRequest = nil;
    __weak OLImagePickerPhotosPageViewController *welf = self;
    [self.inProgressMediaRequest fetchMediaWithCompletionHandler:^(NSError *error, NSArray *media, OLInstagramMediaRequest *nextRequest) {
        welf.inProgressMediaRequest = nil;
        welf.nextMediaRequest = nextRequest;
        welf.loadingIndicator.hidden = YES;
        
        if (error) {
            // clear all accounts and redo login...
            if (error.domain == kOLInstagramImagePickerErrorDomain && error.code == kOLInstagramImagePickerErrorCodeOAuthTokenInvalid) {
                // need to renew auth token, start by clearing any accounts. A new one will be created as part of the login process.
                NSArray *instagramAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"instagram"];
                for (NXOAuth2Account *account in instagramAccounts) {
                    [[NXOAuth2AccountStore sharedStore] removeAccount:account];
                }
                
                [welf.imagePicker reloadPageController];
            } else {
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.")  style:UIAlertActionStyleDefault handler:NULL]];
                [self.imagePicker presentViewController:ac animated:YES completion:NULL];
            }
            
            return;
        }
        
        [welf.media addObjectsFromArray:welf.overflowMedia];
        for (OLInstagramImage *image in welf.overflowMedia){
            [welf.provider.collections.firstObject.array addObject:[OLAsset assetWithURL:image.fullURL size:image.size]];
        }
        if (nextRequest != nil) {
            // only insert multiple of [self numberOfCellsPerRow] images so we fill complete rows
            NSInteger overflowCount = (welf.media.count + media.count) % [welf numberOfCellsPerRow];
            [welf.media addObjectsFromArray:[media subarrayWithRange:NSMakeRange(0, media.count - overflowCount)]];
            for (OLInstagramImage *image in [media subarrayWithRange:NSMakeRange(0, media.count - overflowCount)]){
                [welf.provider.collections.firstObject.array addObject:[OLAsset assetWithURL:image.fullURL size:image.size]];
            }
            welf.overflowMedia = [media subarrayWithRange:NSMakeRange(media.count - overflowCount, overflowCount)];
        } else {
            // we've exhausted all the users images so show the remainder
            [welf.media addObjectsFromArray:media];
            for (OLInstagramImage *image in media){
                [welf.provider.collections.firstObject.array addObject:[OLAsset assetWithURL:image.fullURL size:image.size]];
            }
            welf.overflowMedia = @[];
            [self.activityIndicator stopAnimating];
        }
        
        [welf.collectionView reloadData];
    }];
}

@end
