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

#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLAsset+Private.h"
#import "OLCircleMaskCollectionViewCell.h"
#import "OLConstants.h"
#import "OLImagePickerViewController.h"
#import "OLInfoBanner.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLPackProductViewController.h"
#import "OLProduct.h"
#import "OLProductPrintJob.h"
#import "OLProductTemplate.h"
#import "OLImageView.h"
#import "OLUserSession.h"
#import "UIImageView+FadeIn.h"
#import "UIViewController+OLMethods.h"
#import "OLKiteViewController+Private.h"
#import "UIView+RoundRect.h"

@import Photobook;

typedef NS_ENUM(NSUInteger, OLPackReviewStyle) {
    OLPackReviewStyleClassic,
    OLPackReviewStyleMini,
};

@interface OLPackProductViewController () <UICollectionViewDelegateFlowLayout, OLInfoBannerDelegate, OLArtboardDelegate>

@property (weak, nonatomic) OLAsset *editingAsset;
@property (strong, nonatomic) UIView *addMorePhotosView;
@property (strong, nonatomic) UIButton *addMorePhotosButton;
@property (strong, nonatomic) UIButton *ctaButton;
@property (strong, nonatomic) OLInfoBanner *infoBanner;

@end

@interface OLArtboardView ()
- (void)handleTapGesture:(UITapGestureRecognizer *)sender;
@end

@implementation OLPackProductViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    [self setupCtaButton];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top, self.collectionView.contentInset.left, self.ctaButton.frame.size.height + 30, self.collectionView.contentInset.right);
    [self addInfoBanner];
}

- (OLPackReviewStyle)reviewStyle{
    return [[OLKiteABTesting sharedInstance].packReviewStyle isEqualToString:@"Classic"] ? OLPackReviewStyleClassic : OLPackReviewStyleMini;
}

- (void)addInfoBanner{
    if ([OLUserSession currentSession].kiteVc.disableEditingTools && ![OLKiteUtils imageProvidersAvailable]){
        return;
    }
    if ([OLUserSession currentSession].kiteVc.disableEditingTools){
        self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap image to change", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    }
    else{
        self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap image to edit", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    }
    self.infoBanner.delegate = self;
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top + 50, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
}

- (void)infoBannerWillDismiss{
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top - self.infoBanner.frame.size.height, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
}

- (void)setupCtaButton{
    self.ctaButton = [[UIButton alloc] init];
    [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Add to Basket", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    [self.ctaButton addTarget:self action:@selector(onButtonNextClicked:) forControlEvents:UIControlEventTouchUpInside];
    if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        [self.ctaButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
    }
    else{
        [self.ctaButton setBackgroundColor:[UIColor colorWithRed:0 green:0.48 blue:1 alpha:1]];
    }
    [self.ctaButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    CGFloat y = self.view.frame.size.height - 55 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height);
    
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        y -= self.view.safeAreaInsets.bottom;
    }
#endif
    
    self.ctaButton.frame = CGRectMake(15, self.view.frame.size.height - 55 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height), self.view.frame.size.width-30, 50);
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:17];
    if (!font){
        font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    }
    if (font){
        [self.ctaButton.titleLabel setFont:font];
    }
    else{
        [self.ctaButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    }
    
    NSNumber *cornerRadius = [OLKiteABTesting sharedInstance].lightThemeButtonRoundCorners;
    if (cornerRadius){
        [self.ctaButton makeRoundRectWithRadius:[cornerRadius floatValue]];
    } else {
        [self.ctaButton makeRoundRectWithRadius:10];
    }
    
    [self.collectionView addSubview:self.ctaButton];
    
    if ([OLUserSession currentSession].capitalizeCtaTitles){
        [self.ctaButton setTitle:[[self.ctaButton titleForState:UIControlStateNormal] uppercaseString] forState:UIControlStateNormal];
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    CGFloat y = -self.ctaButton.frame.origin.x + self.view.frame.size.height - self.ctaButton.frame.size.height + self.collectionView.contentOffset.y;
    
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        y -= self.view.safeAreaInsets.bottom;
    }
#endif
    
    self.ctaButton.frame = CGRectMake(self.ctaButton.frame.origin.x, y, self.view.frame.size.width - 2 * self.ctaButton.frame.origin.x, self.ctaButton.frame.size.height);
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self addBasketIconToTopRight];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    NSArray *visibleCells = [self.collectionView indexPathsForVisibleItems];
    NSIndexPath *maxIndexPath = [visibleCells firstObject];
    for (NSIndexPath *indexPath in visibleCells){
        if (maxIndexPath.item < indexPath.item){
            maxIndexPath = indexPath;
        }
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView.collectionViewLayout invalidateLayout];
        for (NSIndexPath *indexPath in visibleCells){
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            [cell setNeedsDisplay];
        }
        
        CGFloat y = -self.ctaButton.frame.origin.x + self.view.frame.size.height - self.ctaButton.frame.size.height + self.collectionView.contentOffset.y;
        
#ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
            y -= self.view.safeAreaInsets.bottom;
        }
#endif
        
        self.ctaButton.frame = CGRectMake(self.ctaButton.frame.origin.x, y, self.view.frame.size.width - 2 * self.ctaButton.frame.origin.x, self.ctaButton.frame.size.height);
        [self addBasketIconToTopRight];
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGRect frame = self.ctaButton.frame;
    frame.origin.y = self.view.frame.size.height - self.ctaButton.frame.size.height + scrollView.contentOffset.y ;
    self.ctaButton.frame = frame;
}

-(NSUInteger) totalNumberOfExtras{
    NSUInteger res = 0;
    for (OLAsset *photo in [OLAsset userSelectedAssets]){
        res += photo.extraCopies;
    }
    return res;
}

- (void)updateTitleBasedOnSelectedPhotoQuanitity {
    if (self.product.quantityToFulfillOrder > 1){
        NSUInteger numOrders = 1 + (MAX(0, [OLAsset userSelectedAssets].nonPlaceholderAssets.count - 1 + [self totalNumberOfExtras]) / self.product.quantityToFulfillOrder);
        NSUInteger quanityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
        self.title = [NSString stringWithFormat:@"%lu / %lu", (unsigned long) ([OLAsset userSelectedAssets].nonPlaceholderAssets.count + [self totalNumberOfExtras]), (unsigned long)quanityToFulfilOrder];
    }
    else{
        self.title = NSLocalizedStringFromTableInBundle(@"Review", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Title of a screen where the user can review the product before ordering");
    }
}

-(BOOL) shouldGoToCheckout{
    NSUInteger selectedCount = [OLAsset userSelectedAssets].nonPlaceholderAssets.count + [self totalNumberOfExtras];
    NSUInteger numOrders = 1 + (MAX(0, selectedCount - 1) / self.product.quantityToFulfillOrder);
    NSUInteger quantityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
    if (selectedCount < quantityToFulfilOrder) {
        NSUInteger canSelectExtraCount = quantityToFulfilOrder - selectedCount;
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You've selected %d photos.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") ,selectedCount] message:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You can add %d more for the same price.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @""), canSelectExtraCount] preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Print these", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self doCheckout];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Add more", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Add more [photos]") style:UIAlertActionStyleCancel handler:NULL]];
        [self presentViewController:ac animated:YES completion:NULL];
        return NO;
    }
    return YES;
}

- (void)saveJobWithCompletionHandler:(void(^)(void))handler{
    [self preparePhotosForCheckout];
    NSArray<OLAsset *> *assets = [[OLAsset userSelectedAssets] nonPlaceholderAssets];
    
    id<Product> job;
    if (self.product.productTemplate.supportsTextOnBorder) { // NOTE: There should be a better way to identify polaroid products
        job = (id<Product>)[OLPrintJob polaroidWithTemplateId:self.product.templateId OLAssets:assets];
    } else if (self.product.productTemplate.templateUI == OLTemplateUIDoubleSided) {
        job = (id<Product>)[OLPrintJob postcardWithTemplateId:self.product.templateId frontImageOLAsset:assets.firstObject backImageOLAsset:assets.lastObject];
    } else if (self.product.productTemplate.templateUI == OLTemplateUICalendar) {
        job = (id<Product>)[OLPrintJob calendarWithTemplateId:self.product.productTemplate.identifier OLAssets:assets];
    } else{
        job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:assets];
    }
    [[PhotobookSDK shared] addProductToBasket:job];
    
    if (handler){
        handler();
    }
}

- (void)doCheckout {
    [self saveJobWithCompletionHandler:NULL];
    
    UIViewController *checkoutVc = [[PhotobookSDK shared] checkoutViewControllerWithEmbedInNavigation:NO dismissClosure:^(UIViewController *viewController, BOOL success){
        if (![OLUserSession currentSession].kiteVc){
            [viewController dismissViewControllerAnimated:YES completion:NULL];
        }
        else if ([viewController isKindOfClass:[NSClassFromString(@"Photobook.PhotobookViewController") class]]){
            [viewController.navigationController popViewControllerAnimated:YES];
        } else {
            [viewController.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
    UIViewController *firstController = self.navigationController.viewControllers.firstObject;
    [self.navigationController setViewControllers:@[firstController, checkoutVc] animated:YES];
    [[OLUserSession currentSession] resetUserSelectedPhotos];
}

- (void) deletePhotoAtIndex:(NSUInteger)index{
    [[OLAsset userSelectedAssets] removeObjectAtIndex:index];
    
    if ([OLAsset userSelectedAssets].nonPlaceholderAssets.count == 0){
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
}

- (CGFloat) productAspectRatio{
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    if (b.top < b.bottom){ //This is for polaroids, since we don't know its pixel dims
        return 1;
    }
    else if (CGSizeEqualToSize(self.product.productTemplate.sizeCm, CGSizeZero)){
        return 1;
    }
    else{
        return self.product.productTemplate.sizeCm.height / self.product.productTemplate.sizeCm.width;
    }
}

#pragma mark Button Actions

- (IBAction)onButtonUpArrowClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UICollectionViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)cell];
    
    NSInteger extraCopies = [[[OLAsset userSelectedAssets] objectAtIndex:indexPath.item] extraCopies] + 1;
    [[[OLAsset userSelectedAssets] objectAtIndex:indexPath.item] setExtraCopies:extraCopies];
    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)extraCopies + 1]];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (IBAction)onButtonDownArrowClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UICollectionViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)cell];
    
    NSInteger extraCopies = [[[OLAsset userSelectedAssets] objectAtIndex:indexPath.item] extraCopies];
    if (extraCopies == 0){
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Remove?", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Remove [photo]?") message:NSLocalizedStringFromTableInBundle(@"Do you want to remove this photo?", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Yes, remove it", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Yes, remove [the photo]") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
            [self deletePhotoAtIndex:indexPath.item];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"No, keep it", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"No, keep [the photo]") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    extraCopies--;
    
    [[[OLAsset userSelectedAssets] objectAtIndex:indexPath.item] setExtraCopies:extraCopies];
    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)extraCopies + 1]];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];    
}

- (void)editPhoto:(UIButton *)sender {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[sender.superview convertPoint:sender.frame.origin toView:self.collectionView]];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    OLArtboardView *artboard = [cell viewWithTag:10];
    for (UIGestureRecognizer *gesture in artboard.assetViews.firstObject.gestureRecognizers){
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]){
            [artboard handleTapGesture:(UITapGestureRecognizer *)gesture];
            return;
        }
    }
}

- (void)onButtonNextClicked:(UIBarButtonItem *)sender {
    if (![self shouldGoToCheckout]){
        return;
    }
    
    [self doCheckout];
}

- (void)preparePhotosForCheckout{
    NSArray<OLAsset *> *assets = [[OLAsset userSelectedAssets] nonPlaceholderAssets];
    
    NSInteger numOrders = 1 + (MAX(0, assets.count - 1 + [self totalNumberOfExtras]) / self.product.quantityToFulfillOrder);
    NSInteger quantityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
    NSInteger totalItems = assets.count + [self totalNumberOfExtras];
    
    NSInteger additionalCopies = quantityToFulfilOrder - totalItems;
    if (additionalCopies > 0) {
        NSInteger assetIndex = 0;
        for (NSInteger i = 0; i < additionalCopies; i++) {
            assets[assetIndex].extraCopies = assets[assetIndex].extraCopies + 1;
            ++assetIndex;
            if (assetIndex == assets.count) {
                assetIndex = 0;
            }
        }
    }    
}

#pragma mark UICollectionView data source and delegate methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [OLAsset userSelectedAssets].nonPlaceholderAssets.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    OLCircleMaskCollectionViewCell *cell;
    if (self.product.productTemplate.templateUI == OLTemplateUIDoubleSided){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"doubleSidedCell" forIndexPath:indexPath];
        UILabel *label = (UILabel *)[cell viewWithTag:10];
        label.text = indexPath.item == 0 ? NSLocalizedStringFromTableInBundle(@"FRONT", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Front of the photo") : NSLocalizedStringFromTableInBundle(@"BACK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Back of the photo");
        
    }
    else if ([self reviewStyle] == OLPackReviewStyleMini){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"miniPhotoCell" forIndexPath:indexPath];
    }
    else{
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"reviewPhotoCell" forIndexPath:indexPath];
    }
    UIView *view = cell.contentView;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    UIButton *editButton = (UIButton *)[cell.contentView viewWithTag:11];
    if ([OLUserSession currentSession].kiteVc.disableEditingTools){
        [editButton removeFromSuperview];
    }
    [editButton addTarget:self action:@selector(editPhoto:) forControlEvents:UIControlEventTouchUpInside];
    if ([OLKiteABTesting sharedInstance].lightThemeColor2){
        [editButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor2];
    }
    [editButton setTitle:NSLocalizedStringFromTableInBundle(@"Edit", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Edit image") forState:UIControlStateNormal];
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        [editButton.titleLabel setFont:font];
    }
    
    UIButton *upButton = (UIButton *)[cell.contentView viewWithTag:12];
    [upButton addTarget:self action:@selector(onButtonUpArrowClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *downButton = (UIButton *)[cell.contentView viewWithTag:13];
    [downButton addTarget:self action:@selector(onButtonDownArrowClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *countLabel = (UILabel *)[cell.contentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%ld", (long)[[[OLAsset userSelectedAssets] objectAtIndex:indexPath.item] extraCopies]+1]];
    if ([OLKiteABTesting sharedInstance].lightThemeColor3){
        if ([self reviewStyle] == OLPackReviewStyleMini){
            [[cell viewWithTag:100] setBackgroundColor:[[OLKiteABTesting sharedInstance].lightThemeColor3 colorWithAlphaComponent:0.9]];
            [upButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor3];
            [downButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor3];
        }
        else{
            [upButton setTintColor:[OLKiteABTesting sharedInstance].lightThemeColor3];
            [downButton setTintColor:[OLKiteABTesting sharedInstance].lightThemeColor3];
        }
    }
    
    if ([OLKiteABTesting sharedInstance].lightThemeColorReviewCounter){
        if ([self reviewStyle] == OLPackReviewStyleMini){
            [countLabel setTextColor:[OLKiteABTesting sharedInstance].lightThemeColorReviewCounter];
        }
        else{
            [countLabel setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColorReviewCounter];
        }
    }
    else if ([OLKiteABTesting sharedInstance].lightThemeColor3){
        if ([self reviewStyle] == OLPackReviewStyleMini){
            [countLabel setTextColor:[OLKiteABTesting sharedInstance].lightThemeColor3];
        }
        else{
            [countLabel setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor3];
        }
    }
    
    OLAsset *asset = [[OLAsset userSelectedAssets] objectAtIndex:indexPath.item];
    
    OLArtboardView *artboard = cell.imageView;
    artboard.delegate = self;
    CGSize imageSize = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
    [self configureAssetViewsForArtboard:artboard forSize:imageSize];
    
    artboard.assetViews.firstObject.index = indexPath.item;
    
    [artboard.assetViews.firstObject.imageView setAndFadeInImageWithOLAsset:asset size:imageSize applyEdits:YES placeholder:nil progress:^(float progress){
        [(OLImageView *)artboard.assetViews.firstObject.imageView setProgress:progress];
    }completionHandler:nil];
    
    if (self.product.productTemplate.templateUI == OLTemplateUICircle){
        cell.enableMask = YES;
        [cell setNeedsDisplay];
    }
    
    [[artboard viewWithTag:1556] removeFromSuperview];
    if (asset.edits.bottomBorderText.text){
        [artboard setupBottomBorderTextField];
        [(UITextView *)[artboard viewWithTag:1556] setText:asset.edits.bottomBorderText.text];
    }
    
    return cell;
}

- (void)configureAssetViewsForArtboard:(OLArtboardView *)artboard forSize:(CGSize)size{
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    
    artboard.assetViews.firstObject.relativeFrame = CGRectMake(b.right, b.top, 1 - b.right - b.left, 1 - b.top - b.bottom);
}

- (CGFloat)heightForButtons{
    if (self.product.productTemplate.templateUI == OLTemplateUIDoubleSided){
        return 30;
    }
    else if ([self reviewStyle] == OLPackReviewStyleMini){
        return 45;
    }
    return 51;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    
    CGFloat margin = [self collectionView:collectionView layout:collectionView.collectionViewLayout minimumInteritemSpacingForSectionAtIndex:indexPath.section];
    
    UIEdgeInsets sectionInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    CGFloat width = self.view.frame.size.width;
    width -= sectionInsets.left + sectionInsets.right;
    width = MIN(width / [self numberOfCellsPerRow], 320.0);
    width -= (NSInteger)((self.view.frame.size.width / width)-1) * margin;
    
    CGFloat height = (width * (1.0 - b.left - b.right)) * [self productAspectRatio];
    height = height / (1 - b.top - b.bottom);
    height += [self heightForButtons];
    
    return CGSizeMake(width, height);
}

- (NSUInteger)numberOfCellsPerRow{
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact && self.view.frame.size.height > self.view.frame.size.width && [self reviewStyle] == OLPackReviewStyleClassic){
        return 1;
    }
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact && self.view.frame.size.height > self.view.frame.size.width && [self reviewStyle] == OLPackReviewStyleMini){
        return 2;
    }
    
    UIEdgeInsets sectionInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    return (self.view.frame.size.width - sectionInsets.left - sectionInsets.right) / 320.0;
    
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    CGSize cellSize = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
    
    NSInteger numberOfCellsPerRow = collectionView.frame.size.width / cellSize.width;
    CGFloat margin = MAX((collectionView.frame.size.width - (cellSize.width * numberOfCellsPerRow))/(numberOfCellsPerRow+1), 5);
    
    return UIEdgeInsetsMake(10, margin, 10, margin);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 20;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 35;
}

- (UIView *)viewToAddDraggingAsset{
    return self.view;
}

- (UIScrollView *)scrollViewForVerticalScolling{
    return self.collectionView;
}

- (UIViewController *)viewControllerForPresenting{
    return self;
}

@end
