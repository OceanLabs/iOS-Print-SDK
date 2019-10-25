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


#import "OLImagePickerPhotosPageViewController.h"
#import "UIImageView+FadeIn.h"
#import "OLImageView.h"
#import "OLUserSession.h"
#import "UIView+RoundRect.h"
#import "OLAsset+Private.h"
#import "OLKiteUtils.h"
#import "OLKiteABTesting.h"
#import "OLImagePreviewViewController.h"

@interface OLImagePickerPhotosPageViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, UIViewControllerPreviewingDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *albumLabelChevron;
@property (assign, nonatomic) CGSize rotationSize;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;
@property (weak, nonatomic) IBOutlet UIView *albumsContainerView;
@property (weak, nonatomic) IBOutlet UIView *albumsCollectionViewContainerView;
@property (assign, nonatomic) BOOL reloadOnViewWillAppear;
@property (assign, nonatomic) NSUInteger numberOfCellsPerRow;

@end

CGFloat OLImagePickerMargin = 1.5;

@implementation OLImagePickerPhotosPageViewController

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [self closeAlbumsDrawer];
    
    self.reloadOnViewWillAppear = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [OLAsset cancelAllImageOperations];
    if (self.reloadOnViewWillAppear){
        [self.collectionView reloadData];
        self.reloadOnViewWillAppear = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self.albumsCollectionView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([OLUserSession currentSession].kiteVc.defaultPhotoAlbumName){
        for (OLImagePickerProviderCollection *collection in self.provider.collections){
            if ([collection.name isEqualToString:[OLUserSession currentSession].kiteVc.defaultPhotoAlbumName]){
                self.showingCollectionIndex = [self.provider.collections indexOfObjectIdenticalTo:collection];
                break;
            }
        }
    }
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.albumsCollectionView.dataSource = self;
    self.albumsCollectionView.delegate = self;
    
    self.albumsCollectionView.transform = CGAffineTransformMakeRotation(M_PI);
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    if (self.provider.collections.count > self.showingCollectionIndex){
        self.albumLabel.text = self.provider.collections[self.showingCollectionIndex].name;
    }
    else{
        self.albumLabel.text = @"";
    }
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        self.albumLabel.font = font;
    }
    
    
    self.albumLabelChevron.transform = CGAffineTransformMakeRotation(M_PI);
    
    self.ctaButton.backgroundColor = self.imagePicker.ctaButton.backgroundColor;
    self.ctaButton.titleLabel.font = self.imagePicker.ctaButton.titleLabel.font;
    [self.ctaButton setTitle:self.imagePicker.ctaButton.currentTitle forState:UIControlStateNormal];
    
    if ([OLUserSession currentSession].capitalizeCtaTitles){
        [self.ctaButton setTitle:[[self.ctaButton titleForState:UIControlStateNormal] uppercaseString] forState:UIControlStateNormal];
    }
    
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    
    self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    UIView *view = self.visualEffectView;
    [self.albumLabelContainer insertSubview:view belowSubview:self.albumLabel];
    
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    [self.view bringSubviewToFront:self.albumsContainerView];
        
    if (self.provider.providerType == OLImagePickerProviderTypeRecents || self.provider.providerType == OLImagePickerProviderTypeQRCode || self.provider.providerType == OLImagePickerProviderTypeViewController || (self.provider.providerType == OLImagePickerProviderTypeCustom && self.provider.collections.count <= 1)){
        [self.albumLabelContainer removeFromSuperview];
        self.albumLabelContainer = nil;
        [self.albumsContainerView removeFromSuperview];
    }
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    self.reloadOnViewWillAppear = YES;
    
    if ([self.imagePicker.traitCollection respondsToSelector:@selector(forceTouchCapability)] && self.imagePicker.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
        [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
    }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    if (self.collectionView.tag != 10){
        return nil;
    }
    
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
    UIImageView *imageView = [cell viewWithTag:10];
    
    [previewingContext setSourceRect:[cell convertRect:imageView.frame toView:self.collectionView]];
    
    id potentialAsset = [self assetForIndexPath:indexPath];
    OLAsset *asset;
    if ([potentialAsset isKindOfClass:[PHAsset class]]){
        asset = [OLAsset assetWithPHAsset:potentialAsset];
        
        //If it's already selected use the existing OLAsset instead of the newly created one
        if ([self.imagePicker.selectedAssets containsObject:asset]){
            asset = self.imagePicker.selectedAssets[[self.imagePicker.selectedAssets indexOfObject:asset]];
        }
    }
    else if ([potentialAsset isKindOfClass:[OLAsset class]]){
        asset = potentialAsset;
    }
    
    OLImagePreviewViewController *previewVc = [[OLImagePreviewViewController alloc] init];
    previewVc.asset = asset;
    previewVc.providesPresentationContextTransitionStyle = true;
    previewVc.definesPresentationContext = true;
    previewVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    previewVc.preferredContentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.width * (imageView.image.size.height / imageView.image.size.width));
    
    return previewVc;
}

- (void)previewingContext:(nonnull id<UIViewControllerPreviewing>)previewingContext commitViewController:(nonnull UIViewController *)viewControllerToCommit {
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.numberOfCellsPerRow = 0;
    self.rotationSize = size;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView reloadData];
        [self.collectionView.collectionViewLayout invalidateLayout];
        
        //Ignore warning about this collection view, works fine.
        [self.albumsCollectionView.collectionViewLayout invalidateLayout];
        
        self.albumsContainerView.transform = CGAffineTransformIdentity;
        
    }completion:^(id<UIViewControllerTransitionCoordinator> context){}];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    if (collectionView.tag == 10 && ![self.imagePicker isExclusiveCustomViewControllerProvider] && (self.provider.providerType == OLImagePickerProviderTypeQRCode || self.provider.providerType == OLImagePickerProviderTypeViewController)){
        return 2;
    }
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (section == 1){
        return 1;
    }
    
    if (collectionView.tag == 10){
        NSInteger numberOfItems = 0;
        if (self.provider.collections.count > self.showingCollectionIndex){
            NSInteger numberOfCellsToFillHeight = 0;
            
            numberOfItems = MAX(numberOfCellsToFillHeight * [self numberOfCellsPerRow], [self.provider.collections[self.showingCollectionIndex] count]);
        }
        return numberOfItems;
    }
    else{
        return [self.provider.collections count];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1){
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"addCell" forIndexPath:indexPath];
        if ([OLKiteABTesting sharedInstance].lightThemeColor1){
            [(UILabel *)[cell viewWithTag:10] setTextColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
        }
        return cell;
    }
    
    UICollectionViewCell *cell;
    if (collectionView.tag == 10){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photoCell" forIndexPath:indexPath];
        OLImageView *imageView = [cell viewWithTag:10];
        [self setAssetOfCollection:self.provider.collections[self.showingCollectionIndex] withIndex:indexPath.item toImageView:imageView forCollectionView:collectionView];
        
        UIView *checkmark = [cell viewWithTag:20];
        id potentialAsset = [self assetForIndexPath:indexPath];
        OLAsset *asset;
        if ([potentialAsset isKindOfClass:[PHAsset class]]){
            asset = [OLAsset assetWithPHAsset:potentialAsset];
            
            //If it's already selected use the existing OLAsset instead of the newly created one
            if ([[self.imagePicker.selectedAssets copy] containsObject:asset]){
                asset = self.imagePicker.selectedAssets[[[self.imagePicker.selectedAssets copy] indexOfObject:asset]];
            }
        }
        else if ([potentialAsset isKindOfClass:[OLAsset class]]){
            asset = potentialAsset;
        }
        
        if ([OLKiteABTesting sharedInstance].lightThemeColorPickerTick){
            [checkmark viewWithTag:1].tintColor = [OLKiteABTesting sharedInstance].lightThemeColorPickerTick;
        }
        else if ([OLKiteABTesting sharedInstance].lightThemeColor1){
            [checkmark viewWithTag:1].tintColor = [OLKiteABTesting sharedInstance].lightThemeColor1;
        } else {
            [checkmark viewWithTag:1].tintColor = [UIColor colorWithRed:0 green:0.48 blue:1 alpha:1];
        }
        
        if ([[self.imagePicker.selectedAssets copy] containsObject:asset]){
            checkmark.hidden = NO;
        }
        else{
            checkmark.hidden = YES;
        }
        
        UILabel *qtyLabel = [cell viewWithTag:11];
        if (!qtyLabel){
            qtyLabel = [[UILabel alloc] init];
            qtyLabel.tag = 11;
            
            qtyLabel.backgroundColor = self.ctaButton.backgroundColor;
            qtyLabel.textColor = [UIColor whiteColor];
            qtyLabel.font = [UIFont systemFontOfSize:13];
            qtyLabel.textAlignment = NSTextAlignmentCenter;
            
            [cell.contentView addSubview:qtyLabel];
            qtyLabel.translatesAutoresizingMaskIntoConstraints = NO;
            NSDictionary *views = NSDictionaryOfVariableBindings(qtyLabel);
            NSMutableArray *con = [[NSMutableArray alloc] init];
            
            NSArray *visuals = @[@"H:[qtyLabel(28)]-(6.5)-|",
                                 @"V:|-(6.5)-[qtyLabel(28)]"];
            
            
            for (NSString *visual in visuals) {
                [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
            }
            
            [qtyLabel.superview addConstraints:con];
            [qtyLabel makeRoundRectWithRadius:14];
        }
        
        if (asset.extraCopies > 0){
            qtyLabel.hidden = NO;
            qtyLabel.text = [NSString stringWithFormat:@"%d", (int)asset.extraCopies+1];
        }
        else{
            qtyLabel.hidden = YES;
        }
    }
    else{
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"albumCell" forIndexPath:indexPath];
        cell.contentView.transform = CGAffineTransformMakeRotation(M_PI);
        OLImageView *imageView = [cell viewWithTag:10];
        
        if (self.provider.collections[indexPath.item].coverAsset){
            __weak OLImageView *weakImageView = imageView;
            [imageView setAndFadeInImageWithOLAsset:self.provider.collections[indexPath.item].coverAsset size:imageView.frame.size applyEdits:NO placeholder:nil progress:^(float progress){
                [weakImageView setProgress:progress];
            } completionHandler:NULL];
        }
        else{
            [self setAssetOfCollection:self.provider.collections[indexPath.item] withIndex:0 toImageView:imageView forCollectionView:collectionView];
        }
        [imageView makeRoundRectWithRadius:4];
        imageView.clipsToBounds = YES;
        
        cell.clipsToBounds = NO;
        cell.layer.shadowColor = [[UIColor blackColor] CGColor];
        cell.layer.shadowOpacity = .4;
        cell.layer.shadowRadius = 5;
        
        UILabel *label = [[cell viewWithTag:20] viewWithTag:30];
        label.text = self.provider.collections[indexPath.item].name;
        if ([OLKiteABTesting sharedInstance].lightThemeColor2){
            label.superview.backgroundColor = [OLKiteABTesting sharedInstance].lightThemeColor2;
        }
        UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
        if (font){
            label.font = font;
        }
    }
    
    return cell;
}

- (void)setAssetOfCollection:(OLImagePickerProviderCollection *)collection withIndex:(NSInteger)index toImageView:(OLImageView *)imageView forCollectionView:(UICollectionView *)collectionView{
    id asset = [collection objectAtIndex:index];
    
    for (OLAsset *selectedAsset in [self.imagePicker.selectedAssets copy]){
        if ([asset isKindOfClass:[PHAsset class]]){
            if ([asset isEqual:[selectedAsset isKindOfClass:[OLAsset class]] ? selectedAsset.phAsset : selectedAsset]){
                asset = selectedAsset;
                break;
            }
        }
        else if ([asset isEqual:selectedAsset ignoreEdits:YES]){
            asset = selectedAsset;
            break;
        }
    }
    
    if ([asset isKindOfClass:[PHAsset class]]){
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = NO;
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        
        __weak OLImageView *weakImageView = imageView;
        
        CGSize cellSize = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [imageView setAndFadeInImageWithPHAsset:asset size:CGSizeMake(cellSize.width * [OLUserSession currentSession].screenScale, cellSize.height * [OLUserSession currentSession].screenScale) options:options placeholder:nil progress:^(float progress){
                [weakImageView setProgress:progress];
            }completionHandler:NULL];
        });
    }
    else if ([asset isKindOfClass:[OLAsset class]]){
        __weak OLImageView *weakImageView = imageView;
        [imageView setAndFadeInImageWithOLAsset:asset size:[self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathWithIndex:0]] applyEdits:NO placeholder:nil progress:^(float progress){
            [weakImageView setProgress:progress];
        } completionHandler:NULL];
    }
}

- (NSUInteger)numberOfCellsPerRow{
    if (_numberOfCellsPerRow == 0){
        CGSize size = self.rotationSize.width != 0 ? self.rotationSize : self.view.frame.size;
        if (self.quantityPerItem == 3){
            _numberOfCellsPerRow = 3;
        }
        
        if (self.imagePicker.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact){
            if (size.height > size.width){
                _numberOfCellsPerRow = [self findFactorOf:self.quantityPerItem maximum:6 minimum:6];
            }
            else{
                _numberOfCellsPerRow = [self findFactorOf:self.quantityPerItem maximum:6 minimum:6];
            }
        }
        else{
            if (size.height > size.width){
                _numberOfCellsPerRow = [self findFactorOf:self.quantityPerItem maximum:3 minimum:3];
            }
            else{
                _numberOfCellsPerRow = [self findFactorOf:self.quantityPerItem maximum:6 minimum:6];
            }
        }
    }
    
    return _numberOfCellsPerRow;
}

- (NSInteger) findFactorOf:(NSInteger)qty maximum:(NSInteger)max minimum:(NSInteger)min{
    if (qty == 1){
        return 3;
    }
    min = MAX(1, min);
    max = MAX(1, max);
    NSInteger factor = max;
    while (factor > min) {
        if (qty % factor == 0){
            return factor;
        }
        else{
            factor--;
        }
    }
    return min;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag == 10){
        return OLImagePickerMargin;
    }
    else{
        return 10;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag == 10){
        return OLImagePickerMargin;
    }
    else{
        return 10;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGSize size = self.view.bounds.size;
    
    if (self.rotationSize.width != 0){
        size = self.rotationSize;
    }
    
    if (collectionView.tag == 10){
        float numberOfCellsPerRow = [self numberOfCellsPerRow];
        CGFloat width = ((size.width - ((float)OLImagePickerMargin * (numberOfCellsPerRow-1.0)))/numberOfCellsPerRow);
        CGFloat height = width;
        
        return CGSizeMake(width, height);
    }
    else{
        return CGSizeMake(size.width - 16, 225);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag == 10){
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
    else{
        return UIEdgeInsetsMake(10, 0, self.albumLabelContainerTopCon.constant + 10, 0);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    if (collectionView != self.collectionView){
        return CGSizeZero;
    }
    
    CGSize size = self.view.bounds.size;
    
    if (self.rotationSize.width != 0){
        size = self.rotationSize;
    }
    
    return CGSizeZero;
}

- (OLAsset *)assetForIndexPath:(NSIndexPath *)indexPath{
    id potentialAsset = [self.provider.collections[self.showingCollectionIndex] objectAtIndex:indexPath.item];
    OLAsset *asset;
    if ([potentialAsset isKindOfClass:[PHAsset class]]){
        asset = [OLAsset assetWithPHAsset:potentialAsset];
        if ([[self.imagePicker.selectedAssets copy] containsObject:asset]){
            asset = self.imagePicker.selectedAssets[[[self.imagePicker.selectedAssets copy] indexOfObject:asset]];
        }
    }
    else if ([potentialAsset isKindOfClass:[OLAsset class]]){
        asset = potentialAsset;
    }
    
    for (OLAsset *potentialAsset in [self.imagePicker.selectedAssets copy]){
        if ([asset isEqual:potentialAsset ignoreEdits:YES]){
            asset = potentialAsset;
            break;
        }
    }
    
    return asset;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section > 0){ // + button for external vc
        [self.imagePicker presentExternalViewControllerForProvider:self.provider];
        return;
    }
    
    if (collectionView.tag == 10){ //Images collection view
        OLAsset *asset = [self assetForIndexPath:indexPath];
        
        if ([[self.imagePicker.selectedAssets copy] containsObject:asset]){ //Photo is selected
            if ([asset isEdited]){
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Are you sure?", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:NSLocalizedStringFromTableInBundle(@"This will discard your edits.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"The image edits, like crop, filters, etc") preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Yes", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleDestructive handler:^(id action){
                    [self.imagePicker.selectedAssets removeObject:asset];
                    asset.edits = nil;
                    asset.extraCopies = 0;
                    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }]];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"No", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleCancel handler:NULL]];
                [self presentViewController:ac animated:YES completion:NULL];
            }
            else{
                [self.imagePicker.selectedAssets removeObject:asset];
                asset.edits = nil;
                asset.extraCopies = 0;
                [[collectionView cellForItemAtIndexPath:indexPath] viewWithTag:20].hidden = YES;
            }
        }
        else if (self.imagePicker.maximumPhotos > 0 && self.imagePicker.assetCount >= self.imagePicker.maximumPhotos){ //Maximum reached
            NSString *message;
            if (self.imagePicker.maximumPhotos != self.imagePicker.minimumPhotos && self.imagePicker.maximumPhotos != 1){
                message = [NSString stringWithFormat:self.imagePicker.maximumPhotos == 1 ? NSLocalizedStringFromTableInBundle(@"Please select only %ld photo", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") : NSLocalizedStringFromTableInBundle(@"Please select up to %ld photos", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @""), (long)self.imagePicker.maximumPhotos];
            }
            else{
                message = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Please select %ld photos", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @""), (long)self.imagePicker.maximumPhotos];
            }
            UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Maximum Photos Reached", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")
                                                message:message
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action =
            [UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.")
                                     style:UIAlertActionStyleDefault
                                   handler:nil];
            
            [alert addAction:action];
            
            [self.imagePicker presentViewController:alert animated:YES completion:nil];
        }
        else if (asset){ //Add photo
            asset = [asset copy];
            asset.extraCopies = 0;
            asset.uuid = [[NSUUID UUID] UUIDString];
            NSUInteger index = [self.imagePicker.selectedAssets indexOfObject:[[OLPlaceholderAsset alloc] init]];
            if (index != NSNotFound){
                [self.imagePicker.selectedAssets replaceObjectAtIndex:index withObject:asset];
            }
            else{
                [self.imagePicker.selectedAssets addObject:asset];
            }
            asset.edits = nil;
            [asset unloadImage];
            [[collectionView cellForItemAtIndexPath:indexPath] viewWithTag:20].hidden = NO;
            
            if (self.imagePicker.maximumPhotos == 1){
                if (self.imagePicker.ctaButton){
                    [self.imagePicker.ctaButton sendActionsForControlEvents:UIControlEventTouchUpInside];
                }
                else{
                    [self.imagePicker onButtonDoneTapped:nil];
                }
            }
        }
        
        [self.imagePicker updateTitleBasedOnSelectedPhotoQuanitity];
    }
    else{ //Albums collection view
        self.showingCollectionIndex = indexPath.item;
        [self.collectionView reloadData];
        if ([self.collectionView numberOfItemsInSection:0] > 0){
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }
        [self userDidTapOnAlbumLabel:nil];
        self.albumLabel.text = self.provider.collections[self.showingCollectionIndex].name;
    }
}

- (void)closeAlbumsDrawer{
    if (!CGAffineTransformIsIdentity(self.albumsContainerView.transform)){
        [self userDidTapOnAlbumLabel:nil];
    }
}

- (IBAction)userDidTapOnAlbumLabel:(UITapGestureRecognizer *)sender {
    BOOL isOpening = CGAffineTransformIsIdentity(self.albumsContainerView.transform);
    
    if (isOpening){
        self.ctaButton.hidden = NO;
        self.imagePicker.ctaButton.hidden = YES;
    }
    else{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.imagePicker.ctaButton.hidden = NO;
            self.ctaButton.hidden = YES;
        });
    }
    
    if (isOpening){
        [UIView animateWithDuration:0.1 animations:^{
            self.albumsCollectionViewContainerView.alpha = 1;
        }];
    }
    else{
        [UIView animateWithDuration:0.1 delay:0.1 options:0 animations:^{
            self.albumsCollectionViewContainerView.alpha = 0;
        } completion:NULL];
    }
    
    [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:0 animations:^{
        self.albumsContainerView.transform = isOpening ? CGAffineTransformMakeTranslation(0, self.view.frame.size.height - (self.albumsContainerView.frame.origin.y + self.albumsContainerView.frame.size.height)) : CGAffineTransformIdentity;
        
        self.albumLabelChevron.transform = isOpening ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI);
    }completion:^(BOOL finished){}];
}

- (IBAction)userDidDragAlbumLabel:(UIPanGestureRecognizer *)sender {
    {
        static CGFloat originalY;
        
        if (sender.state == UIGestureRecognizerStateBegan){
            originalY = self.albumsContainerView.transform.ty;
        }
        else if (sender.state == UIGestureRecognizerStateChanged){
            CGFloat closedY = self.albumsContainerView.frame.origin.y - self.albumsContainerView.transform.ty;
            CGFloat openTY = (self.view.frame.size.height - (closedY + self.albumsContainerView.frame.size.height));
            CGPoint translate = [sender translationInView:sender.view.superview];
            self.albumsContainerView.transform = CGAffineTransformMakeTranslation(0, MAX(translate.y + originalY, 0));
            
            CGFloat percentComplete = MAX(self.albumsContainerView.transform.ty, 0) / (openTY);
            self.albumLabelChevron.transform = CGAffineTransformMakeRotation(M_PI * (1- MIN(percentComplete, 1)));
            
            self.ctaButton.hidden = percentComplete <= 0.5;
            self.imagePicker.ctaButton.hidden = percentComplete > 0.5;
            
            self.albumsCollectionViewContainerView.alpha = MIN(percentComplete * 15, 1);
            
        }
        else if (sender.state == UIGestureRecognizerStateEnded ||
                 sender.state == UIGestureRecognizerStateFailed ||
                 sender.state == UIGestureRecognizerStateCancelled){
            CGFloat closedY = self.albumsContainerView.frame.origin.y - self.albumsContainerView.transform.ty;
            CGFloat openTY = (self.view.frame.size.height - (closedY + self.albumsContainerView.frame.size.height));
            
            BOOL opening = [sender velocityInView:sender.view].y > 0;
            
            CGFloat start = self.albumsContainerView.transform.ty;
            CGFloat ty = opening ? openTY : 0;
            
            CGFloat distance = ABS(start - ty);
            CGFloat total = openTY;
            CGFloat percentComplete = 1 - distance / total;
            
            CGFloat damping = ABS(0.6 + (0.6 * percentComplete)*(0.6 * percentComplete));
            CGFloat time = ABS(0.8 - (0.8 * percentComplete));
            
            if (opening){
                self.ctaButton.hidden = NO;
                self.imagePicker.ctaButton.hidden = YES;
                
                [UIView animateWithDuration:0.1 animations:^{
                    self.albumsCollectionViewContainerView.alpha = 1;
                }];
            }
            else{
                [UIView animateWithDuration:time/8.0 delay:0.1 options:0 animations:^{
                    self.albumsCollectionViewContainerView.alpha = 0;
                } completion:NULL];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    self.ctaButton.hidden = YES;
                    self.imagePicker.ctaButton.hidden = NO;
                });
            }
            
            
            [UIView animateWithDuration:time delay:0 usingSpringWithDamping:damping initialSpringVelocity:0 options:0 animations:^{
                self.albumsContainerView.transform = CGAffineTransformMakeTranslation(0, ty);
                self.albumLabelChevron.transform = opening ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI);
            }completion:^(BOOL finished){}];
        }
    }
}

- (IBAction)onButtonLogoutTapped{}

@end
