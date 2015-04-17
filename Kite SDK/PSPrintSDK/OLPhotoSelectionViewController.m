//
//  PhotoSelectionViewController.m
//  Print Studio
//
//  Created by Elliott Minns on 12/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import "OLPhotoSelectionViewController.h"
#import "OLPhotoSelectionButton.h"
#import "OLPrintPhoto.h"
#import "OLOrderReviewViewController.h"

#import <CTAssetsPickerController.h>

#ifdef OL_KITE_OFFER_INSTAGRAM
#import <OLInstagramImagePickerController.h>
#import <OLInstagramImage.h>
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#import <OLFacebookImagePickerController.h>
#import <OLFacebookImage.h>
#endif

#import "OLPrintJob.h"
#import "OLAddress.h"
#import "OLAsset.h"
#import "OLProductPrintJob.h"
#import <UIColor+HexString.h>
#import "OLCheckoutViewController.h"
#import "OLConstants.h"
#import "LXReorderableCollectionViewFlowLayout.h"
#import "NSArray+QueryingExtras.h"
#import "OLKitePrintSDK.h"
#import "NSObject+Utils.h"

NSInteger OLPhotoSelectionMargin = 0;

static const NSUInteger kTagAlertViewSelectMorePhotos = 99;

@interface OLKitePrintSDK (Private)

+ (OLKiteViewController *)kiteViewControllerInNavStack:(NSArray *)viewControllers;
#ifdef OL_KITE_OFFER_INSTAGRAM
+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;
#endif

@end

@interface OLPhotoSelectionViewController () <UINavigationControllerDelegate,
                                            CTAssetsPickerControllerDelegate,
                                            UICollectionViewDataSource,
                                            UICollectionViewDelegate,
                                            UICollectionViewDelegateFlowLayout,
#ifdef OL_KITE_OFFER_INSTAGRAM
                                            OLInstagramImagePickerControllerDelegate,
#endif
#ifdef OL_KITE_OFFER_FACEBOOK
                                            OLFacebookImagePickerControllerDelegate,
#endif
                                            LXReorderableCollectionViewDataSource,
                                            UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet OLPhotoSelectionButton *galleryButton;
@property (nonatomic, weak) IBOutlet OLPhotoSelectionButton *instagramButton;
@property (nonatomic, weak) IBOutlet OLPhotoSelectionButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIView *cameraRollContainer;
@property (weak, nonatomic) IBOutlet UIView *instagramContainer;
@property (weak, nonatomic) IBOutlet UIView *facebookContainer;

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) CTAssetsPickerController *picker;
@property (strong, nonatomic) NSMutableArray *userDisabledPhotos;

@property (nonatomic, weak) IBOutlet UILabel *chooseImportSourceLabel;
@property (nonatomic, weak) IBOutlet UIButton *buttonGalleryImport, *buttonInstagramImport, *buttonFacebookImport;

@property (nonatomic, weak) IBOutlet UIButton *buttonNext;
@property (nonatomic, weak) IBOutlet UIView *noSelectedPhotosView;
@property (weak, nonatomic) IBOutlet UIView *clearButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;

@property (assign, nonatomic) CGSize rotationSize;

@property (strong, nonatomic) NSMutableDictionary *indexPathsToRemoveDict;
@end

@implementation OLPhotoSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userDisabledPhotos = [[NSMutableArray alloc] init];
    
    self.galleryButton.image = [UIImage imageNamed:@"import_gallery"];
    self.galleryButton.title = NSLocalizedString(@"Camera Roll", @"");
    self.galleryButton.mainColor = [UIColor colorWithHexString:@"#48cfad"];
    
    self.instagramButton.image = [UIImage imageNamed:@"import_instagram"];
    self.instagramButton.title = NSLocalizedString(@"Instagram", @"");
    self.instagramButton.mainColor = [UIColor colorWithHexString:@"#f6bb42"];
    
    self.facebookButton.image = [UIImage imageNamed:@"import_facebook"];
    self.facebookButton.title = NSLocalizedString(@"Facebook", @"");
    self.facebookButton.mainColor = [UIColor colorWithHexString:@"#5d9cec"];
    
    [self.buttonFacebookImport setBackgroundImage:[self imageWithColor:[UIColor colorWithHexString:@"#497aba"]] forState:UIControlStateHighlighted];
    [self.buttonGalleryImport setBackgroundImage:[self imageWithColor:[UIColor colorWithHexString:@"#369c82"]] forState:UIControlStateHighlighted];
    [self.buttonInstagramImport setBackgroundImage:[self imageWithColor:[UIColor colorWithHexString:@"#c29334"]] forState:UIControlStateHighlighted];
    
    self.rotationSize = CGSizeZero;
    
    if (![self instagramEnabled]){
        [self.instagramButton removeFromSuperview];
        [self.buttonInstagramImport removeFromSuperview];
        [self.instagramContainer removeFromSuperview];
    }
    
    if (![self facebookEnabled]){
        [self.facebookButton removeFromSuperview];
        [self.buttonFacebookImport removeFromSuperview];
        [self.facebookContainer removeFromSuperview];
    }
    
    LXReorderableCollectionViewFlowLayout *layout = (LXReorderableCollectionViewFlowLayout *)[self.collectionView collectionViewLayout];
    layout.headerReferenceSize = CGSizeMake(0, 50);
    
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerView"];
    
    if (self.userSelectedPhotos.count > 0) {
            self.noSelectedPhotosView.alpha = 0;
    }
    else if (self.userSelectedPhotos.count == 0) {
            self.noSelectedPhotosView.alpha = 1;
    }
    [self onUserSelectedPhotoCountChange];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        
        self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        UIView *view = self.visualEffectView;
        [self.clearButtonContainerView insertSubview:view belowSubview:self.clearButton];
        
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[view]-0-|",
                             @"V:|-0-[view]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
        
    }
    else{
        self.clearButtonContainerView.backgroundColor = [UIColor whiteColor];
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)instagramEnabled{
#ifdef OL_KITE_OFFER_INSTAGRAM
    return [OLKitePrintSDK instagramSecret] && ![[OLKitePrintSDK instagramSecret] isEqualToString:@""] && [OLKitePrintSDK instagramClientID] && ![[OLKitePrintSDK instagramClientID] isEqualToString:@""] && [OLKitePrintSDK instagramRedirectURI] && ![[OLKitePrintSDK instagramRedirectURI] isEqualToString:@""];
#else 
    return NO;
#endif
}

- (BOOL)facebookEnabled{
#ifdef OL_KITE_OFFER_FACEBOOK
    return YES;
#else
    return NO;
#endif
}

- (void)viewWillAppear:(BOOL)animated{
    if (self.userSelectedPhotos.count > 0){
        [self.collectionView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [self updateNoSelectedPhotosView];
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)onUserSelectedPhotoCountChange {
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];
    for (OLPrintPhoto *printPhoto in self.userDisabledPhotos){
        if (![self.userSelectedPhotos containsObjectIdenticalTo:printPhoto]){
            [toRemove addObject:printPhoto];
        }
    }
    [self.userDisabledPhotos removeObjectsInArray:toRemove];
    
    [self updateNoSelectedPhotosView];
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (void)updateNoSelectedPhotosView {
    NSTimeInterval delay = 0.35;
    NSTimeInterval duration = 0.3;
    self.collectionView.alpha = self.userSelectedPhotos.count == 0 ? 0 : 1;
    if (self.userSelectedPhotos.count > 0 && self.noSelectedPhotosView.alpha >= 0.9f) {
        self.noSelectedPhotosView.alpha = 1;
        [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.noSelectedPhotosView.alpha = 0;
        } completion:^(BOOL finished) {}];
    }
    else if (self.userSelectedPhotos.count == 0 && self.noSelectedPhotosView.alpha <= 0.1f) {
        self.noSelectedPhotosView.alpha = 0;
        [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.noSelectedPhotosView.alpha = 1;
        } completion:^(BOOL finished) {}];
    }
}

- (void)updateTitleBasedOnSelectedPhotoQuanitity {
    if (self.userSelectedPhotos.count == 0) {
        [self setTitle:NSLocalizedString(@"Choose Photos", @"")];
    } else {
        NSUInteger numOrders = 1 + (MAX(0, self.userSelectedPhotos.count - 1) / self.product.quantityToFulfillOrder);
        NSUInteger quanityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
        [self setTitle:[NSString stringWithFormat:@"%lu / %lu", (unsigned long)self.userSelectedPhotos.count - self.userDisabledPhotos.count, (unsigned long)quanityToFulfilOrder]];
    }
    
    if ([self.userDisabledPhotos count] > 0){
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Cancel", @"");
        
        if ([self.userDisabledPhotos count] == 1){
            [self.clearButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"Clear %lu Photo", @""), (unsigned long)[self.userDisabledPhotos count]] forState:UIControlStateNormal];
        }
        else{
            [self.clearButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"Clear %lu Photos", @""), (unsigned long)[self.userDisabledPhotos count]] forState:UIControlStateNormal];
        }
        [UIView animateKeyframesWithDuration:0.15 delay:0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear animations:^{
            self.clearButtonContainerView.transform = CGAffineTransformMakeTranslation(0, -40);
        }completion:NULL];
    }
    else{
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Next", @"");
        [UIView animateKeyframesWithDuration:0.15 delay:0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear animations:^{
            self.clearButtonContainerView.transform = CGAffineTransformIdentity;
        }completion:NULL];
    }
}

- (void)populateArrayWithNewArray:(NSArray *)array dataType:(Class)class {
    NSMutableArray *photoArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    NSMutableArray *assetArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    
    for (id object in array) {
        OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
        printPhoto.asset = object;
        [photoArray addObject:printPhoto];
        
        [assetArray addObject:[OLAsset assetWithPrintPhoto:printPhoto]];
    }
    
    // First remove any that are not returned.
    NSMutableArray *removeArray = [NSMutableArray arrayWithArray:self.userSelectedPhotos];
    NSMutableArray *removeAssetArray = [NSMutableArray arrayWithArray:self.assets];
    for (OLPrintPhoto *object in self.userSelectedPhotos) {
        if (![object.asset isKindOfClass:class] || [photoArray containsObjectIdenticalTo:object]) {
            [removeAssetArray removeObjectAtIndex:[removeArray indexOfObjectIdenticalTo:object]];
            [removeArray removeObjectIdenticalTo:object];
        }
    }
    
    [self.userSelectedPhotos removeObjectsInArray:removeArray];
    [self.assets removeObjectsInArray:removeAssetArray];
    
    // Second, add the remaining objects to the end of the array without replacing any.
    NSMutableArray *addArray = [NSMutableArray arrayWithArray:photoArray];
    NSMutableArray *addAssetArray = [NSMutableArray arrayWithArray:assetArray];
    for (id object in self.userSelectedPhotos) {
        OLAsset *asset = [OLAsset assetWithPrintPhoto:object];
        
        if ([addAssetArray containsObject:asset]){
            [addArray removeObjectAtIndex:[addAssetArray indexOfObject:asset]];
            [addAssetArray removeObject:asset];
        }
    }

    [self.userSelectedPhotos addObjectsFromArray:addArray];
    [self.assets addObjectsFromArray:addAssetArray];
    
    // Reload the collection view.
    [self.collectionView reloadData];
    
    [self onUserSelectedPhotoCountChange];
}

- (NSArray *)createAssetArray {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:self.userSelectedPhotos.count];
    for (OLPrintPhoto *object in self.userSelectedPhotos) {
        [array addObject:object.asset];
    }
    return array;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.rotationSize = size;
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    for (OLPrintPhoto *photo in self.userSelectedPhotos) {
        [photo unloadImage];
    }
}

#pragma mark - Actions

- (IBAction)cameraRollSelected:(id)sender {
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    picker.delegate = self;
    picker.assetsFilter = [ALAssetsFilter allPhotos];
    picker.modalPresentationStyle = UIModalPresentationPageSheet;
    NSArray *allAssets = [[self createAssetArray] mutableCopy];
    NSMutableArray *alAssets = [[NSMutableArray alloc] init];
    for (id asset in allAssets){
        if ([asset isKindOfClass:[ALAsset class]]){
            [alAssets addObject:asset];
        }
    }
    picker.selectedAssets = alAssets;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)instagramSelected:(id)sender {
#ifdef OL_KITE_OFFER_INSTAGRAM
    OLInstagramImagePickerController *picker = nil;
    picker = [[OLInstagramImagePickerController alloc] initWithClientId:[OLKitePrintSDK instagramClientID] secret:[OLKitePrintSDK instagramSecret] redirectURI:[OLKitePrintSDK instagramRedirectURI]];
    
    picker.delegate = self;
    picker.selected = [self createAssetArray];
    picker.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:picker animated:YES completion:nil];
#endif
}

- (IBAction)facebookSelected:(id)sender {
#ifdef OL_KITE_OFFER_FACEBOOK
    OLFacebookImagePickerController *picker = nil;
    picker = [[OLFacebookImagePickerController alloc] init];
    picker.delegate = self;
    picker.selected = [self createAssetArray];
    picker.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:picker animated:YES completion:nil];
#endif
}

- (IBAction)onButtonClearClicked:(UIButton *)sender {
    NSInteger initialSections = [self numberOfSectionsInCollectionView:self.collectionView];
    
    self.indexPathsToRemoveDict = [[NSMutableDictionary alloc] init];
    for (id photo in self.userDisabledPhotos){
        NSUInteger index = [self.userSelectedPhotos indexOfObjectIdenticalTo:photo];
        NSUInteger section = index / self.product.quantityToFulfillOrder;
        NSUInteger item = index % self.product.quantityToFulfillOrder;
        
        if (!self.indexPathsToRemoveDict[[NSNumber numberWithInteger:section]]){
            self.indexPathsToRemoveDict[[NSNumber numberWithInteger:section]] = [[NSMutableArray alloc] init];
        }
        [self.indexPathsToRemoveDict[[NSNumber numberWithInteger:section]] addObject:[NSIndexPath indexPathForItem:item inSection:section]];
    }
    for (id photo in self.userDisabledPhotos){
        [self.assets removeObjectAtIndex:[self.userSelectedPhotos indexOfObject:photo]];
        [self.userSelectedPhotos removeObjectIdenticalTo:photo];
    }
    
    [self.userDisabledPhotos removeAllObjects];
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    [self.collectionView performBatchUpdates:^{
        if ([self numberOfSectionsInCollectionView:self.collectionView] < initialSections){
            NSUInteger sectionsDeleted = initialSections - [self numberOfSectionsInCollectionView:self.collectionView];
            NSRange range = NSMakeRange(initialSections - sectionsDeleted, sectionsDeleted);
            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndexesInRange:range]];
        }
        for (NSNumber *sectionNumber in self.indexPathsToRemoveDict.allKeys){
            NSNumber *n = [NSNumber numberWithLong:[sectionNumber longValue]];
            [self.collectionView deleteItemsAtIndexPaths:self.indexPathsToRemoveDict[n]];
        }
    }completion:^(BOOL finished){
        [self.indexPathsToRemoveDict removeAllObjects];
        [self.collectionView performSelector:@selector(reloadData) withObject:0 afterDelay:0.05];
        [self updateNoSelectedPhotosView];
    }];
    
}

#pragma mark - CTAssetsPickerControllerDelegate Methods

- (OLKiteViewController *)kiteViewController {
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isMemberOfClass:[OLKiteViewController class]]) {
            return (OLKiteViewController *) vc;
        }
    }
    
    return nil;
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker isDefaultAssetsGroup:(ALAssetsGroup *)group {
    if ([self.delegate respondsToSelector:@selector(kiteController:isDefaultAssetsGroup:)]) {
        return [self.delegate kiteController:[self kiteViewController] isDefaultAssetsGroup:group];
    }
    
    return NO;
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    [self populateArrayWithNewArray:assets dataType:[ALAsset class]];
    [picker dismissViewControllerAnimated:YES completion:^(void){}];
    
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldShowAssetsGroup:(ALAssetsGroup *)group{
    if (group.numberOfAssets == 0){
        return NO;
    }
    return YES;
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldShowAsset:(ALAsset *)asset{
    NSString *fileName = [[[asset defaultRepresentation] filename] lowercaseString];
    if (!([fileName hasSuffix:@".jpg"] || [fileName hasSuffix:@".jpeg"] || [fileName hasSuffix:@"png"])) {
        return NO;
    }
    return YES;
}

#ifdef OL_KITE_OFFER_INSTAGRAM
#pragma mark - OLInstagramImagePickerControllerDelegate Methods

- (void)instagramImagePicker:(OLInstagramImagePickerController *)imagePicker didFailWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)instagramImagePicker:(OLInstagramImagePickerController *)imagePicker didFinishPickingImages:(NSArray *)images {
    [self populateArrayWithNewArray:images dataType:[OLInstagramImage class]];
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)instagramImagePickerDidCancelPickingImages:(OLInstagramImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#pragma mark - OLFacebookImagePickerControllerDelegate Methods

- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFailWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFinishPickingImages:(NSArray *)images {
    [self populateArrayWithNewArray:images dataType:[OLFacebookImage class]];
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)facebookImagePickerDidCancelPickingImages:(OLFacebookImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}
#endif

#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger number = self.product.quantityToFulfillOrder;//collectionView.frame.size.height / 105 ;
    NSInteger removedImagesInOtherSections = 0;
    for (NSNumber *sectionNumber in self.indexPathsToRemoveDict.allKeys){
        NSNumber *n = [NSNumber numberWithLong:[sectionNumber longValue]];
        if ([n integerValue] != section){
            removedImagesInOtherSections += [self.indexPathsToRemoveDict[n] count];
        }
    }
    NSInteger removedImagesInThisSection = [self.indexPathsToRemoveDict[[NSNumber numberWithInteger:section]] count];
    NSInteger finalNumberOfPhotosRemoved = removedImagesInThisSection + removedImagesInOtherSections;

    return MIN(MAX(self.userSelectedPhotos.count + finalNumberOfPhotosRemoved, number * 3), self.product.quantityToFulfillOrder) - removedImagesInThisSection;
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    NSInteger removedImagesCount = 0;
    for (NSNumber *section in self.indexPathsToRemoveDict.allKeys){
        NSNumber *n = [NSNumber numberWithLong:[section longValue]];
        removedImagesCount += [self.indexPathsToRemoveDict[n] count];
    }
    NSInteger finalNumberOfPhotos = self.userSelectedPhotos.count;
    return ceil(finalNumberOfPhotos / (double)self.product.quantityToFulfillOrder);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerView" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithHexString:@"#ECEFF2"];
    
    
    UILabel *label = (UILabel *)[cell viewWithTag:77];
    if (!label){
        label = [[UILabel alloc] init];
        label.tag = 77;
        [cell addSubview:label];
        
        label.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(label);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-20-[label]-0-|",
                             @"V:|-0-[label]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [label.superview addConstraints:con];
    }
    
    NSString *title;
    OLTemplateUI templateUI = [OLProductTemplate templateWithId:self.product.templateId].templateUI;
    if (templateUI == kOLTemplateUIFrame){
        title = [[NSString alloc]initWithFormat:@"#%ld Frame", indexPath.section + 1];
    }
    else{
        title = [[NSString alloc]initWithFormat:@"#%ld Pack of %lu %@", indexPath.section + 1, (unsigned long)self.product.quantityToFulfillOrder, self.product.productTemplate.name];
    }
    label.text = title;
    
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"PhotoCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *imageView = (UIImageView *) [cell.contentView viewWithTag:40];
    if (imageView == nil) {
        cell.contentView.backgroundColor = [UIColor whiteColor];
        imageView = [[UIImageView alloc] init];
        imageView.tag = 40;
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [cell.contentView addSubview:imageView];
        
        // Auto autolayout constraints to the cell.
        NSDictionary *views = NSDictionaryOfVariableBindings(imageView);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[imageView]-0-|",
                             @"V:|-0-[imageView]-0-|"];
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [cell.contentView addConstraints:con];
    }
    imageView.image = nil;
    
    UIImageView *checkmark = (UIImageView *) [cell.contentView viewWithTag:41];
    if (!checkmark){
        checkmark = [[UIImageView alloc] initWithFrame:CGRectMake(cell.frame.size.width - 31, 0, 31, 31)];
        checkmark.tag = 41;
        checkmark.clipsToBounds = YES;
        checkmark.contentMode = UIViewContentModeScaleAspectFill;
        checkmark.translatesAutoresizingMaskIntoConstraints = NO;
        
        [cell.contentView addSubview:checkmark];
        
        // Auto autolayout constraints to the cell.
        NSDictionary *views = NSDictionaryOfVariableBindings(checkmark);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:[checkmark(==31)]",
                             @"V:[checkmark(==31)]",
                             @"H:[checkmark]-0-|"];
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [cell.contentView addConstraints:con];
        
        checkmark.image = [UIImage imageNamed:@"checkmark"];
        checkmark.hidden = YES;
    }
    
    UIView *disabled = [cell.contentView viewWithTag:42];
    if (!disabled){
        disabled = [[UIView alloc] init];
        disabled.tag = 42;
        disabled.translatesAutoresizingMaskIntoConstraints = NO;
        
        [cell.contentView addSubview:disabled];
        
        // Auto autolayout constraints to the cell.
        NSDictionary *views = NSDictionaryOfVariableBindings(disabled);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[disabled]-0-|",
                             @"V:|-0-[disabled]-0-|"];

        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [cell.contentView addConstraints:con];
        
        disabled.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    }
    
    imageView.backgroundColor = indexPath.item % 2 == 0 ? [UIColor colorWithHexString:@"#e6e9ed"] : [UIColor colorWithHexString:@"#dce0e5"];
    
    NSUInteger imageIndex = indexPath.row + indexPath.section * self.product.quantityToFulfillOrder;
    if (imageIndex < self.userSelectedPhotos.count) {
        OLPrintPhoto *photo = self.userSelectedPhotos[indexPath.row + indexPath.section * self.product.quantityToFulfillOrder];
        [photo setImageIdealSizeForImageView:imageView highQuality:NO];
        checkmark.hidden = [self.userDisabledPhotos containsObjectIdenticalTo:photo];
        disabled.hidden = !checkmark.hidden;
    } else {
        [imageView setImage:nil];
        checkmark.hidden = YES;
        disabled.hidden = YES;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id photo;
    NSInteger photoIndex = indexPath.row + indexPath.section * self.product.quantityToFulfillOrder;
    if (photoIndex < [self.userSelectedPhotos count]){
        photo = self.userSelectedPhotos[photoIndex];
        if ([self.userDisabledPhotos containsObjectIdenticalTo:photo]){
            [self.userDisabledPhotos removeObjectIdenticalTo:photo];
        }
        else{
            [self.userDisabledPhotos addObject:photo];
        }
    }
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    UIView *checkmark = [cell viewWithTag:41];
    checkmark.hidden = [self.userDisabledPhotos containsObjectIdenticalTo:photo] || photoIndex >= [self.userSelectedPhotos count];
    
    UIView *disabled = [cell viewWithTag:42];
    disabled.hidden = !checkmark.hidden || photoIndex >= [self.userSelectedPhotos count];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
    
    id object = [self.userSelectedPhotos objectAtIndex:fromIndexPath.item + fromIndexPath.section * self.product.quantityToFulfillOrder];
    [self.userSelectedPhotos removeObjectAtIndex:fromIndexPath.item + fromIndexPath.section * self.product.quantityToFulfillOrder];
    [self.userSelectedPhotos insertObject:object atIndex:toIndexPath.item + toIndexPath.section * self.product.quantityToFulfillOrder];
    
    object = [self.assets objectAtIndex:fromIndexPath.item + fromIndexPath.section * self.product.quantityToFulfillOrder];
    [self.assets removeObjectAtIndex:fromIndexPath.item + fromIndexPath.section * self.product.quantityToFulfillOrder];
    [self.assets insertObject:object atIndex:toIndexPath.item + toIndexPath.section * self.product.quantityToFulfillOrder];
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath{
    if (toIndexPath.item >= MIN(self.userSelectedPhotos.count, (self.userSelectedPhotos.count - fromIndexPath.section * self.product.quantityToFulfillOrder))){
        return NO;
    }
    if (fromIndexPath.section != toIndexPath.section){
        return NO;
    }
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item >= MIN(self.userSelectedPhotos.count, self.product.quantityToFulfillOrder)){
        return NO;
    }
    return YES;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return OLPhotoSelectionMargin;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return OLPhotoSelectionMargin;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = self.view.bounds.size;
    
    if (self.rotationSize.width != 0){
        size = self.rotationSize;
    }
    
    CGFloat width = floorf(size.width/3);
    CGFloat height = width;
    
    if (indexPath.item % 3 == 2) {
        width = size.width - 2 * width;
    }

    return CGSizeMake(width, height);
}

#pragma mark - Storyboard Methods

- (BOOL)shouldGoToOrderPreview {
    if (self.userDisabledPhotos.count > 0){
        [self.userDisabledPhotos removeAllObjects];
        [self updateTitleBasedOnSelectedPhotoQuanitity];
        [self.collectionView reloadData];
        return NO;
    }
    
    if (self.userSelectedPhotos.count - self.userDisabledPhotos.count == 0) {
        if ([UIAlertController class]){
            UIAlertController *av = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Oops!", @"") message:NSLocalizedString(@"Please select some images to print first.", @"") preferredStyle:UIAlertControllerStyleAlert];
            [av addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:NULL]];
            [self presentViewController:av animated:YES completion:NULL];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", @"") message:NSLocalizedString(@"Please select some images to print first.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [av show];
        }
        return NO;
    } 
    
    return YES;
}

- (IBAction)onButtonNextClicked {
    if ([self shouldGoToOrderPreview]) {
        [self doSegueToOrderPreview];
    }
}

-(void)doSegueToOrderPreview{
//    [OLAnalytics trackPhotosSelectedForOrder];
    UIViewController* orvc;
    if (self.product.productTemplate.templateUI == kOLTemplateUIFrame){
        orvc = [self.storyboard instantiateViewControllerWithIdentifier:@"FrameOrderReviewViewController"];
    }
    else if (self.product.productTemplate.templateUI == kOLTemplateUIPhotobook){
        orvc = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotobookViewController"];
    }
    else{
        orvc = [self.storyboard instantiateViewControllerWithIdentifier:@"OrderReviewViewController"];
    }
    [orvc safePerformSelector:@selector(setProduct:) withObject:self.product];
    [orvc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:self.userSelectedPhotos];
    [orvc safePerformSelector:@selector(setAssets:) withObject:self.assets];
    [self.navigationController pushViewController:orvc animated:YES];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kTagAlertViewSelectMorePhotos) {
        if (buttonIndex == 1) {
            [self doSegueToOrderPreview];
        }
    }
}

#pragma mark - Autorotate and Orientation Methods
// Currently here to disable landscape orientations and rotation on iOS 7. When support is dropped, these can be deleted.

- (BOOL)shouldAutorotate {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return YES;
    }
    else{
        return NO;
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
