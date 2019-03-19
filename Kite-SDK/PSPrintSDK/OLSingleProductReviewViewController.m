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
#import "OLImageCachingManager.h"
#import "OLImagePickerViewController.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLNavigationController.h"
#import "OLProductPrintJob.h"
#import "OLProductTemplateOption.h"
#import "OLImageCropper.h"
#import "OLImageView.h"
#import "OLSingleProductReviewViewController.h"
#import "OLUserSession.h"
#import "UIViewController+OLMethods.h"
#import "UIView+AutoLayoutHelper.h"
#import "UIColor+OLHexString.h"
#import "OLKiteViewController+Private.h"

@interface OLImageEditViewController ()
- (void)orderViews;
- (void)onButtonClicked:(UIButton *)sender;
- (void)saveEditsToAsset:(OLAsset *)asset;
- (void)loadImageFromAsset;
- (void)updateProductRepresentationForChoice:(OLProductTemplateOptionChoice *)choice;
@property (strong, nonatomic) UIViewController *presentedVc;
@end

@interface OLSingleProductReviewViewController () <OLImageEditViewControllerDelegate>
@property (assign, nonatomic) BOOL showingBack;
@property (strong, nonatomic) OLAsset *backAsset;
@end

@implementation OLSingleProductReviewViewController

- (OLAsset *)asset{
    if (!super.asset && !self.showingBack){
        super.asset = [[OLAsset userSelectedAssets] nonPlaceholderAssets].firstObject;
    }
    
    return super.asset;
}

- (CGFloat)aspectRatio{
    return 1.435714286;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    self.view.backgroundColor = [UIColor colorWithHexString:@"E7EBEF"];
    self.printContainerView.backgroundColor = [UIColor clearColor];
    
    self.delegate = self;
    self.view.clipsToBounds = YES;
    
    if (self.navigationController.viewControllers.firstObject == self){
        self.title = self.product.productTemplate.name;
    }
    else{
        self.title = NSLocalizedStringFromTableInBundle(@"Create Image", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    }
    
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
    
    [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    
    self.ctaButton.enabled = YES;
    
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:17];
    if (!font){
        font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    }
    if (font){
        [self.ctaButton.titleLabel setFont:font];
    }
    
    if ([OLUserSession currentSession].capitalizeCtaTitles){
        [self.ctaButton setTitle:[[self.ctaButton titleForState:UIControlStateNormal] uppercaseString] forState:UIControlStateNormal];
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.hintView = [[[OLKiteUtils kiteResourcesBundle] loadNibNamed:@"OLHintView" owner:self options:nil] objectAtIndex:0];
    self.hintView.alpha = 0;
    self.hintView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.hintView];
    
    [self.hintView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.hintView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.hintView.superview attribute:NSLayoutAttributeLeading multiplier:1 constant:5]];
    [self.hintView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.hintView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.hintView.superview attribute:NSLayoutAttributeTrailing multiplier:1 constant:-5]];
    [self.hintView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.hintView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.editingTools attribute:NSLayoutAttributeTop multiplier:1 constant:-15]];
    [self.hintView setContentHuggingPriority:1000 forAxis:UILayoutConstraintAxisHorizontal];
    [self.hintView setContentCompressionResistancePriority:1000 forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.hintView viewWithTag:10].transform = CGAffineTransformMakeRotation(M_PI_4);
    
    self.hintView.layer.masksToBounds = NO;
    self.hintView.layer.shadowOffset = CGSizeMake(0, 2);
    self.hintView.layer.shadowRadius = 5;
    self.hintView.layer.shadowOpacity = 0.3;
}

- (void)showHintViewForView:(UIView *)view header:(NSString *)header body:(NSString *)body delay:(BOOL)shouldDelay{
    if (!self.hintView){
        return;
    }
    for (NSLayoutConstraint *con in self.view.constraints){
        if ([con.identifier isEqualToString:@"toolBarCon"]){
            [self.view removeConstraint:con];
        }
    }
    NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:[self.hintView viewWithTag:10] attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    con.identifier = @"toolBarCon";
    [self.view addConstraint:con];
    
    if (header){
        UILabel *label = (UILabel *)[self.hintView viewWithTag:20];
        [label setText:header];
        
        UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:25];
        if (!font){
            font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:25];
        }
        
        if (font){
            [label setFont:font];
        }
    }
    if (body){
        UILabel *label = (UILabel *)[self.hintView viewWithTag:30];
        [label setText:body];
        
        UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:13];
        if (font){
            [label setFont:font];
        }
    }
    
    NSTimeInterval delay = shouldDelay ? 1 : 0;
    NSTimeInterval duration = 0.3;
    [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.hintView.alpha = 1;
    } completion:NULL];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self addBasketIconToTopRight];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self showHintViewIfNeeded];
}

- (void)showHintViewIfNeeded{
    if ([OLAsset userSelectedAssets].nonPlaceholderAssets.count == 0 && self.hintView.alpha <= 0.1f) {
        [self showHintViewForView:self.editingTools.button1 header:NSLocalizedStringFromTableInBundle(@"Let's pick\nan image!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Let's pick an image! The \n means there is a line break there. Please put it in the middle of the phrase, as best as you can. If one needs to be longer, it should be the first half.") body:NSLocalizedStringFromTableInBundle(@"Start by tapping this button", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")delay:YES];
    }
}

- (void)orderViews{
    [super orderViews];
    [self.view bringSubviewToFront:self.hintView];
}

- (void)onButtonDoneTapped:(UIButton *)sender{
    [self doCheckout];
}

- (void)saveJobWithCompletionHandler:(void(^)(void))handler{
    [self saveEditsToAsset:self.asset];
    OLAsset *asset = [self.asset copy];
    
    [asset dataLengthWithCompletionHandler:^(long long dataLength, NSError *error){
        if (dataLength < 40000){
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Image Is Too Small", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please zoom out or pick a higher quality image", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:NULL]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Print It Anyway", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self saveEditsToAsset:self.asset];
                [self saveJobNowWithCompletionHandler:handler];
            }]];
            [self presentViewController:alert animated:YES completion:NULL];
            return;
            
        }
        
        [self saveJobNowWithCompletionHandler:handler];
    }];
}

- (void)saveJobNowWithCompletionHandler:(void(^)(void))handler {
    if (self.product.productTemplate.collectionName && self.product.productTemplate.collectionId){
        NSString *templateId = self.product.selectedOptions[self.product.productTemplate.collectionId];
        if (templateId){
            OLProduct *product = [OLProduct productWithTemplateId:templateId];
            product.selectedOptions = self.product.selectedOptions;
            product.uuid = self.product.uuid;
            self.product = product;
        }
    }
    
    OLAsset *asset = [self.asset copy];
    NSArray *assetArray = @[asset];
    
    OLProductPrintJob *job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:assetArray];
    for (NSString *option in self.product.selectedOptions.allKeys){
        [job setValue:self.product.selectedOptions[option] forOption:option];
    }
    
    [[PhotobookSDK shared] addProductToBasket:job];
    
    if (handler){
        handler();
    }    
}

- (void) doCheckout{
    if ([OLAsset userSelectedAssets].nonPlaceholderAssets.count == 0) {
        if (self.hintView){
            [self showHintViewForView:self.editingTools.button1 header:NSLocalizedStringFromTableInBundle(@"Let's pick\nan image!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Let's pick an image! The \n means there is a line break there. Please put it in the middle of the phrase, as best as you can. If one needs to be longer, it should be the first half.") body:NSLocalizedStringFromTableInBundle(@"Start by tapping this button", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")delay:NO];
        }
        else{
            UIAlertController *av = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please add some photos", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
            [av addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:NULL]];
            [self presentViewController:av animated:YES completion:NULL];
        }
        return;
    }
    self.ctaButton.enabled = NO;
    [self saveJobWithCompletionHandler:^{
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
    }];
}

- (void)onButtonClicked:(UIButton *)sender {
    NSTimeInterval duration = 0.3;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.hintView.alpha = 0;
    } completion:NULL];
    
    [super onButtonClicked:sender];
}

- (void)imageEditViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset{
    [[OLAsset userSelectedAssets] replaceObjectAtIndex:[[OLAsset userSelectedAssets] indexOfObjectIdenticalTo:self.asset] withObject:asset];
}

- (void)imageEditViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    //Do nothing
}

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    OLAsset *asset = [addedAssets.firstObject copy];
    self.edits = [asset.edits copy];
    
    NSInteger assetIndex = 0;
    if (self.showingBack){
        self.backAsset = asset;
        assetIndex = 1;
    }
    if (asset) {
        self.asset = asset;
        
        if ([OLAsset userSelectedAssets].count > assetIndex && vc.maximumPhotos == 1){
            [[OLAsset userSelectedAssets] replaceObjectAtIndex:assetIndex withObject:asset];
        }
        else{
            [[OLAsset userSelectedAssets] addObject:asset];
        }
        
        self.ctaButton.enabled = YES;
        id view = [self.view viewWithTag:1010];
        if ([view isKindOfClass:[UIActivityIndicatorView class]]){
            [(UIActivityIndicatorView *)view startAnimating];
        }
        
        [self loadImageFromAsset];
    }
    
    if (self.presentedVc){
        [self.presentedVc dismissViewControllerAnimated:YES completion:NULL];
    }
    else{
        [vc dismissViewControllerAnimated:YES completion:NULL];
    }
}

@end
