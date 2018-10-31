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

#import "OLImagePickerPhotosPageViewController+Facebook.h"
#import "OLKiteUtils.h"

@interface OLImagePickerProviderCollection ()
@property (strong, nonatomic) NSMutableArray<OLAsset *> *array;
@end

@interface OLImagePickerPhotosPageViewController () <UICollectionViewDataSource>

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
    if (self.inProgressRequest){
        [self.inProgressRequest cancel];
    }
    self.inProgressRequest = self.albumRequestForNextPage;
    self.albumRequestForNextPage = nil;
    __weak OLImagePickerPhotosPageViewController *welf = self;
    [self.inProgressRequest getAlbums:^(NSArray<OLFacebookAlbum *> *albums, NSError *error, OLFacebookAlbumRequest *nextPageRequest) {
        welf.inProgressRequest = nil;
        welf.loadingIndicator.hidden = YES;
        welf.albumRequestForNextPage = nextPageRequest;
        
        if (error) {
            if (welf.parentViewController.isBeingPresented) {
                welf.loadingIndicator.hidden = NO;
                welf.getAlbumError = error; // delay notification so that delegate can dismiss view controller safely if desired.
            } else {
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.")  style:UIAlertActionStyleDefault handler:NULL]];
                [self.imagePicker presentViewController:ac animated:YES completion:NULL];
            }
            return;
        }
        
        
        [welf.albums addObjectsFromArray:albums];
        
        if (nextPageRequest) {
            
        }
        else {
            welf.albumLabel.text = welf.albums.firstObject.name;
            for (OLFacebookAlbum *album in welf.albums){
                OLImagePickerProviderCollection *collection = [[OLImagePickerProviderCollection alloc] initWithArray:[[NSMutableArray alloc] init] name:album.name];
                collection.coverAsset = [OLAsset assetWithURL:album.coverPhotoURL size:CGSizeZero];
                collection.metaData = album;
                [welf.provider.collections addObject:collection];
            }
            [self.albumsCollectionView reloadData];
            
            welf.photos = [[NSMutableArray alloc] init];
            
            
            welf.nextPageRequest = [[OLFacebookPhotosForAlbumRequest alloc] initWithAlbum:welf.albums.firstObject];
            [welf loadNextFacebookPage];
        }
        
    }];
}

- (void)loadNextFacebookPage {
    if (self.inProgressPhotosRequest){
        [self.inProgressPhotosRequest cancel];
    }
    self.inProgressPhotosRequest = self.nextPageRequest;
    self.nextPageRequest = nil;
    __weak OLImagePickerPhotosPageViewController *welf = self;
    [self.inProgressPhotosRequest getPhotos:^(NSArray *photos, NSError *error, OLFacebookPhotosForAlbumRequest *nextPageRequest) {
        welf.inProgressRequest = nil;
        welf.nextPageRequest = nextPageRequest;
        welf.loadingIndicator.hidden = YES;
        
        if (error) {
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.")  style:UIAlertActionStyleDefault handler:NULL]];
            [self.imagePicker presentViewController:ac animated:YES completion:NULL];
            return;
        }
        
        for (OLFacebookImage *image in welf.overflowPhotos){
            [welf.provider.collections[self.showingCollectionIndex].array addObject:[OLAsset assetWithURL:image.fullURL size:image.bestSize]];
        }
        [welf.photos addObjectsFromArray:welf.overflowPhotos];
        if (nextPageRequest != nil) {
            // only insert multiple of numberOfCellsPerRow images so we fill complete rows
            NSInteger overflowCount = (welf.photos.count + photos.count) % [welf numberOfCellsPerRow];
            for (OLFacebookImage *image in [photos subarrayWithRange:NSMakeRange(0, photos.count - overflowCount)]){
                [welf.provider.collections[self.showingCollectionIndex].array addObject:[OLAsset assetWithURL:image.fullURL size:image.bestSize]];
            }
            [welf.photos addObjectsFromArray:[photos subarrayWithRange:NSMakeRange(0, photos.count - overflowCount)]];
            welf.overflowPhotos = [photos subarrayWithRange:NSMakeRange(photos.count - overflowCount, overflowCount)];
        } else {
            // we've exhausted all the users images so show the remainder
            for (OLFacebookImage *image in photos){
                [welf.provider.collections[self.showingCollectionIndex].array addObject:[OLAsset assetWithURL:image.fullURL size:image.bestSize]];
            }
            [welf.photos addObjectsFromArray:photos];
            welf.overflowPhotos = @[];
            [self.activityIndicator stopAnimating];
        }
        
        [welf.collectionView reloadData];
    }];
    
}

@end
