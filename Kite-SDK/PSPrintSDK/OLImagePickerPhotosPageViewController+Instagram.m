//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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
#import <NXOAuth2Client/NXOAuth2AccountStore.h>
#import "OLInstagramImage.h"
#import "OLImagePickerProviderCollection.h"

@interface OLImagePickerProviderCollection ()
@property (strong, nonatomic) NSMutableArray<OLAsset *> *array;
@end

@implementation OLImagePickerPhotosPageViewController (Instagram)

- (void)startImageLoading {
    self.loadingIndicator.hidden = NO;
    self.media = [[NSMutableArray alloc] init];
    self.nextMediaRequest = [[OLInstagramMediaRequest alloc] init];
    self.overflowMedia = @[];
    [self.collectionView reloadData];
    [self.provider.collections addObject:[[OLImagePickerProviderCollection alloc] initWithArray:@[] name:NSLocalizedString(@"All Photos", @"")]];
    [self loadNextInstagramPage];
}

- (void)loadNextInstagramPage {
    self.inProgressMediaRequest = self.nextMediaRequest;
    self.nextMediaRequest = nil;
    [self.inProgressMediaRequest fetchMediaWithCompletionHandler:^(NSError *error, NSArray *media, OLInstagramMediaRequest *nextRequest) {
        self.inProgressMediaRequest = nil;
        self.nextMediaRequest = nextRequest;
        self.loadingIndicator.hidden = YES;
        
        if (error) {
            // clear all accounts and redo login...
            if (error.domain == kOLInstagramImagePickerErrorDomain && error.code == kOLInstagramImagePickerErrorCodeOAuthTokenInvalid) {
                // need to renew auth token, start by clearing any accounts. A new one will be created as part of the login process.
                NSArray *instagramAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"instagram"];
                for (NXOAuth2Account *account in instagramAccounts) {
                    [[NXOAuth2AccountStore sharedStore] removeAccount:account];
                }
                
                [self.imagePicker reloadPageController];
            } else {
                //TODO handle error
            }
            
            return;
        }
        
        NSUInteger mediaStartCount = self.media.count;
        [self.media addObjectsFromArray:self.overflowMedia];
        for (OLInstagramImage *image in self.overflowMedia){
            [self.provider.collections.firstObject.array addObject:[OLAsset assetWithURL:image.fullURL]];
        }
        if (nextRequest != nil) {
            // only insert multiple of [self numberOfCellsPerRow] images so we fill complete rows
            NSInteger overflowCount = (self.media.count + media.count) % [self numberOfCellsPerRow];
            [self.media addObjectsFromArray:[media subarrayWithRange:NSMakeRange(0, media.count - overflowCount)]];
            for (OLInstagramImage *image in [media subarrayWithRange:NSMakeRange(0, media.count - overflowCount)]){
                [self.provider.collections.firstObject.array addObject:[OLAsset assetWithURL:image.fullURL]];
            }
            self.overflowMedia = [media subarrayWithRange:NSMakeRange(media.count - overflowCount, overflowCount)];
        } else {
            // we've exhausted all the users images so show the remainder
            [self.media addObjectsFromArray:media];
            for (OLInstagramImage *image in media){
                [self.provider.collections.firstObject.array addObject:[OLAsset assetWithURL:image.fullURL]];
            }
            self.overflowMedia = @[];
        }
        
        // Insert new items
        NSMutableArray *addedItemPaths = [[NSMutableArray alloc] init];
        for (NSUInteger itemIndex = mediaStartCount; itemIndex < self.media.count; ++itemIndex) {
            [addedItemPaths addObject:[NSIndexPath indexPathForItem:itemIndex inSection:0]];
        }
        
        [self.collectionView insertItemsAtIndexPaths:addedItemPaths];
        ((UICollectionViewFlowLayout *) self.collectionView.collectionViewLayout).footerReferenceSize = CGSizeMake(0, nextRequest == nil ? 0 : 44);        
    }];
}

@end
