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


#import <UIKit/UIKit.h>
#import "OLImagePickerViewController.h"
#import "OLImagePickerPageViewController.h"

#import "OLFacebookAlbumRequest.h"
#import "OLFacebookAlbum.h"
#import "OLFacebookPhotosForAlbumRequest.h"
#import "OLFacebookImage.h"

#import "OLInstagramMediaRequest.h"

@interface OLImagePickerPhotosPageViewController : OLImagePickerPageViewController

@property (assign, nonatomic) NSInteger quantityPerItem;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *albumsCollectionView;
@property (weak, nonatomic) IBOutlet UIView *albumLabelContainer;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (assign, nonatomic) NSInteger showingCollectionIndex;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (NSUInteger)numberOfCellsPerRow;
- (void)closeAlbumsDrawer;


//Facebook
@property (nonatomic, strong) OLFacebookAlbumRequest *albumRequestForNextPage;
@property (nonatomic, strong) OLFacebookAlbumRequest *inProgressRequest;
@property (nonatomic, strong) OLFacebookPhotosForAlbumRequest *nextPageRequest;
@property (nonatomic, strong) OLFacebookPhotosForAlbumRequest *inProgressPhotosRequest;
@property (nonatomic, strong) UIView *loadingFooter;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) NSError *getAlbumError;
@property (nonatomic, strong) NSMutableArray<OLFacebookAlbum *> *albums;

@property (nonatomic, strong) NSMutableArray<OLFacebookImage *> *photos;
@property (nonatomic, strong) NSArray<OLFacebookImage *> *overflowPhotos;

//Instagram
@property (nonatomic, strong) NSMutableArray *media;
@property (nonatomic, strong) OLInstagramMediaRequest *inProgressMediaRequest;
@property (nonatomic, strong) OLInstagramMediaRequest *nextMediaRequest;
@property (nonatomic, strong) NSArray *overflowMedia;


@end