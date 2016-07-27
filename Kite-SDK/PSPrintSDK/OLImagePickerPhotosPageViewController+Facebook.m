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

#import "OLImagePickerPhotosPageViewController+Facebook.h"

@interface OLImagePickerProviderCollection ()
@property (strong, nonatomic) NSMutableArray<OLAsset *> *array;
@end

@implementation OLImagePickerPhotosPageViewController (Facebook)

- (void)loadFacebookAlbums{
    self.albums = [[NSMutableArray alloc] init];
    self.albumRequestForNextPage = [[OLFacebookAlbumRequest alloc] init];
    [self loadNextAlbumPage];
    
    UIView *loadingFooter = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.frame = CGRectMake((320 - activityIndicator.frame.size.width) / 2, (44 - activityIndicator.frame.size.height) / 2, activityIndicator.frame.size.width, activityIndicator.frame.size.height);
    [activityIndicator startAnimating];
    [loadingFooter addSubview:activityIndicator];
    self.loadingFooter = loadingFooter;
}

- (void)loadNextAlbumPage {
    self.inProgressRequest = self.albumRequestForNextPage;
    self.albumRequestForNextPage = nil;
    [self.inProgressRequest getAlbums:^(NSArray<OLFacebookAlbum *> *albums, NSError *error, OLFacebookAlbumRequest *nextPageRequest) {
        self.inProgressRequest = nil;
        self.loadingIndicator.hidden = YES;
        self.albumRequestForNextPage = nextPageRequest;
        
        if (error) {
            if (self.parentViewController.isBeingPresented) {
                self.loadingIndicator.hidden = NO;
                self.getAlbumError = error; // delay notification so that delegate can dismiss view controller safely if desired.
            } else {
                //TODO error
            }
            return;
        }
        
        NSMutableArray *paths = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < albums.count; ++i) {
            [paths addObject:[NSIndexPath indexPathForRow:self.albums.count + i inSection:0]];
        }
        
        [self.albums addObjectsFromArray:albums];
//        if (self.albums.count == albums.count) {
//            // first insert request
//            [self.collectionView reloadData];
//        } else {
//            [self.collectionView insertItemsAtIndexPaths:paths];
//        }
        
        if (nextPageRequest) {
            //            self.tableView.tableFooterView = self.loadingFooter;
        } else {
            [self.provider.collections addObject:[[OLImagePickerProviderCollection alloc] initWithArray:[[NSMutableArray alloc] init] name:[self.albums.firstObject name]]];
            
            self.photos = [[NSMutableArray alloc] init];
            self.albumLabel.text = self.albums.firstObject.name;
            self.nextPageRequest = [[OLFacebookPhotosForAlbumRequest alloc] initWithAlbum:self.albums.firstObject];
            [self loadNextPage];
            //            self.tableView.tableFooterView = nil;
        }
        
    }];
}

- (void)loadNextPage {
    self.inProgressPhotosRequest = self.nextPageRequest;
    self.nextPageRequest = nil;
    [self.inProgressPhotosRequest getPhotos:^(NSArray *photos, NSError *error, OLFacebookPhotosForAlbumRequest *nextPageRequest) {
        self.inProgressRequest = nil;
        self.nextPageRequest = nextPageRequest;
        self.loadingIndicator.hidden = YES;
        
        if (error) {
            //TODO error
            return;
        }
        
        NSUInteger photosStartCount = self.photos.count;
        for (OLFacebookImage *image in self.overflowPhotos){
            [self.provider.collections.firstObject.array addObject:[OLAsset assetWithURL:image.fullURL]];
        }
        [self.photos addObjectsFromArray:self.overflowPhotos];
        if (nextPageRequest != nil) {
            // only insert multiple of numberOfCellsPerRow images so we fill complete rows
            NSInteger overflowCount = (self.photos.count + photos.count) % [self numberOfCellsPerRow];
            for (OLFacebookImage *image in [photos subarrayWithRange:NSMakeRange(0, photos.count - overflowCount)]){
                [self.provider.collections.firstObject.array addObject:[OLAsset assetWithURL:image.fullURL]];
            }
            [self.photos addObjectsFromArray:[photos subarrayWithRange:NSMakeRange(0, photos.count - overflowCount)]];
            self.overflowPhotos = [photos subarrayWithRange:NSMakeRange(photos.count - overflowCount, overflowCount)];
        } else {
            // we've exhausted all the users images so show the remainder
            for (OLFacebookImage *image in photos){
                [self.provider.collections.firstObject.array addObject:[OLAsset assetWithURL:image.fullURL]];
            }
            [self.photos addObjectsFromArray:photos];
            self.overflowPhotos = @[];
        }
        
        // Insert new items
        NSMutableArray *addedItemPaths = [[NSMutableArray alloc] init];
        for (NSUInteger itemIndex = photosStartCount; itemIndex < self.photos.count; ++itemIndex) {
            [addedItemPaths addObject:[NSIndexPath indexPathForItem:itemIndex inSection:0]];
        }
        
        [self.collectionView insertItemsAtIndexPaths:addedItemPaths];
        ((UICollectionViewFlowLayout *) self.collectionView.collectionViewLayout).footerReferenceSize = CGSizeMake(0, nextPageRequest == nil ? 0 : 44);
    }];
    
}

@end
