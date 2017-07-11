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

#import "OLCollagePosterViewController.h"
#import "OLAsset+Private.h"
#import "OLKiteUtils.h"
#import "OLKiteABTesting.h"
#import "UIView+RoundRect.h"
#import "OLUserSession.h"

@interface OLProduct ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

@interface OLProductPrintJob ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

@interface OLPrintOrder (Private)
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
- (void)saveOrder;
@end

@interface OLSingleImagePosterViewController () <OLArtboardDelegate>
- (void)saveAndDismissReviewController;
- (IBAction)onButtonDoneTapped:(UIButton *)sender;
- (IBAction)onButtonNextClicked:(UIButton *)sender;
@end

@implementation OLCollagePosterViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [[OLAsset userSelectedAssets] adjustNumberOfSelectedAssetsWithTotalNumberOfAssets:self.product.quantityToFulfillOrder trim:YES];
    
    self.editingTools.hidden = YES;
    [self.hintView removeFromSuperview];
    
    [self setupCtaButton];
}

- (void)setupCtaButton{
    UIButton *ctaButton = [[UIButton alloc] init];
    [ctaButton setTitle:OLLocalizedString(@"Add to Basket", @"") forState:UIControlStateNormal];
    [ctaButton addTarget:self action:@selector(onButtonDoneTapped:) forControlEvents:UIControlEventTouchUpInside];
    if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        [ctaButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
    }
    else{
        [ctaButton setBackgroundColor:[UIColor colorWithRed:0.125 green:0.498 blue:0.655 alpha:1.000]];
    }
    [ctaButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    ctaButton.frame = CGRectMake(5, self.view.frame.size.height - 55, self.view.frame.size.width-10, 50);
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:17];
    if (!font){
        font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    }
    if (font){
        [ctaButton.titleLabel setFont:font];
    }
    else{
        [ctaButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    }
    
    NSNumber *cornerRadius = [OLKiteABTesting sharedInstance].lightThemeButtonRoundCorners;
    if (cornerRadius){
        [ctaButton makeRoundRectWithRadius:[cornerRadius floatValue]];
    }
    
    [self.view addSubview:ctaButton];
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            [ctaButton setTitle:OLLocalizedString(@"Next", @"") forState:UIControlStateNormal];
        }
    }
    
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)]) {
        UIViewController *paymentVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if ([paymentVc respondsToSelector:@selector(saveAndDismissReviewController)]){
            [ctaButton setTitle:OLLocalizedString(@"Save", @"") forState:UIControlStateNormal];
            [ctaButton removeTarget:self action:@selector(onButtonNextClicked:) forControlEvents:UIControlEventTouchUpInside];
            [ctaButton addTarget:paymentVc action:@selector(saveAndDismissReviewController) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    [self configureAssetViewsForArtboard:self.artboard forSize:self.artboard.frame.size];
}

- (void)setupContainerView{
    [super setupContainerView];
    
    self.artboard.delegate = self;
    
    [self.artboard setNeedsLayout];
    [self.artboard layoutIfNeeded];
    [self configureAssetViewsForArtboard:self.artboard forSize:self.artboard.frame.size];
}

- (void)configureAssetViewsForArtboard:(OLArtboardView *)artboard forSize:(CGSize)size{
    NSUInteger gridX = self.product.productTemplate.gridCountX;
    NSUInteger gridY = self.product.productTemplate.gridCountY;
    if (gridX == 0 || gridY == 0){
        gridX = sqrt(self.product.quantityToFulfillOrder);
        gridY = gridX;
    }
    
    CGFloat relativeMarginX = 2.0 / size.width;
    CGFloat relativeMarginY = 2.0 / size.height;
    
    CGSize assetViewRelativeSize = CGSizeMake((1 - relativeMarginX * (gridX-1.0)) / gridX, (1 - relativeMarginY * (gridY-1.0)) / gridY);
    
    while(artboard.assetViews.count < gridX * gridY){
        [artboard addAssetView];
    }
    
    for (NSUInteger i = 0; i < artboard.assetViews.count; i++){
        NSUInteger x = i % gridX;
        NSUInteger y = i / gridX;
        artboard.assetViews[i].index = i;
        artboard.assetViews[i].relativeFrame = CGRectMake((assetViewRelativeSize.width + relativeMarginX) * x, (assetViewRelativeSize.height + relativeMarginY) * y, assetViewRelativeSize.width, assetViewRelativeSize.height);
    }
}

- (void)loadImageFromAsset{
    [self.artboard loadImageOnAllAssetViews];
}

- (void)preparePhotosForCheckout{
    NSMutableArray *reversePhotos = [[OLAsset userSelectedAssets].nonPlaceholderAssets mutableCopy];
    [OLCollagePosterViewController changeOrderOfPhotosInArray:reversePhotos forProduct:self.product];
    [OLUserSession currentSession].userSelectedAssets = reversePhotos;
}

+ (void)changeOrderOfPhotosInArray:(NSMutableArray*)array forProduct:(OLProduct *)product{
    NSMutableArray *subArrays = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < array.count / product.quantityToFulfillOrder; i++) {
        [subArrays addObject:[[array subarrayWithRange:NSMakeRange(i*product.quantityToFulfillOrder, product.quantityToFulfillOrder)] mutableCopy]];
    }
    
    for (NSMutableArray *subArray in subArrays){
        NSMutableArray* rows = [[NSMutableArray alloc] initWithCapacity:product.productTemplate.gridCountY];
        for (NSUInteger rowNumber = 0; rowNumber < product.productTemplate.gridCountY; rowNumber++){
            NSMutableArray* row = [[NSMutableArray alloc] initWithCapacity:product.productTemplate.gridCountX];
            for (NSUInteger photoInRow = 0; photoInRow < product.productTemplate.gridCountX; photoInRow++){
                [row addObject:subArray[rowNumber * (NSInteger)product.productTemplate.gridCountX + photoInRow]];
            }
            [rows addObject:row];
        }
        
        [subArray removeAllObjects];
        for (NSInteger rowNumber = product.productTemplate.gridCountY - 1; rowNumber >= 0; rowNumber--){
            [subArray addObjectsFromArray:rows[rowNumber]];
        }
    }
    
    [array removeAllObjects];
    for (NSArray *subArray in subArrays){
        [array addObjectsFromArray:subArray];
    }
}

- (void)saveJobWithCompletionHandler:(void(^)())handler{
    NSInteger nullCount = 0;
    for (OLAsset *asset in [[OLAsset userSelectedAssets] subarrayWithRange:NSMakeRange(0, self.product.quantityToFulfillOrder)]){
        if ([asset isKindOfClass:[OLPlaceholderAsset class]]){
            nullCount++;
        }
    }
    
    if (nullCount == self.product.quantityToFulfillOrder){
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:OLLocalizedString(@"Oops!", @"") message:OLLocalizedString(@"Please add some photos", @"") preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:OLLocalizedString(@"OK", @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    if (nullCount > 0){
        NSInteger selected = [OLAsset userSelectedAssets].nonPlaceholderAssets.count;
        NSString *title = selected == 1 ? [NSString stringWithFormat:OLLocalizedString(@"You've only selected %d photo.", @""), selected] : [NSString stringWithFormat:OLLocalizedString(@"You've only selected %d photos.", @""), selected];
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:[NSString stringWithFormat:OLLocalizedString(@"Please add %d more.", @"Please add [a number] more [photos]"), nullCount] preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:OLLocalizedString(@"OK", @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleCancel handler:NULL]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    [self preparePhotosForCheckout];
    
    NSMutableArray *photoAssets = [[NSMutableArray alloc] init];
    for (OLAsset *photo in [OLAsset userSelectedAssets]) {
        [photoAssets addObject:[photo copy]];
    }
        
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    OLProductPrintJob *job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:photoAssets];
    NSArray *jobs = [NSArray arrayWithArray:printOrder.jobs];
    for (id<OLPrintJob> existingJob in jobs){
        if ([existingJob.uuid isEqualToString:self.product.uuid]){
            job.dateAddedToBasket = [existingJob dateAddedToBasket];
            job.extraCopies = existingJob.extraCopies;
            [printOrder removePrintJob:existingJob];
        }
    }
    [job.acceptedOffers addObjectsFromArray:self.product.acceptedOffers.allObjects];
    [job.declinedOffers addObjectsFromArray:self.product.declinedOffers.allObjects];
    job.redeemedOffer = self.product.redeemedOffer;
    [printOrder addPrintJob:job];
    
    [printOrder saveOrder];
    
    if (handler){
        handler();
    }
}

- (UIViewController *)viewControllerForPresenting{
    return self;
}

- (UIView *)viewToAddDraggingAsset{
    return self.view;
}

- (OLArtboardAssetView *)assetViewAtPoint:(CGPoint)point{
    return [self.artboard findAssetViewAtPoint:point];
}

@end
