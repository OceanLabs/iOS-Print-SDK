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

#import "OLImagePickerViewController.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLKiteUtils.h"
#import "OLCustomPhotoProvider.h"
#import "OLImagePickerPhotosPageViewController.h"
#import <Photos/Photos.h>
#import "OLPrintPhoto.h"
#import "OLUpsellViewController.h"
#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLProductPrintJob.h"
#import "OLPrintOrder.h"

@interface OLKiteViewController ()
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (strong, nonatomic) NSMutableArray <OLCustomPhotoProvider *> *customImageProviders;
@property (strong, nonatomic) OLPrintOrder *printOrder;
@end

@interface OLImagePickerViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIPageViewControllerDelegate, UIPageViewControllerDataSource, OLUpsellViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *sourcesCollectionView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) NSMutableArray *selectedImages;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;

@end

@interface OLProduct ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
@end

@interface OLProductPrintJob ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

@interface OLPrintOrder ()
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
@end

@implementation OLImagePickerViewController

- (NSMutableArray *)userSelectedPhotos{
    OLKiteViewController *kiteVc = [OLKiteUtils kiteVcForViewController:self];
    return kiteVc.userSelectedPhotos;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectedImages = [[NSMutableArray alloc] init];
    self.automaticallyAdjustsScrollViewInsets = NO;
        
    self.sourcesCollectionView.delegate = self;
    self.sourcesCollectionView.dataSource = self;
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageController.delegate = self;
    self.pageController.dataSource = self;
    [self.pageController setViewControllers:@[[self viewControllerAtIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    [self addChildViewController:self.pageController];
    [self.containerView addSubview:self.pageController.view];
    
    UIView *view = self.pageController.view;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        
        self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        UIView *view = self.visualEffectView;
        [self.sourcesCollectionView.superview insertSubview:view belowSubview:self.sourcesCollectionView];
        
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
        self.sourcesCollectionView.superview.backgroundColor = [UIColor whiteColor];
    }

}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    OLImagePickerPhotosPageViewController *vc = self.pageController.viewControllers.firstObject;
    if ([vc isKindOfClass:[OLImagePickerPhotosPageViewController class]]){
        vc.albumLabelContainerTopCon.constant = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + self.sourcesCollectionView.frame.size.height;
        vc.collectionView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + self.sourcesCollectionView.frame.size.height + vc.albumLabelContainer.frame.size.height, 0, 0, 0);
    }
}

#pragma mark PageViewController

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{
    return [self viewControllerAtIndex:0];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
    return [self viewControllerAtIndex:0];
}

- (UIViewController *)viewControllerAtIndex:(NSInteger)index{
    OLImagePickerPhotosPageViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePickerPhotosPageViewController"];
    vc.selectedImages = self.selectedImages;
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.wantsIncrementalChangeDetails = NO;
    options.includeHiddenAssets = NO;
    options.includeAllBurstAssets = NO;
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    if ([options respondsToSelector:@selector(setIncludeAssetSourceTypes:)]){
        options.includeAssetSourceTypes = PHAssetSourceTypeCloudShared | PHAssetSourceTypeUserLibrary | PHAssetSourceTypeiTunesSynced;
    }
    
    vc.assets = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
    
    vc.collectionView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + self.sourcesCollectionView.frame.size.height, 0, 0, 0);
    vc.quantityPerItem = self.product.quantityToFulfillOrder;
    
    [vc.view class]; //force view did load
    vc.collectionView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + self.sourcesCollectionView.frame.size.height, 0, 0, 0);
    
    return vc;
}

#pragma mark CollectionView

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"sourceCell" forIndexPath:indexPath];
    
    UIImageView *imageView = [cell viewWithTag:10];
    UILabel *label = [cell viewWithTag:20];
    if (indexPath.item == [OLKiteUtils cameraRollProviderIndex:self]){
        imageView.image = [UIImage imageNamedInKiteBundle:@"import_gallery"];
        label.text = NSLocalizedString(@"Camera Roll", @"");
    }
    else if (indexPath.item == [OLKiteUtils facebookProviderIndex:self]){
        imageView.image = [UIImage imageNamedInKiteBundle:@"import_facebook"];
        label.text = NSLocalizedString(@"Facebook", @"");
    }
    else if (indexPath.item == [OLKiteUtils instagramProviderIndex:self]){
        imageView.image = [UIImage imageNamedInKiteBundle:@"import_instagram"];
        label.text = NSLocalizedString(@"Instagram", @"");
    }
    else if (indexPath.item == [OLKiteUtils qrCodeProviderStartIndex:self]){
        imageView.image = [UIImage imageNamedInKiteBundle:@"import_qr"];
        label.text = NSLocalizedString(@"Transfer from your phone", @"");
    }
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_SOURCES
    else{
        imageView.image = [[OLKiteUtils kiteVcForViewController:self].customImageProviders[indexPath.item - self.customProvidersStartAtIndex] icon];
    }
#endif
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger result = 0;
    if ([OLKiteUtils cameraRollEnabled:self]){
        result++;
    }
    if ([OLKiteUtils instagramEnabled]){
        result++;
    }
    if ([OLKiteUtils facebookEnabled]){
        result++;
    }
    if ([OLKiteUtils qrCodeUploadEnabled]){
        result++;
    }
    result += [OLKiteUtils kiteVcForViewController:self].customImageProviders.count;
    
    return result;
}

#pragma mark Navigation

- (BOOL)shouldGoToOrderPreview {
    if (self.userSelectedPhotos.count == 0) {
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

- (IBAction)onButtonNextClicked:(UIButton *)sender {
    if ([self shouldGoToOrderPreview]) {
        
        for (id asset in self.selectedImages){ //Replace this with populateArray...
            OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
            if ([asset isKindOfClass:[PHAsset class]]){
                printPhoto.asset = asset;
            }
            
            if (printPhoto){
                [self.userSelectedPhotos addObject:printPhoto];
            }
        }
        
        
        OLUpsellOffer *offer = [self upsellOfferToShow];
        BOOL shouldShowOffer = offer != nil;
        if (offer){
            shouldShowOffer &= offer.minUnits <= self.userSelectedPhotos.count;
            shouldShowOffer &= offer.maxUnits == 0 || offer.maxUnits >= self.userSelectedPhotos.count;
            shouldShowOffer &= [OLProduct productWithTemplateId:offer.offerTemplate] != nil;
        }
        
        [OLAnalytics trackUpsellShown:shouldShowOffer];
        if (shouldShowOffer){
            OLUpsellViewController *c = [self.storyboard instantiateViewControllerWithIdentifier:@"OLUpsellViewController"];
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8){
                c.providesPresentationContextTransitionStyle = true;
                c.definesPresentationContext = true;
            }
            c.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            c.delegate = self;
            c.offer = offer;
            c.triggeredProduct = self.product;
            [self presentViewController:c animated:NO completion:NULL];
        }
        else{
            [self showOrderPreview];
        }
    }
}

-(void)showOrderPreview{
    UIViewController* orvc = [self.storyboard instantiateViewControllerWithIdentifier:[OLKiteUtils reviewViewControllerIdentifierForProduct:self.product photoSelectionScreen:NO]];
    
    [orvc safePerformSelector:@selector(setProduct:) withObject:self.product];
    [orvc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:self.userSelectedPhotos];
    [self.navigationController pushViewController:orvc animated:YES];
}

#pragma mark Upsells

- (OLUpsellOffer *)upsellOfferToShow{
    NSArray *upsells = self.product.productTemplate.upsellOffers;
    if (upsells.count == 0){
        return nil;
    }
    
    OLUpsellOffer *offerToShow;
    for (OLUpsellOffer *offer in upsells){
        //Check if offer is valid for this point
        if (offer.active && offer.type == OLUpsellOfferTypeItemAdd){
            
            if ([self.product hasOfferIdBeenUsed:offer.identifier]){
                continue;
            }
            if ([[OLKiteUtils kiteVcForViewController:self].printOrder hasOfferIdBeenUsed:offer.identifier]){
                continue;
            }
            
            //Find the max priority offer
            if (!offerToShow || offerToShow.priority < offer.priority){
                offerToShow = offer;
            }
        }
    }
    
    return offerToShow;
}

- (void)userDidDeclineUpsell:(OLUpsellViewController *)vc{
    [self.product.declinedOffers addObject:vc.offer];
    [vc dismissViewControllerAnimated:NO completion:^{
        [self showOrderPreview];
    }];
}

- (void)userDidAcceptUpsell:(OLUpsellViewController *)vc{
    [self.product.acceptedOffers addObject:vc.offer];
    [vc dismissViewControllerAnimated:NO completion:^{
        if (vc.offer.prepopulatePhotos){
            id<OLPrintJob> job = [self addItemToBasketWithTemplateId:vc.offer.offerTemplate];
            [(OLProductPrintJob *)job setRedeemedOffer:vc.offer];
            [self showOrderPreview];
        }
        else if ([self.product.templateId isEqualToString:vc.offer.offerTemplate]){
            self.product.redeemedOffer = vc.offer;
            //TODO update qty here
        }
        else{
            id<OLPrintJob> job = [self addItemToBasketWithTemplateId:self.product.templateId];
            [[(OLProductPrintJob *)job acceptedOffers] addObject:vc.offer];
            
            OLProduct *offerProduct = [OLProduct productWithTemplateId:vc.offer.offerTemplate];
            UIViewController *nextVc = [self.storyboard instantiateViewControllerWithIdentifier:[OLKiteUtils reviewViewControllerIdentifierForProduct:offerProduct photoSelectionScreen:[OLKiteUtils imageProvidersAvailable:self]]];
            [nextVc safePerformSelector:@selector(setKiteDelegate:) withObject:self.delegate];
            [nextVc safePerformSelector:@selector(setProduct:) withObject:offerProduct];
            NSMutableArray *stack = [self.navigationController.viewControllers mutableCopy];
            [stack removeObject:self];
            [stack addObject:nextVc];
            [self.navigationController setViewControllers:stack animated:YES];
        }
    }];
}

- (id<OLPrintJob>)addItemToBasketWithTemplateId:(NSString *)templateId{
    OLProduct *offerProduct = [OLProduct productWithTemplateId:templateId];
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    if (offerProduct.productTemplate.templateUI == kOLTemplateUINonCustomizable){
        //Do nothing, no assets needed
    }
    else if (offerProduct.quantityToFulfillOrder == 1){
        [assets addObject:[OLAsset assetWithDataSource:[self.userSelectedPhotos.firstObject copy]]];
    }
    else{
        for (OLPrintPhoto *photo in self.userSelectedPhotos){
            [assets addObject:[OLAsset assetWithDataSource:[photo copy]]];
        }
    }
    
    id<OLPrintJob> job;
    if ([OLProductTemplate templateWithId:templateId].templateUI == kOLTemplateUIPhotobook){
        job = [OLPrintJob photobookWithTemplateId:templateId OLAssets:assets frontCoverOLAsset:nil backCoverOLAsset:nil];
    }
    else{
        job = [OLPrintJob printJobWithTemplateId:templateId OLAssets:assets];
    }
    
    [[OLKiteUtils kiteVcForViewController:self].printOrder addPrintJob:job];
    return job;
}

@end
