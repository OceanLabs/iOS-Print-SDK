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
#import "OLKiteViewController.h"
#import "OLCustomPhotoProvider.h"
#import "OLImagePickerPhotosPageViewController.h"
#import <Photos/Photos.h>

@interface OLKiteViewController ()
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (strong, nonatomic) NSMutableArray <OLCustomPhotoProvider *> *customImageProviders;
@end

@interface OLImagePickerViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIPageViewControllerDelegate, UIPageViewControllerDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *sourcesCollectionView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) UIPageViewController *pageController;

@end

@implementation OLImagePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    OLImagePickerPhotosPageViewController *vc = self.pageController.viewControllers.firstObject;
    if ([vc isKindOfClass:[OLImagePickerPhotosPageViewController class]]){
        vc.collectionView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + self.sourcesCollectionView.frame.size.height, 0, 0, 0);
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{
    return [self viewControllerAtIndex:0];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
    return [self viewControllerAtIndex:0];
}

- (UIViewController *)viewControllerAtIndex:(NSInteger)index{
    OLImagePickerPhotosPageViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePickerPhotosPageViewController"];
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.wantsIncrementalChangeDetails = NO;
    options.includeHiddenAssets = NO;
    options.includeAllBurstAssets = NO;
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


@end
