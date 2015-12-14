//
//  OLPosterSizeSelectionViewController.m
//  Photo Mosaic
//
//  Created by Alberto De Capitani on 23/09/2014.
//  Copyright (c) 2014 Ocean Labs App Ltd. All rights reserved.
//

#import "OLPosterSizeSelectionViewController.h"
#import "OLProduct.h"
#import "OLKiteViewController.h"
#import "OLAnalytics.h"
#import "OLKitePrintSDK.h"
#import "OLKiteABTesting.h"
#import "TSMarkdownParser.h"
#import "OLPosterViewController.h"
#import "NSObject+Utils.h"
#import "OLKiteUtils.h"

@interface OLProduct (Private)

-(void)setCoverImageToImageView:(UIImageView *)imageView;
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;

@end

static UIColor *deselectedColor;

@interface OLPosterSizeSelectionViewController ()
@property (weak, nonatomic) IBOutlet UIButton *classicBtn;
@property (weak, nonatomic) IBOutlet UIButton *grandBtn;
@property (weak, nonatomic) IBOutlet UIButton *deluxeBtn;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UIImageView *productImageView;
@property (strong, nonatomic) NSMutableArray *availableButtons;
@property (weak, nonatomic) IBOutlet UILabel *chooseSizeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailsBoxTopCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailsViewHeightCon;
@property (weak, nonatomic) IBOutlet UILabel *detailsTextLabel;

@end

@implementation OLPosterSizeSelectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id context){
        self.detailsViewHeightCon.constant = size.height > size.width ? 450 : 340;
        self.detailsBoxTopCon.constant = self.detailsBoxTopCon.constant != 0 ? self.detailsViewHeightCon.constant-100 : 0;
    }completion:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.availableButtons = [@[self.classicBtn, self.grandBtn, self.deluxeBtn] mutableCopy];
    deselectedColor = [UIColor colorWithRed:0.365 green:0.612 blue:0.925 alpha:1]; /*#5d9cec*/
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Next"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(pressedContinue)];
    self.navigationItem.rightBarButtonItem = nextButton;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    [self setTitle:NSLocalizedString(@"Choose Size", @"")];
    
    CGSize size = self.view.frame.size;
    self.detailsViewHeightCon.constant = size.height > size.width ? 450 : 340;
    
    OLProduct *productA1;
    OLProduct *productA2;
    OLProduct *productA3;
    for (OLProduct *product in [OLProduct productsWithFilters:self.filterProducts]){
        if ([product.productTemplate.productCode hasSuffix:@"A1"] && product.productTemplate.gridCountX == self.product.productTemplate.gridCountX && product.productTemplate.gridCountY == self.product.productTemplate.gridCountY){
            productA1 = product;
        }
        if ([product.productTemplate.productCode hasSuffix:@"A2"] && product.productTemplate.gridCountX == self.product.productTemplate.gridCountX && product.productTemplate.gridCountY == self.product.productTemplate.gridCountY){
            productA2 = product;
        }
        if ([product.productTemplate.productCode hasSuffix:@"A3"] && product.productTemplate.gridCountX == self.product.productTemplate.gridCountX && product.productTemplate.gridCountY == self.product.productTemplate.gridCountY){
            productA3 = product;
        }
    }
    if (!productA1){
        [self.deluxeBtn removeFromSuperview];
        [self.availableButtons removeObject:self.deluxeBtn];
    }
    if (!productA2){
        [self.grandBtn removeFromSuperview];
        [self.availableButtons removeObject:self.grandBtn];
    }
    if (!productA3){
        [self.classicBtn removeFromSuperview];
        [self.availableButtons removeObject:self.classicBtn];
    }
    
    UIButton *firstButton = [self.availableButtons firstObject];
    if (firstButton == self.classicBtn){
        [self pressedClassic:nil];
    }
    else if (firstButton == self.grandBtn){
        [self pressedGrand:nil];
    }
    else if (firstButton == self.deluxeBtn){
        [self pressedDeluxe:nil];
    }
    
    if (self.availableButtons.count == 1){
        [[self.availableButtons firstObject] removeFromSuperview];
        [self.availableButtons removeAllObjects];
        [self.chooseSizeLabel removeFromSuperview];
    }
    
    UIViewController *vc = self.parentViewController;
    while (vc) {
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            break;
        }
        else{
            vc = vc.parentViewController;
        }
    }
    
    if ([OLKiteABTesting sharedInstance].hidePrice){
        [self.priceLabel removeFromSuperview];
    }
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductDescriptionScreenViewed:@"Posters" hidePrice:[OLKiteABTesting sharedInstance].hidePrice];
#endif
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackProductDescriptionScreenHitBack:@"Posters" hidePrice:[OLKiteABTesting sharedInstance].hidePrice];
    }
#endif
}

#pragma mark - actions
- (IBAction)pressedClassic:(UIButton *)sender {
    for (OLProduct *product in [OLProduct products]){
        if ([product.productTemplate.productCode hasSuffix:@"A3"] && product.productTemplate.gridCountX == self.product.productTemplate.gridCountX && product.productTemplate.gridCountY == self.product.productTemplate.gridCountY){
            self.product = product;
        }
    }
    self.classicBtn.backgroundColor = [UIColor whiteColor];
    [self.classicBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.grandBtn.backgroundColor = deselectedColor;
    [self.grandBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.deluxeBtn.backgroundColor = deselectedColor;
    [self.deluxeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    self.sizeLabel.text = @"A3:";
    [self.product setProductPhotography:0 toImageView:self.productImageView];
    
    self.priceLabel.text = self.product.unitCost;
    
    NSMutableAttributedString *attributedString = [[[TSMarkdownParser standardParser] attributedStringFromMarkdown:[self.product detailsString]] mutableCopy];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed: 0.341 green: 0.341 blue: 0.341 alpha: 1] range:NSMakeRange(0, attributedString.length)];
    self.detailsTextLabel.attributedText = attributedString;
}

- (IBAction)pressedGrand:(UIButton *)sender {
    for (OLProduct *product in [OLProduct products]){
        if ([product.productTemplate.productCode hasSuffix:@"A2"] && product.productTemplate.gridCountX == self.product.productTemplate.gridCountX && product.productTemplate.gridCountY == self.product.productTemplate.gridCountY){
            self.product = product;
        }
    }
    self.grandBtn.backgroundColor = [UIColor whiteColor];
    [self.grandBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.deluxeBtn.backgroundColor = deselectedColor;
    [self.deluxeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.classicBtn.backgroundColor = deselectedColor;
    [self.classicBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    self.sizeLabel.text = @"A2:";
    [self.product setProductPhotography:0 toImageView:self.productImageView];
    
    self.priceLabel.text = self.product.unitCost;
    
    NSMutableAttributedString *attributedString = [[[TSMarkdownParser standardParser] attributedStringFromMarkdown:[self.product detailsString]] mutableCopy];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed: 0.341 green: 0.341 blue: 0.341 alpha: 1] range:NSMakeRange(0, attributedString.length)];
    self.detailsTextLabel.attributedText = attributedString;
}

- (IBAction)pressedDeluxe:(UIButton *)sender {
    for (OLProduct *product in [OLProduct products]){
        if ([product.productTemplate.productCode hasSuffix:@"A1"] && product.productTemplate.gridCountX == self.product.productTemplate.gridCountX && product.productTemplate.gridCountY == self.product.productTemplate.gridCountY){
            self.product = product;
        }
    }
    self.classicBtn.backgroundColor = deselectedColor;
    [self.classicBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.grandBtn.backgroundColor = deselectedColor;
    [self.grandBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.deluxeBtn.backgroundColor = [UIColor whiteColor];
    [self.deluxeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
//    self.sizeLabel.text = @"A1:";
    [self.product setProductPhotography:0 toImageView:self.productImageView];
    
    self.priceLabel.text = self.product.unitCost;
    
    NSMutableAttributedString *attributedString = [[[TSMarkdownParser standardParser] attributedStringFromMarkdown:[self.product detailsString]] mutableCopy];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed: 0.341 green: 0.341 blue: 0.341 alpha: 1] range:NSMakeRange(0, attributedString.length)];
    self.detailsTextLabel.attributedText = attributedString;
}

- (IBAction)pressedContinue {
    NSString *identifier;
    if (self.product.quantityToFulfillOrder == 1){
        identifier = @"OLSingleImageProductReviewViewController";
    }
    else if (![self.delegate respondsToSelector:@selector(kiteControllerShouldAllowUserToAddMorePhotos:)] || [self.delegate kiteControllerShouldAllowUserToAddMorePhotos:[OLKiteUtils kiteViewControllerInNavStack:self.navigationController.viewControllers]]){
        identifier = @"PhotoSelectionViewController";
    }
    else{
        identifier = @"OLPosterViewController";
    }
    UIViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    [dest safePerformSelector:@selector(setProduct:) withObject:self.product];
    [dest safePerformSelector:@selector(setUserSelectedPhotos:) withObject:self.userSelectedPhotos];
    [self.navigationController pushViewController:dest animated:YES];
}

- (IBAction)onLabelDetailsTapped:(UITapGestureRecognizer *)sender {
    self.detailsBoxTopCon.constant = self.detailsBoxTopCon.constant == 0 ? self.detailsViewHeightCon.constant-100 : 0;
    [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:^{
        self.arrowImageView.transform = self.detailsBoxTopCon.constant == 0 ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI);
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }completion:^(BOOL finished){
        
    }];
    
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
