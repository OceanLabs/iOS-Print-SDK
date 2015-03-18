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
#import <objc/runtime.h>
#import <OLInstagramImagePickerController.h>
#import <OLInstagramImage.h>
#import <OLFacebookImagePickerController.h>
#import <OLFacebookImage.h>
#import <UIImageView+FadeIn.h>
#import "OLPrintJob.h"
#import "OLAddress.h"
#import "OLAsset.h"
#import <OLImageEditorViewController.h>
#import "OLProductPrintJob.h"
#import <UIColor+HexString.h>
#import "OLCheckoutViewController.h"
#import "OLConstants.h"
#import <LXReorderableCollectionViewFlowLayout.h>

NSInteger OLPhotoSelectionMargin = 0;

static const NSUInteger kTagAlertViewSelectMorePhotos = 99;

@interface UIActionSheet (Cell)
@property (nonatomic, strong) UICollectionViewCell *cell;
@end

static void *ActionSheetCellKey;

@implementation UIActionSheet(Cell)

- (void)setCell:(UICollectionViewCell *)cell {
    objc_setAssociatedObject(self, ActionSheetCellKey, cell, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UICollectionViewCell *)cell {
    return objc_getAssociatedObject(self, ActionSheetCellKey);
}

@end

@interface OLPhotoSelectionViewController () <UINavigationControllerDelegate,
                                            CTAssetsPickerControllerDelegate,
                                            UICollectionViewDataSource,
                                            UICollectionViewDelegate,
                                            UICollectionViewDelegateFlowLayout,
                                            UIActionSheetDelegate,
                                            OLInstagramImagePickerControllerDelegate,
                                            OLFacebookImagePickerControllerDelegate,
                                            LXReorderableCollectionViewDataSource,
                                            UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet OLPhotoSelectionButton *galleryButton;
@property (nonatomic, weak) IBOutlet OLPhotoSelectionButton *instagramButton;
@property (nonatomic, weak) IBOutlet OLPhotoSelectionButton *facebookButton;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) CTAssetsPickerController *picker;
@property (nonatomic, strong) NSMutableArray *userSelectedPhotos;
@property (strong, nonatomic) NSMutableArray *userDisabledPhotos;

@property (nonatomic, weak) IBOutlet UILabel *chooseImportSourceLabel;
@property (nonatomic, weak) IBOutlet UIButton *buttonGalleryImport, *buttonInstagramImport, *buttonFacebookImport;

@property (nonatomic, weak) IBOutlet UIButton *buttonNext;
@property (nonatomic, weak) IBOutlet UIView *noSelectedPhotosView;
@property (weak, nonatomic) IBOutlet UIView *clearButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;
@end

@implementation OLPhotoSelectionViewController

-(NSMutableArray *) userSelectedPhotos{
    if (!_userSelectedPhotos){
        NSMutableArray *mutableUserSelectedPhotos = [[NSMutableArray alloc] init];
        for (id asset in self.assets){
            OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
            printPhoto.serverImageSize = [self.product serverImageSize];
            printPhoto.asset = asset;
            [mutableUserSelectedPhotos addObject:printPhoto];
        }
        _userSelectedPhotos = mutableUserSelectedPhotos;
    }
    return _userSelectedPhotos;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.userSelectedPhotos = [[NSMutableArray alloc] init];
    self.userDisabledPhotos = [[NSMutableArray alloc] init];
//    [self onUserSelectedPhotoCountChange];
    
    self.galleryButton.image = [UIImage imageNamed:@"import_gallery"];
    self.galleryButton.title = NSLocalizedString(@"Camera Roll", @"");
    self.galleryButton.mainColor = [UIColor colorWithHexString:@"#48cfad"];
    
    self.instagramButton.image = [UIImage imageNamed:@"import_instagram"];
    self.instagramButton.title = NSLocalizedString(@"Instagram", @"");
    self.instagramButton.mainColor = [UIColor colorWithHexString:@"#f6bb42"];
    
    self.facebookButton.image = [UIImage imageNamed:@"import_facebook"];
    self.facebookButton.title = NSLocalizedString(@"Facebook", @"");
    self.facebookButton.mainColor = [UIColor colorWithHexString:@"#5d9cec"];
    
    UIFont *font = [UIFont fontWithName:@"MissionGothic-Bold" size:15];
    self.buttonFacebookImport.titleLabel.font = font;
    self.buttonGalleryImport.titleLabel.font = font;
    self.buttonInstagramImport.titleLabel.font = font;
    self.chooseImportSourceLabel.font = [UIFont fontWithName:@"MissionGothic-Regular" size:19];
    
    [self.buttonFacebookImport setBackgroundImage:[self imageWithColor:[UIColor colorWithHexString:@"#497aba"]] forState:UIControlStateHighlighted];
    [self.buttonGalleryImport setBackgroundImage:[self imageWithColor:[UIColor colorWithHexString:@"#369c82"]] forState:UIControlStateHighlighted];
    [self.buttonInstagramImport setBackgroundImage:[self imageWithColor:[UIColor colorWithHexString:@"#c29334"]] forState:UIControlStateHighlighted];
    
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

-(void) viewWillAppear:(BOOL)animated{
    [self.collectionView reloadData];
}

-(void) viewDidAppear:(BOOL)animated{
    [self updateNoSelectedPhotosView];
    [self updateTitleBasedOnSelectedPhotoQuanitity];
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
    for (OLPrintPhoto *printPhoto in self.userDisabledPhotos){
        if (![self.userSelectedPhotos containsObject:printPhoto]){
            [self.userDisabledPhotos removeObject:printPhoto];
        }
    }
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
    } else if (self.userSelectedPhotos.count == 0 && self.noSelectedPhotosView.alpha <= 0.1f) {
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
        [UIView animateKeyframesWithDuration:0.15 delay:0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear animations:^{
            self.clearButtonContainerView.transform = CGAffineTransformIdentity;
        }completion:NULL];
    }
}

- (void)populateArrayWithNewArray:(NSArray *)array dataType:(Class)class {
    NSMutableArray *photoArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    
    for (id object in array) {
        OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
        printPhoto.serverImageSize = self.product.serverImageSize;
        printPhoto.asset = object;
        [photoArray addObject:printPhoto];
    }
    
    // First remove any that are not returned.
    NSMutableArray *removeArray = [NSMutableArray arrayWithArray:self.userSelectedPhotos];
    for (OLPrintPhoto *object in self.userSelectedPhotos) {
        if (![object.asset isKindOfClass:class] || [photoArray containsObject:object]) {
            [removeArray removeObject:object];
        }
    }
    
    [self.userSelectedPhotos removeObjectsInArray:removeArray];
    
    // Second, add the remaining objects to the end of the array without replacing any.
    NSMutableArray *addArray = [NSMutableArray arrayWithArray:photoArray];
    for (id object in self.userSelectedPhotos) {
        if ([addArray containsObject:object]) {
            [addArray removeObject:object];
        }
    }
    [self.userSelectedPhotos addObjectsFromArray:addArray];
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    for (OLPrintPhoto *photo in self.userSelectedPhotos) {
//        [photo unloadImage];
    }
}

#pragma mark - Actions

- (IBAction)cameraRollSelected:(id)sender {
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    picker.delegate = self;
    picker.assetsFilter = [ALAssetsFilter allPhotos];
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
    OLInstagramImagePickerController *picker = nil;
    picker = [[OLInstagramImagePickerController alloc] initWithClientId:@"8e298e2947f04a07a21ae306cc32cbb8" secret:@"981de984cb954e2196563493f85b13bf" redirectURI:@"sticky9://instagram-callback"];
    
    picker.delegate = self;
    picker.selected = [self createAssetArray];
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)facebookSelected:(id)sender {
//    OLFacebookImagePickerController *picker = nil;
//    picker = [[OLFacebookImagePickerController alloc] init];
//    picker.delegate = self;
//    picker.selected = [self createAssetArray];
//    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)onButtonClearClicked:(UIButton *)sender {
    for (id photo in self.userDisabledPhotos){
        [self.userSelectedPhotos removeObject:photo];
    }
    [self.userDisabledPhotos removeAllObjects];
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    [self.collectionView reloadData];
}

#pragma mark - CTAssetsPickerControllerDelegate Methods

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

#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger number = collectionView.frame.size.height / 105 ;
    return MIN(MAX(self.userSelectedPhotos.count, number * 3), self.product.quantityToFulfillOrder);
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return ((NSInteger)(self.userSelectedPhotos.count / self.product.quantityToFulfillOrder))+1;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerView" forIndexPath:indexPath];
    
    UILabel *label = (UILabel *)[cell viewWithTag:190];
    NSString *title;
    OLTemplateClass templateClass = [OLProductTemplate templateWithId:self.product.templateId].templateClass;
    if (templateClass == kOLTemplateClassFrame){
        title = [[NSString alloc]initWithFormat:@"#%lu %@", indexPath.section + 1, self.product.productTemplate.name];
    }
    else{
        title = [[NSString alloc]initWithFormat:@"#%lu Pack of %lu %@", indexPath.section + 1, (unsigned long)self.product.quantityToFulfillOrder, self.product.productTemplate.name];
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
        [photo setThumbImageForImageView:imageView];
        checkmark.hidden = [self.userDisabledPhotos containsObject:photo];
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
    if (indexPath.row < [self.userSelectedPhotos count]){
        photo = self.userSelectedPhotos[indexPath.row + indexPath.section * self.product.quantityToFulfillOrder];
        if ([self.userDisabledPhotos containsObject:photo]){
            [self.userDisabledPhotos removeObject:photo];
        }
        else{
            [self.userDisabledPhotos addObject:photo];
        }
    }
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    UIView *checkmark = [cell viewWithTag:41];
    checkmark.hidden = [self.userDisabledPhotos containsObject:photo] || indexPath.row >= [self.userSelectedPhotos count];
    
    UIView *disabled = [cell viewWithTag:42];
    disabled.hidden = !checkmark.hidden || indexPath.row >= [self.userSelectedPhotos count];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    
    id object = [self.userSelectedPhotos objectAtIndex:fromIndexPath.item];
    [self.userSelectedPhotos removeObjectAtIndex:fromIndexPath.item];
    [self.userSelectedPhotos insertObject:object atIndex:toIndexPath.item];
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
//    if (indexPath.item % 3 == 1) {
        return CGSizeMake(self.view.bounds.size.width/3, self.view.bounds.size.width/3);
//    } else {
//        return CGSizeMake(106, 106);
//    }
}

#pragma mark - Autorotate and Orientation Methods

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Storyboard Methods

- (BOOL)shouldGoToOrderPreview {
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
    OLOrderReviewViewController* orvc;
    if (self.product.productTemplate.templateClass == kOLTemplateClassFrame){
        orvc = [self.storyboard instantiateViewControllerWithIdentifier:@"FrameOrderReviewViewController"];
    }
    else{
        orvc = [self.storyboard instantiateViewControllerWithIdentifier:@"OrderReviewViewController"];
    }
    orvc.product = self.product;
    NSMutableArray *finalPhotos = [[NSMutableArray alloc] init];
    [finalPhotos addObjectsFromArray:self.userSelectedPhotos];
    [finalPhotos removeObjectsInArray:self.userDisabledPhotos];
    orvc.userSelectedPhotos = finalPhotos;
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

@end
