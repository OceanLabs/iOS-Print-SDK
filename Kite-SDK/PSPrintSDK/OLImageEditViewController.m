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
#import "OLAsset+Private.h"
#import "OLColorSelectionCollectionViewCell.h"
#import "OLCustomViewControllerPhotoProvider.h"
#import "OLImageEditViewController.h"
#import "OLImagePickerViewController.h"
#import "OLKiteABTesting.h"
#import "OLKiteUtils.h"
#import "OLNavigationController.h"
#import "OLPhotoTextField.h"
#import "OLProductOverviewViewController.h"
#import "OLProductTemplateOption.h"
#import "OLUserSession.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIImageView+FadeIn.h"
#import "UIView+RoundRect.h"
#import "OLCustomPickerController.h"
#import "OLTouchTolerantView.h"
#import "OLAnalytics.h"
#import "UIView+AutoLayoutHelper.h"
#import "UIColor+OLHexString.h"
#import "OLKiteViewController+Private.h"
#import "OLImageDownloader.h"
#import "UIImage+OLUtils.h"

const NSInteger kOLEditTagImages = 10;
const NSInteger kOLEditTagProductOptionsTab = 20;
const NSInteger kOLEditTagImageTools = 30;
/**/const NSInteger kOLEditTagTextTools = 31;
/**/const NSInteger kOLEditTagTextColors = 32;
/**/const NSInteger kOLEditTagFonts = 33;
/**/const NSInteger kOLEditTagFilters = 34;
const NSInteger kOLEditTagCrop = 40;

@interface OLKiteViewController ()
@property (strong, nonatomic) NSArray *fontNames;
@property (strong, nonatomic) NSMutableArray <OLImagePickerProvider *> *customImageProviders;
- (void)setLastTouchDate:(NSDate *)date forViewController:(UIViewController *)vc;
@end

@interface OLProductOverviewViewController ()
- (void)setupProductRepresentation;
@end

@interface RMImageCropper()
- (void)panRecognized:(UIPanGestureRecognizer *)recognizer;
- (void)pinchRecognized:(UIPinchGestureRecognizer *)recognizer;
@end

@interface OLImageEditViewController () <RMImageCropperDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, OLPhotoTextFieldDelegate, OLImagePickerViewControllerDelegate>
@property (assign, nonatomic) NSInteger initialOrientation;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerYCon;

@property (strong, nonatomic) NSMutableArray<OLPhotoTextField *> *textFields;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView2;
@property (strong, nonatomic) NSArray<UIColor *> *availableColors;
@property (strong, nonatomic) UIView *textFieldsView;
@property (strong, nonatomic) NSArray<NSString *> *fonts;
@property (assign, nonatomic) CGFloat textFieldKeyboardDiff;
@property (assign, nonatomic) BOOL resizingTextField;
@property (assign, nonatomic) BOOL rotatingTextField;

@property (strong, nonatomic) OLPhotoTextField *activeTextField;
@property (assign, nonatomic) CGFloat originalDrawerHeight;

@property (strong, nonatomic) NSMutableArray *allViews;
@property (strong, nonatomic) NSMutableArray *cropFrameGuideViews;
@property (strong, nonatomic) UIView *safeAreaView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *artboardTopCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *artboardLeftCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *artboardBottomCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *artboardRightCon;
@property (weak, nonatomic) UIView *gestureView;
@property (strong, nonatomic) UIButton *closeButton;

@property (weak, nonatomic) OLProductTemplateOption *selectedOption;
@property (weak, nonatomic) OLProductTemplateOptionChoice *selectedChoice;
@property (strong, nonatomic) UITextField *borderTextField;
@property (assign, nonatomic) BOOL animating;

@property (strong, nonatomic) OLImagePickerViewController *vcDelegateForCustomVc;
@property (strong, nonatomic) UIViewController *presentedVc;

@property (assign, nonatomic) CGAffineTransform backupTransform;
@property (strong, nonatomic) UIImage *thumbnailOriginalImage;
@property (strong, nonatomic) UIImage *fullImage;

@property (assign, nonatomic) BOOL didReplaceAsset;

@end

@implementation OLImageEditViewController

-(NSMutableArray *) allViews{
    if (!_allViews){
        _allViews = [[NSMutableArray alloc] init];
    }
    return _allViews;
}

- (OLProductTemplateOptionChoice *)selectedChoice{
    if (!_selectedChoice && self.selectedOption && ![self.selectedOption.code isEqualToString:@"garment_size"]){
        _selectedChoice = self.selectedOption.choices.firstObject;
    }
    
    return _selectedChoice;
}

-(NSArray<NSString *> *) fonts{
    if (!_fonts){
        OLKiteViewController *kvc = [OLUserSession currentSession].kiteVc;
        _fonts = [kvc fontNames];
    }
    if (!_fonts){
        NSMutableArray<NSString *> *fonts = [[NSMutableArray<NSString *> alloc] init];
        for (NSString *familyName in [UIFont familyNames]){
            for (NSString *fontName in [UIFont fontNamesForFamilyName:familyName]) {
                [fonts addObject:fontName];
            }
        }
        [fonts addObject:NSLocalizedStringFromTableInBundle(@"Default", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
        _fonts = [fonts sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    return _fonts;
}

-(OLPhotoEdits *) edits{
    if (!_edits && self.asset){
        _edits = [self.asset.edits copy];
    }
    if (!_edits){
        _edits = [[OLPhotoEdits alloc] init];
    }
    return _edits;
}

-(NSMutableArray *) textFields{
    if (!_textFields){
        _textFields = [[NSMutableArray alloc] init];
    }
    return _textFields;
}

- (UIEdgeInsets)borderInsets{
    if (self.product){
        return self.product.productTemplate.imageBorder;
    }
    
    return _borderInsets;
}

- (BOOL)shouldEnableGestures{
    return YES;
}

- (NSArray <NSString *> *)filterNames{
    return @[@"", @"CIPhotoEffectMono", @"CIPhotoEffectTonal", @"CIPhotoEffectNoir", @"CIPhotoEffectFade", @"CIPhotoEffectChrome", @"CIPhotoEffectProcess", @"CIPhotoEffectTransfer", @"CIPhotoEffectInstant", @"CISepiaTone", @"CIColorPosterize"];
}

- (void)setActiveTextField:(OLPhotoTextField *)activeTextField{
    if (activeTextField){
        if (self.editingTools.collectionView.tag != kOLEditTagTextTools && activeTextField != _activeTextField){ //Showing colors/fonts for another textField. Dismiss first
            [self dismissDrawerWithCompletionHandler:^(BOOL finished){
                self.editingTools.collectionView.tag = kOLEditTagTextTools;
                
                self.editingTools.drawerHeightCon.constant = self.originalDrawerHeight;
                [self.view layoutIfNeeded];
                
                [self.editingTools.collectionView reloadData];
                self.editingTools.collectionView.tag = kOLEditTagTextTools;
                [self showDrawerWithCompletionHandler:NULL];
            }];
        }
        else{
            self.editingTools.collectionView.tag = kOLEditTagTextTools;
            
            self.editingTools.drawerHeightCon.constant = self.originalDrawerHeight;
            [self.view layoutIfNeeded];
            
            [self.editingTools.collectionView reloadData];
            [self showDrawerWithCompletionHandler:NULL];
        }
    }
    else if (self.editingTools.collectionView.tag == kOLEditTagTextTools){
        [self dismissDrawerWithCompletionHandler:NULL];
    }
     _activeTextField = activeTextField;
}

- (void)onTapGestureRecognized:(id)sender{
    [self.borderTextField resignFirstResponder];
    
    for (OLPhotoTextField *textField in self.textFields){
        if ([textField isFirstResponder]){
            [textField resignFirstResponder];
            return;
        }
    }
    
    [self deselectSelectedTextField];
    
    if (self.editingTools.collectionView.tag != kOLEditTagCrop){
        [self dismissDrawerWithCompletionHandler:NULL];
    }
}

- (void)setButtonsHidden:(BOOL)hidden forTextField:(OLPhotoTextField *)tf{
    CGRect frame = tf.frame;
    if (hidden){
        [self addTextFieldToView:self.artboard existing:tf];
        tf.frame = frame;
        [tf hideButtons];
        self.textFieldsView.userInteractionEnabled = NO;
    }
    else{
        [self addTextFieldToView:self.textFieldsView existing:tf];
        tf.frame = frame;
        [tf showButtons];
        self.textFieldsView.userInteractionEnabled = YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupContainerView];
    [self setupEditingToolsView];
    
    if (!self.navigationController){
        UIButton *button = [[UIButton alloc] init];
        self.closeButton = button;
        [button addTarget:self action:@selector(onBarButtonCancelTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button setImage:[UIImage imageNamedInKiteBundle:@"x-button"] forState:UIControlStateNormal];
        button.tintColor = [UIColor whiteColor];
        [self.allViews addObject:button];
        
        [self.view addSubview:button];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeadingMargin multiplier:1 constant:0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:10]];
        
    }
    self.availableColors = @[[UIColor blackColor], [UIColor whiteColor], [UIColor darkGrayColor], [UIColor colorWithRed:0.890 green:0.863 blue:0.761 alpha:1.000], [UIColor colorWithRed:0.765 green:0.678 blue:0.588 alpha:1.000], [UIColor colorWithRed:0.624 green:0.620 blue:0.612 alpha:1.000], [UIColor colorWithRed:0.976 green:0.910 blue:0.933 alpha:1.000], [UIColor colorWithRed:0.604 green:0.522 blue:0.741 alpha:1.000], [UIColor colorWithRed:0.996 green:0.522 blue:0.886 alpha:1.000], [UIColor colorWithRed:0.392 green:0.271 blue:0.576 alpha:1.000], [UIColor colorWithRed:0.906 green:0.573 blue:0.565 alpha:1.000], [UIColor colorWithRed:0.984 green:0.275 blue:0.404 alpha:1.000], [UIColor colorWithRed:0.918 green:0.000 blue:0.200 alpha:1.000], [UIColor colorWithRed:0.776 green:0.176 blue:0.157 alpha:1.000], [UIColor colorWithRed:0.965 green:0.831 blue:0.239 alpha:1.000], [UIColor colorWithRed:0.961 green:0.682 blue:0.118 alpha:1.000], [UIColor colorWithRed:0.945 green:0.482 blue:0.204 alpha:1.000], [UIColor colorWithRed:0.827 green:0.859 blue:0.898 alpha:1.000], [UIColor colorWithRed:0.616 green:0.710 blue:0.851 alpha:1.000], [UIColor colorWithRed:0.400 green:0.541 blue:0.784 alpha:1.000], [UIColor colorWithRed:0.400 green:0.541 blue:0.784 alpha:1.000], [UIColor colorWithRed:0.173 green:0.365 blue:0.725 alpha:1.000], [UIColor colorWithRed:0.102 green:0.247 blue:0.361 alpha:1.000], [UIColor colorWithRed:0.765 green:0.933 blue:0.898 alpha:1.000], [UIColor colorWithRed:0.506 green:0.788 blue:0.643 alpha:1.000], [UIColor colorWithRed:0.345 green:0.502 blue:0.400 alpha:1.000], [UIColor colorWithRed:0.337 green:0.427 blue:0.208 alpha:1.000]];
    
    [self registerCollectionViewCells];
    self.editingTools.collectionView.dataSource = self;
    self.editingTools.collectionView.delegate = self;
    [self.editingTools.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Done", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    if ([OLUserSession currentSession].capitalizeCtaTitles){
        [self.editingTools.ctaButton setTitle:[[self.editingTools.ctaButton titleForState:UIControlStateNormal] uppercaseString] forState:UIControlStateNormal];
    }
    
    [self setupCropGuides];
    
    self.textFieldsView = [[OLTouchTolerantView alloc] init];
    self.textFieldsView.userInteractionEnabled = NO;
    [self.printContainerView insertSubview:self.textFieldsView aboveSubview:self.artboard];
    self.textFieldsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.textFieldsView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.textFieldsView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.textFieldsView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.textFieldsView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [self.textFieldsView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.textFieldsView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    [self.textFieldsView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.textFieldsView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    
    self.originalDrawerHeight = self.editingTools.drawerHeightCon.constant;
    
    if (self.previewView && !self.skipPresentAnimation){
        self.view.backgroundColor = [UIColor clearColor];
        self.previewView.alpha = 0.15;
        [self.view addSubview:self.previewView];
        [self.view sendSubviewToBack:self.previewView];
        for (UIView *view in self.allViews){
            view.alpha = 0;
        }
    }
    
    self.initialOrientation = self.fullImage.imageOrientation;
    self.artboard.assetViews.firstObject.delegate = self;
    
    if (self.forceSourceViewDimensions && self.previewSourceView){
        UIView *view = self.artboard;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[[NSString stringWithFormat:@"H:[view(%f)]", self.previewSourceView.frame.size.width]];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];

    }
    
    if (self.centerYConConstant){
        self.centerYCon.constant = [self.centerYConConstant integerValue];
    }
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] init];
    [tapGesture addTarget:self action:@selector(onTapGestureRecognized:)];
    [self.view addGestureRecognizer:tapGesture];
    
    NSArray *copy = [[NSArray alloc] initWithArray:self.edits.textsOnPhoto copyItems:NO];
    for (OLTextOnPhoto *textOnPhoto in copy){
        UITextField *textField = [self addTextFieldToView:self.artboard existing:nil];
        textField.text = textOnPhoto.text;
        textField.transform = textOnPhoto.transform;
        textField.textColor = textOnPhoto.color;
        textField.font = [OLKiteUtils fontWithName:textOnPhoto.fontName size:textOnPhoto.fontSize];
        [self.edits.textsOnPhoto removeObject:textOnPhoto];
    }
    
    [self registerForKeyboardNotifications];
    
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    
    self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    UIView *view = self.visualEffectView;
    
    [self.editingTools.drawerView addSubview:view];
    [self.editingTools.drawerView sendSubviewToBack:view];
    
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    [self.view insertSubview:self.editingTools.drawerView belowSubview:self.editingTools];
    
    [self.editingTools.drawerView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.editingTools.drawerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.editingTools.drawerView.superview attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self.editingTools.drawerView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.editingTools.drawerView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.editingTools.drawerView.superview attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self.editingTools.drawerView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.editingTools.drawerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.editingTools.drawerView.superview attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    self.editingTools.drawerView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    
    [self setupButtons];
    
    self.ctaButton = self.editingTools.ctaButton;
    self.ctaButton.enabled = NO;
    self.ctaButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.ctaButton.titleLabel.minimumScaleFactor = 0.5;
    
    self.artboard.clipsToBounds = YES;
    [self orderViews];
    
    self.printContainerView.backgroundColor = [self containerBackgroundColor];
    
    [self.artboard removeConstraint:self.aspectRatioConstraint];
    self.aspectRatioConstraint = [NSLayoutConstraint constraintWithItem:self.artboard attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeWidth multiplier:self.aspectRatio constant:0];
    [self.artboard addConstraints:@[self.aspectRatioConstraint]];
    
    [self setupProductRepresentation];
    
    UIView *gestureView = [[UIView alloc] init];
    self.gestureView = gestureView;
    [self.view addSubview:gestureView];
    gestureView.translatesAutoresizingMaskIntoConstraints = NO;
    views = NSDictionaryOfVariableBindings(gestureView);
    con = [[NSMutableArray alloc] init];
    
    visuals = @[@"H:|-0-[gestureView]-0-|",
                         @"V:|-64-[gestureView]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [gestureView.superview addConstraints:con];
    
    [gestureView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self.artboard.assetViews.firstObject action:@selector(panRecognized:)]];
    [gestureView addGestureRecognizer:[[UIPinchGestureRecognizer alloc] initWithTarget:self.artboard.assetViews.firstObject action:@selector(pinchRecognized:)]];
    gestureView.userInteractionEnabled = NO;
}

- (void)setImage:(UIImage *)image{
    self.fullImage = image;
    self.thumbnailOriginalImage = [image shrinkToSize:CGSizeMake(200, 200) forScreenScale:[OLUserSession currentSession].screenScale];
}

- (CGFloat)containerViewMargin{
    return 20;
}

- (void)setupContainerView{
    self.printContainerView = [[UIView alloc] init];
    [self.view addSubview:self.printContainerView];
    
    [self.printContainerView trailingToSuperview:[self containerViewMargin] relation:NSLayoutRelationGreaterThanOrEqual];
    [self.printContainerView leadingFromSuperview:[self containerViewMargin] relation:NSLayoutRelationGreaterThanOrEqual];
    
    [self.printContainerView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.printContainerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.printContainerView.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.printContainerView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.printContainerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:[self containerViewMargin]]];
    
    NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.printContainerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.printContainerView.superview attribute:NSLayoutAttributeLeading multiplier:1 constant:[self containerViewMargin]];
    con.priority = 750;
    [self.printContainerView.superview addConstraint:con];
    
    con = [NSLayoutConstraint constraintWithItem:self.printContainerView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.printContainerView.superview attribute:NSLayoutAttributeTrailing multiplier:1 constant:[self containerViewMargin]];
    con.priority = 750;
    [self.printContainerView.superview addConstraint:con];
    
    con = [NSLayoutConstraint constraintWithItem:self.printContainerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.printContainerView.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    con.priority = 750;
    [self.printContainerView.superview addConstraint:con];
    
    if ([self productBackgroundURL]){
        self.deviceView = [[UIImageView alloc] init];
        self.deviceView.contentMode = UIViewContentModeScaleToFill;
        [self.printContainerView addSubview:self.deviceView];
        [self.deviceView fillSuperView];
    }
    
    self.artboard = [[OLArtboardView alloc] init];
    [self.printContainerView addSubview:self.artboard];
    NSArray *cons = [self.artboard fillSuperView];
    self.artboardTopCon = cons[0];
    self.artboardLeftCon = cons[1];
    self.artboardBottomCon = cons[2];
    self.artboardRightCon= cons[3];
    
    self.artboard.userInteractionEnabled = YES;
    [self.artboard.assetViews.firstObject setGesturesEnabled:YES];
    
    self.aspectRatioConstraint = [NSLayoutConstraint constraintWithItem:self.artboard attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeWidth multiplier:self.aspectRatio constant:0];
    [self.artboard addConstraint:self.aspectRatioConstraint];
    
    if ([self productHighlightsURL]){
        self.highlightsView = [[UIImageView alloc] init];
        self.highlightsView.contentMode = UIViewContentModeScaleToFill;
        [self.printContainerView addSubview:self.highlightsView];
        [self.highlightsView fillSuperView];
    }
    
    [self.allViews addObject:self.printContainerView];
}

- (void)setupTextEditingEndArtboardTapGesture {
    [self.artboard.assetViews.firstObject addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureRecognized:)]];
}

- (void)setupEditingToolsView{
    self.editingTools = [[OLEditingToolsView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.editingTools];
    [self.allViews addObject:self.editingTools];
    
    [self.editingTools leadingFromSuperview:0 relation:NSLayoutRelationEqual];
    [self.editingTools trailingToSuperview:0 relation:NSLayoutRelationEqual];
    [self.editingTools heightConstraint:45];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.editingTools attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    
    [self.printContainerView verticalSpacingToView:self.editingTools constant:20 relation:NSLayoutRelationGreaterThanOrEqual];
    
    self.editingTools.backgroundColor = [UIColor colorWithHexString:@"E7EBEF"];
    
    [self setupTextEditingEndArtboardTapGesture];
    
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        self.safeAreaView = [[UIView alloc] init];
        
        UIView *bottomSeparatorView = [[UIView alloc] init];
        bottomSeparatorView.backgroundColor = self.editingTools.backgroundColor;
        [self.safeAreaView addSubview:bottomSeparatorView];
        [bottomSeparatorView leadingFromSuperview:0 relation:0];
        [bottomSeparatorView topFromSuperview:0 relation:0];
        [bottomSeparatorView trailingToSuperview:0 relation:NSLayoutRelationEqual];
        [bottomSeparatorView heightConstraint:1];
        
        self.safeAreaView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.safeAreaView];
        [self.allViews addObject:self.safeAreaView];
        
        [self.safeAreaView leadingFromSuperview:0 relation:NSLayoutRelationEqual];
        [self.safeAreaView trailingToSuperview:0 relation:NSLayoutRelationEqual];
        [self.safeAreaView bottomToSuperview:0 relation:NSLayoutRelationEqual];
        
        NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.safeAreaView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.editingTools attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        [self.view addConstraint:con];
    }
#endif
}

- (void)applyProductImageLayers{
    if (!self.deviceView.image && [self productBackgroundURL]){
        self.deviceView.alpha = 0;
        [[OLImageDownloader sharedInstance] downloadImageAtURL:[self productBackgroundURL] priority:1.0 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.deviceView.image = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
                [UIView animateWithDuration:0.1 animations:^{
                    self.deviceView.alpha = 1;
                } completion:^(BOOL finished){
                    [self updateProductRepresentationForChoice:nil];
                }];
            });
        }];
    }
    if (!self.highlightsView.image && [self productHighlightsURL]){
        self.highlightsView.alpha = 0;
        [[OLImageDownloader sharedInstance] downloadImageAtURL:[self productHighlightsURL] priority:0.9 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.highlightsView.image = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
                [UIView animateWithDuration:0.1 animations:^{
                    self.highlightsView.alpha = 1;
                }];
            });
        }];
    }
}

- (NSURL *)productBackgroundURL{
    return self.product.productTemplate.productBackgroundImageURL;
}

- (NSURL *)productHighlightsURL{
    return self.product.productTemplate.productHighlightsImageURL;
}

- (void)setupProductRepresentation{
    //To be used in subclasses
}

- (void)disableOverlay{
    //To be used in subclasses
}

- (void)setupCropGuides{
    UIColor *cropGuidesColor = [UIColor colorWithWhite:0.227 alpha:0.750];
    
    self.cropFrameGuideViews = [[NSMutableArray alloc] init];
    
    UIImageView *cornerTL = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"crop-corner-ul"]];
    [cornerTL setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [cornerTL setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.cropFrameGuideViews addObject:cornerTL];
    [self.printContainerView addSubview:cornerTL];
    [self.printContainerView sendSubviewToBack:cornerTL];
    cornerTL.translatesAutoresizingMaskIntoConstraints = NO;
    [cornerTL.superview addConstraint:[NSLayoutConstraint constraintWithItem:cornerTL attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeTop multiplier:1 constant:-2]];
    [cornerTL.superview addConstraint:[NSLayoutConstraint constraintWithItem:cornerTL attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeLeading multiplier:1 constant:-2]];

    UIImageView *cornerTR = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"crop-corner-ur"]];
    [cornerTR setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [cornerTR setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.cropFrameGuideViews addObject:cornerTR];
    [self.printContainerView addSubview:cornerTR];
    [self.printContainerView sendSubviewToBack:cornerTR];
    cornerTR.translatesAutoresizingMaskIntoConstraints = NO;
    [cornerTR.superview addConstraint:[NSLayoutConstraint constraintWithItem:cornerTR attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeTop multiplier:1 constant:-2]];
    [cornerTR.superview addConstraint:[NSLayoutConstraint constraintWithItem:cornerTR attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeTrailing multiplier:1 constant:2]];
    
    UIImageView *cornerBR = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"crop-corner-dr"]];
    [cornerBR setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [cornerBR setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.cropFrameGuideViews addObject:cornerBR];
    [self.printContainerView addSubview:cornerBR];
    [self.printContainerView sendSubviewToBack:cornerBR];
    cornerBR.translatesAutoresizingMaskIntoConstraints = NO;
    [cornerBR.superview addConstraint:[NSLayoutConstraint constraintWithItem:cornerBR attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeBottom multiplier:1 constant:2]];
    [cornerBR.superview addConstraint:[NSLayoutConstraint constraintWithItem:cornerBR attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeTrailing multiplier:1 constant:2]];
    
    UIImageView *cornerBL = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"crop-corner-dl"]];
    [cornerBL setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [cornerBL setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.cropFrameGuideViews addObject:cornerBL];
    [self.printContainerView addSubview:cornerBL];
    [self.printContainerView sendSubviewToBack:cornerBL];
    cornerBL.translatesAutoresizingMaskIntoConstraints = NO;
    [cornerBL.superview addConstraint:[NSLayoutConstraint constraintWithItem:cornerBL attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeBottom multiplier:1 constant:2]];
    [cornerBL.superview addConstraint:[NSLayoutConstraint constraintWithItem:cornerBL attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeLeading multiplier:1 constant:-2]];
    
     UIImageView *lineLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"crop-line-left"]];
    [self.cropFrameGuideViews addObject:lineLeft];
    [self.printContainerView addSubview:lineLeft];
    [self.printContainerView sendSubviewToBack:lineLeft];
    lineLeft.translatesAutoresizingMaskIntoConstraints = NO;
    [lineLeft.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineLeft attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:5]];
    [lineLeft.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineLeft attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeLeading multiplier:1 constant:-2]];
    [lineLeft.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineLeft attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cornerBL attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [lineLeft.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineLeft attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cornerTL attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    
    UIImageView *lineRight = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"crop-line-right"]];
    [self.cropFrameGuideViews addObject:lineRight];
    [self.printContainerView addSubview:lineRight];
    [self.printContainerView sendSubviewToBack:lineRight];
    lineRight.translatesAutoresizingMaskIntoConstraints = NO;
    [lineRight.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineRight attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:5]];
    [lineRight.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineRight attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeTrailing multiplier:1 constant:2]];
    [lineRight.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineRight attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cornerBR attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [lineRight.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineRight attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cornerTR attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];

    UIImageView *lineTop = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"crop-line-up"]];
    [self.cropFrameGuideViews addObject:lineTop];
    [self.printContainerView addSubview:lineTop];
    [self.printContainerView sendSubviewToBack:lineTop];
    lineTop.translatesAutoresizingMaskIntoConstraints = NO;
    [lineTop.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineTop attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:5]];
    [lineTop.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineTop attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeTop multiplier:1 constant:-2]];
    [lineTop.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineTop attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:cornerTL attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [lineTop.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineTop attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:cornerTR attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    
    UIImageView *lineBottom = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"crop-line-down"]];
    [self.cropFrameGuideViews addObject:lineBottom];
    [self.printContainerView addSubview:lineBottom];
    [self.printContainerView sendSubviewToBack:lineBottom];
    lineBottom.translatesAutoresizingMaskIntoConstraints = NO;
    [lineBottom.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineBottom attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:5]];
    [lineBottom.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineBottom attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeBottom multiplier:1 constant:2]];
    [lineBottom.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineBottom attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:cornerBL attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [lineBottom.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineBottom attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:cornerBR attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    
    UIView *darkViewTop = [[UIView alloc] init];
    darkViewTop.translatesAutoresizingMaskIntoConstraints = NO;
    darkViewTop.backgroundColor = cropGuidesColor;
    [self.view addSubview:darkViewTop];
    [self.view sendSubviewToBack:darkViewTop];
    [self.cropFrameGuideViews addObject:darkViewTop];
    [darkViewTop.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewTop attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [darkViewTop.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewTop attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:darkViewTop.superview attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [darkViewTop.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewTop attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:darkViewTop.superview attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [darkViewTop.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewTop attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    darkViewTop.userInteractionEnabled = NO;
    
    UIView *darkViewLeft = [[UIView alloc] init];
    darkViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
    darkViewLeft.backgroundColor = cropGuidesColor;
    [self.view addSubview:darkViewLeft];
    [self.view sendSubviewToBack:darkViewLeft];
    [self.cropFrameGuideViews addObject:darkViewLeft];
    [darkViewLeft.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewLeft attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:darkViewTop attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [darkViewLeft.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewLeft attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:darkViewLeft.superview attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [darkViewLeft.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewLeft attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:darkViewLeft.superview attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [darkViewLeft.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewLeft attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    darkViewLeft.userInteractionEnabled = NO;

    UIView *darkViewRight = [[UIView alloc] init];
    darkViewRight.translatesAutoresizingMaskIntoConstraints = NO;
    darkViewRight.backgroundColor = cropGuidesColor;
    [self.view addSubview:darkViewRight];
    [self.view sendSubviewToBack:darkViewRight];
    [self.cropFrameGuideViews addObject:darkViewRight];
    [darkViewRight.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewRight attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:darkViewTop attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [darkViewRight.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewRight attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:darkViewRight.superview attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [darkViewRight.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewRight attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:darkViewRight.superview attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [darkViewRight.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewRight attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    darkViewRight.userInteractionEnabled = NO;

    UIView *darkViewBottom = [[UIView alloc] init];
    darkViewBottom.translatesAutoresizingMaskIntoConstraints = NO;
    darkViewBottom.backgroundColor = cropGuidesColor;
    [self.view addSubview:darkViewBottom];
    [self.view sendSubviewToBack:darkViewBottom];
    [self.cropFrameGuideViews addObject:darkViewBottom];
    [darkViewBottom.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewBottom attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [darkViewBottom.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewBottom attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:darkViewLeft attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [darkViewBottom.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewBottom attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:darkViewRight attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [darkViewBottom.superview addConstraint:[NSLayoutConstraint constraintWithItem:darkViewBottom attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    darkViewBottom.userInteractionEnabled = NO;
    
    for (UIView *view in self.cropFrameGuideViews){
        view.alpha = 0;
    }
    
}

- (void)orderViews{
    [self.view bringSubviewToFront:self.printContainerView];
    [self.view bringSubviewToFront:self.artboard];
    [self.view bringSubviewToFront:self.textFieldsView];
    [self.view bringSubviewToFront:self.previewView];
    [self.view bringSubviewToFront:self.editingTools.drawerView];
    if (self.safeAreaView){
        [self.view bringSubviewToFront:self.safeAreaView];
    }
    [self.view bringSubviewToFront:self.editingTools];
    [self.view bringSubviewToFront:self.gestureView];
    [self.view bringSubviewToFront:self.closeButton];
    [self.view bringSubviewToFront:self.touchReporter];
}

- (UIColor *)containerBackgroundColor{
    return self.edits.borderColor ? self.edits.borderColor : [UIColor whiteColor];
}

- (BOOL)hasEditableBorder{
    return !UIEdgeInsetsEqualToEdgeInsets(self.borderInsets, UIEdgeInsetsZero);
}

- (BOOL)cropIsInImageEditingTools{
    return NO;
}

- (UIEdgeInsets)imageInsetsOnContainer{
    UIEdgeInsets b = self.borderInsets;
    
    CGFloat width = 0;
    CGFloat height = 0;
    if (self.view.frame.size.height > self.view.frame.size.width){
        width = self.printContainerView.frame.size.width;
        height = (width * (1.0 - b.left - b.right)) * self.aspectRatio;
        height = height / (1 - b.top - b.bottom);
    }
    else{
        height = self.printContainerView.frame.size.height;
        width = (height * (1.0 - b.top - b.bottom)) / self.aspectRatio;
        width = width / (1 - b.left - b.right);

    }
    
    return UIEdgeInsetsMake(b.top * height, b.left * width, b.bottom * height, b.right * width);
}

- (CGFloat)heightForButtons{
    return 64 + self.editingTools.drawerView.frame.size.height;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self setupBottomBorderTextField];
    if (self.edits.bottomBorderText.text){
        self.borderTextField.text = self.edits.bottomBorderText.text;
    }
    
    if (self.previewView && !self.skipPresentAnimation){
        [UIView animateWithDuration:0.10 animations:^{
            self.previewView.alpha = 1;
        } completion:^(BOOL finished){
            self.previewSourceView.hidden = YES;
            [UIView animateWithDuration:0.25 animations:^{
                self.previewView.frame = [self.artboard.superview convertRect:self.artboard.frame toView:self.printContainerView.superview];
            }completion:^(BOOL finished){
                [UIView animateWithDuration:0.25 animations:^{
                    if ([OLKiteABTesting sharedInstance].lightThemeColorImageEditBg){
                        self.view.backgroundColor = [OLKiteABTesting sharedInstance].lightThemeColorImageEditBg;
                    }
                    else{
                        self.view.backgroundColor = [UIColor colorWithWhite:0.227 alpha:1.000];
                    }
                    for (UIView *view in self.allViews){
                        view.alpha = 1;
                    }
                } completion:^(BOOL finished){
                    [self.previewView removeFromSuperview];
                    self.previewSourceView.hidden = NO;
                }];
            }];
        }];
    }
    if (!self.previewView && !self.fullImage){
        [self loadImageFromAsset];
    }
}

- (BOOL)isUsingMultiplyBlend{
    return NO;
}

- (void)loadImages{
    void (^setImageToArtboard)(UIImage *image) = ^(UIImage *image){
        if (self.edits.counterClockwiseRotations > 0 || self.edits.flipHorizontal || self.edits.flipVertical){
            image = [UIImage imageWithCGImage:self.fullImage.CGImage scale:self.fullImage.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.edits.counterClockwiseRotations andInitialOrientation:self.fullImage.imageOrientation horizontalFlip:self.edits.flipHorizontal verticalFlip:self.edits.flipVertical]];
        }
        else{
            image = self.fullImage;
        }
        
        self.artboard.image = image;
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        
        CGFloat factor = 1;
        if (self.edits.cropImageFrame.size.width != 0) {
            factor = self.artboard.assetViews.firstObject.frame.size.width / self.edits.cropImageFrame.size.width;
        }
        
        self.artboard.assetViews.firstObject.imageView.transform = CGAffineTransformMake(self.edits.cropTransform.a, self.edits.cropTransform.b, self.edits.cropTransform.c, self.edits.cropTransform.d, self.edits.cropTransform.tx * factor, self.edits.cropTransform.ty * factor);
        
        [self updateProductRepresentationForChoice:nil];
        self.animating = NO;
    };
    
    if (self.fullImage && self.edits.filterName && ![self.edits.filterName isEqualToString:@""]){
        OLAsset *asset = [OLAsset assetWithImageAsJPEG:self.fullImage];
        asset.edits.filterName = self.edits.filterName;
        [asset imageWithSize:self.fullImage.size applyEdits:YES progress:NULL completion:^(UIImage *image, NSError *error){
            self.fullImage = image;
            setImageToArtboard(self.fullImage);
        }];
    }
    else{
        setImageToArtboard(self.fullImage);
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.previewView){
        [self.view layoutIfNeeded];
        if (self.fullImage){
            [self loadImages];
        }
        else{
            [self loadImageFromAsset];
        }
    }
    
    [self updateButtonBadges];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    self.artboard.assetViews.firstObject.imageView.image = nil;
    self.edits.cropImageRect = [self.artboard.assetViews.firstObject getImageRect];
    self.edits.cropImageFrame = [self.artboard.assetViews.firstObject getFrameRect];
    self.edits.cropImageSize = [self.artboard.assetViews.firstObject croppedImageSize];
    self.edits.cropTransform = [self.artboard.assetViews.firstObject.imageView transform];
    
    [coordinator animateAlongsideTransition:^(id context){
        [self loadImageFromAsset];
        [self.editingTools.collectionView.collectionViewLayout invalidateLayout];
    }completion:^(id context){
        NSString *borderString = self.borderTextField.text;
        if (borderString){
            [self.borderTextField removeFromSuperview];
            self.borderTextField = nil;
            [self setupBottomBorderTextField];
            self.borderTextField.text = borderString;
        }
    }];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if (self.enableCircleMask){
        CAShapeLayer *aCircle=[CAShapeLayer layer];
        aCircle.path=[UIBezierPath bezierPathWithRoundedRect:self.artboard.bounds cornerRadius:self.artboard.frame.size.height/2].CGPath;
        
        aCircle.fillColor=[UIColor blackColor].CGColor;
        self.artboard.layer.mask=aCircle;
    }
    
    UIEdgeInsets b = [self imageInsetsOnContainer];
    if (self.artboardTopCon.constant != b.top || self.artboardRightCon.constant != b.right || self.artboardBottomCon.constant != b.bottom || self.artboardLeftCon.constant != b.left){
        self.artboardTopCon.constant = b.top;
        self.artboardRightCon.constant = b.right;
        self.artboardBottomCon.constant = b.bottom;
        self.artboardLeftCon.constant = b.left;
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        self.artboard.assetViews.firstObject.imageView.transform = self.edits.cropTransform;
    }
    
    if (!self.product.productTemplate.maskImageURL){
        [self applyProductImageLayers];
    }
}

- (void)setupBottomBorderTextField{
    if (self.product.productTemplate.supportsTextOnBorder && !self.borderTextField){
        CGFloat heightFactor = self.artboard.frame.size.height / 212.0;
        
        UITextField *tf = [[UITextField alloc] init];
        tf.delegate = self;
        tf.autocorrectionType = UITextAutocorrectionTypeNo;
        tf.tintColor = self.editingTools.ctaButton.backgroundColor;
        tf.textAlignment = NSTextAlignmentCenter;
        tf.adjustsFontSizeToFitWidth = YES;
        tf.minimumFontSize = 1;
        tf.placeholder = @"Add Text";
        tf.font = [UIFont fontWithName:@"HelveticaNeue" size:35 * heightFactor];
        tf.textColor = [UIColor blackColor];
        self.borderTextField = tf;
        
        [self.printContainerView addSubview:tf];
        
        UIView *artboard = self.artboard;
        tf.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(tf, artboard);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        UIEdgeInsets insets = [self imageInsetsOnContainer];
        
        NSArray *visuals = @[[NSString stringWithFormat:@"H:|-%f-[tf]-%f-|", insets.left - 5, insets.right - 5],
                             [NSString stringWithFormat:@"V:[artboard]-%f-[tf(%f)]", 8.0 * heightFactor, 40.0 * heightFactor]];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [tf.superview addConstraints:con];
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion{
    if (!self.previewView){
        [super dismissViewControllerAnimated:flag completion:completion];
    }
    else if (!flag){
        [super dismissViewControllerAnimated:NO completion:completion];
    }
    else{
        [self exitCropMode];
        
        self.previewView  = [self.artboard snapshotViewAfterScreenUpdates:YES];
        
        self.previewView.frame = [self.artboard.superview convertRect:self.artboard.frame toView:self.printContainerView.superview];
        [self.view addSubview:self.previewView];
        self.previewSourceView.hidden = YES;
        [UIView animateWithDuration:0.25 animations:^{
            self.view.backgroundColor = [UIColor clearColor];
            for (UIView *view in [self.allViews arrayByAddingObjectsFromArray:@[self.editingTools, self.editingTools.collectionView]]){
                view.alpha = 0;
            }
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.25 animations:^{
                self.previewView.frame = [self.previewSourceView.superview convertRect:self.previewSourceView.frame toView:self.presentingViewController.view];
            }completion:^(BOOL finished){
                self.previewSourceView.hidden = NO;
                [UIView animateWithDuration:0.15 animations:^{
                    self.previewView.alpha = 0;
                } completion:^(BOOL finished){
                    [super dismissViewControllerAnimated:NO completion:completion];
                }];
                
            }];
        }];
    }
}

- (OLPhotoTextField *)addTextFieldToView:(UIView *)view existing:(OLPhotoTextField *)existing{
    OLPhotoTextField *textField;
    if (existing){
        textField = existing;
    }
    else{
        textField = [[OLPhotoTextField alloc] initWithFrame:CGRectMake(0, 0, 130, 70)];
        textField.center = self.artboard.center;
        textField.margins = 10;
        textField.delegate = self;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.photoTextFieldDelegate = self;
        textField.keyboardAppearance = UIKeyboardAppearanceDark;
        [textField addTarget:self
                      action:@selector(textFieldDidChange:)
            forControlEvents:UIControlEventEditingChanged];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] init];
        panGesture.delegate = self;
        [panGesture addTarget:self action:@selector(onTextfieldGesturePanRecognized:)];
        [textField addGestureRecognizer:panGesture];
        
        [self.textFields addObject:textField];
    }
    
    [view addSubview:textField];
    [textField.superview addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:textField.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [textField.superview addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:textField.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(textField);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:[textField(>=100)]",
                         @"V:[textField(>=40)]"];
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [textField.superview addConstraints:con];
    
    return textField;
}

- (CGFloat)angleOfTouchPoint:(CGPoint)p fromPoint:(CGPoint)c{
    CGFloat x = p.x - c.x;
    CGFloat y = p.y - c.y;

    if (y == 0){
        y = 0.000001; //Avoid division by zero, even though it produces the right result
    }
    
    CGFloat angle = atan(x / y);
    if (y >= 0){
        angle = angle + M_PI;
    }
    
    return -angle;
}

- (void)onTextfieldGesturePanRecognized:(UIPanGestureRecognizer *)gesture{
    static CGAffineTransform original;
    static CGFloat originalFontSize;
    static CGRect originalFrame;
    static CGFloat originalAngle;
    
    if (gesture.state == UIGestureRecognizerStateBegan){
        if ([self shouldEnableGestures]){
            [self.artboard.assetViews.firstObject setGesturesEnabled:NO];
        }
        original = gesture.view.transform;
        originalFrame = gesture.view.frame;
        CGPoint gesturePoint = [gesture locationInView:self.artboard];
        CGPoint translatedPoint = CGPointMake(gesturePoint.x - original.tx, gesturePoint.y - original.ty);
        originalAngle = [self angleOfTouchPoint:translatedPoint fromPoint:gesture.view.center];
        
        OLPhotoTextField *textField = (OLPhotoTextField *)gesture.view;
        originalFontSize = textField.font.pointSize;
        
        if (self.activeTextField != textField){
            [self.activeTextField resignFirstResponder];
            if ([self.activeTextField isKindOfClass:[OLPhotoTextField class]]){
                [self setButtonsHidden:YES forTextField:self.activeTextField];
            }
            self.activeTextField = (OLPhotoTextField *)textField;
            if ([self.activeTextField isKindOfClass:[OLPhotoTextField class]]){
                [self setButtonsHidden:NO forTextField:self.activeTextField];
            }
        }
    }
    else if (gesture.state == UIGestureRecognizerStateChanged){
        CGPoint translate = [gesture translationInView:gesture.view.superview];
        CGAffineTransform translation = CGAffineTransformTranslate(CGAffineTransformMakeTranslation(original.tx, original.ty), translate.x, translate.y);
        CGAffineTransform transform = original;
        transform.tx = translation.tx;
        transform.ty = translation.ty;
        
        if (self.resizingTextField){
            CGFloat sizeChange = sqrt(translate.x * translate.x + translate.y * translate.y);
            if (translate.x < 0 && translate.y < 0){
                sizeChange = -sizeChange;
            }
            else if (translate.x < 0){
                sizeChange = translate.y;
            }
            else if (translate.y < 0){
                sizeChange = translate.x;
            }
            OLPhotoTextField *textField = (OLPhotoTextField *)gesture.view;
            CGFloat fontSize = textField.font.pointSize;
            textField.font = [UIFont fontWithName:textField.font.fontName size:MAX(originalFontSize + sizeChange, 30)];
            [textField sizeToFit];
            if (textField.frame.origin.x < 0 || textField.frame.origin.y < 0 || textField.frame.origin.x + textField.frame.size.width > textField.superview.frame.size.width || textField.frame.origin.y + textField.frame.size.height > textField.superview.frame.size.height){
                textField.font = [UIFont fontWithName:textField.font.fontName size:fontSize];
                [textField sizeToFit];
            }
            [textField setNeedsDisplay];
        }
        else if (self.rotatingTextField){
            static CGFloat previousAngle;
            
            CGPoint gesturePoint = [gesture locationInView:self.artboard];
            CGPoint translatedPoint = CGPointMake(gesturePoint.x - original.tx, gesturePoint.y - original.ty);
            CGFloat angle = [self angleOfTouchPoint:translatedPoint fromPoint:gesture.view.center];
            CGFloat deltaAngle = angle - previousAngle;
            angle = deltaAngle + previousAngle;
            previousAngle = angle;
            CGAffineTransform transform = original;
            transform.tx = 0;
            transform.ty = 0;
            transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(original.tx, original.ty), angle + atan2(transform.b, transform.a) - originalAngle);
            
            gesture.view.transform = transform;
        }
        else{
            CGFloat minY = gesture.view.frame.size.height/2.0 - self.artboard.frame.size.height / 2.0;
            CGFloat maxY = -minY;
            CGFloat minX = gesture.view.frame.size.width/2.0 - self.artboard.frame.size.width / 2.0;
            CGFloat maxX = -minX;
            if (transform.ty < minY){
                transform.ty = minY;
            }
            if (transform.ty > maxY){
                transform.ty = maxY;
            }
            if (transform.tx < minX){
                transform.tx = minX;
            }
            if (transform.tx > maxX){
                transform.tx = maxX;
            }
            gesture.view.transform = transform;
        }
    }
    else if (gesture.state == UIGestureRecognizerStateEnded){
        if ([self shouldEnableGestures]){
            [self.artboard.assetViews.firstObject setGesturesEnabled:YES];
        }
        self.resizingTextField = NO;
        self.rotatingTextField = NO;
    }
    
    self.ctaButton.enabled = YES;
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Drawer

- (void)dismissDrawerWithCompletionHandler:(void(^)(BOOL finished))handler{
    if (self.animating){
        return;
    }
    self.animating = YES;
    self.selectedOption = nil;
    self.editingTools.button1.selected = NO;
    self.editingTools.button2.selected = NO;
    self.editingTools.button3.selected = NO;
    self.editingTools.button4.selected = NO;
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.editingTools.drawerView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        [(UICollectionViewFlowLayout *)self.editingTools.collectionView.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        
        self.editingTools.collectionView.tag = -1;
        [self.editingTools.collectionView reloadData];
        [self.view bringSubviewToFront:self.editingTools];
        self.editingTools.drawerHeightCon.constant = self.originalDrawerHeight;
        [self.view layoutIfNeeded];
        self.animating = NO;
        if (handler){
            handler(finished);
        }
    }];
}

- (void)showDrawerWithCompletionHandler:(void(^)(BOOL finished))handler{
    if (self.animating){
        return;
    }
    self.animating = YES;
    if (self.editingTools.collectionView.tag == kOLEditTagTextTools){
        self.editingTools.drawerLabel.text = NSLocalizedStringFromTableInBundle(@"TEXT TOOLS", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    }
    else if (self.editingTools.collectionView.tag == kOLEditTagTextColors){
        self.editingTools.drawerLabel.text = [NSLocalizedStringFromTableInBundle(@"Text Colour", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    else if (self.editingTools.collectionView.tag == kOLEditTagFonts){
        self.editingTools.drawerLabel.text = [NSLocalizedStringFromTableInBundle(@"Fonts", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    else if (self.editingTools.collectionView.tag == kOLEditTagFilters){
        self.editingTools.drawerLabel.text = [NSLocalizedStringFromTableInBundle(@"Filters", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Image filters") uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    else if (self.editingTools.collectionView.tag == kOLEditTagCrop){
        self.editingTools.drawerLabel.text = [NSLocalizedStringFromTableInBundle(@"Crop", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Crop image") uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    
    CGFloat extraHeight = 0;
    
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        extraHeight = self.view.safeAreaInsets.bottom;
    }
#endif

    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.editingTools.drawerView.transform = CGAffineTransformMakeTranslation(0, -self.editingTools.drawerView.frame.size.height - extraHeight);
    } completion:^(BOOL finished){
        self.animating = NO;
        if (handler){
            handler(finished);
        }
    }];
    
    for (UIButton *b in [self.editingTools buttons]){
        if (b.tag / 10 == self.editingTools.collectionView.tag / 10){
            b.selected = YES;
        }
    }
}

#pragma mark Buttons

- (void)setupTheme{
    if ([OLKiteABTesting sharedInstance].lightThemeColorImageEditCta){
        [self.editingTools setColor:[OLKiteABTesting sharedInstance].lightThemeColorImageEditCta];
    }
    else if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        [self.editingTools setColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
    }
    
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:17];
    if (!font){
        font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    }
    if (font){
        [self.editingTools.drawerDoneButton.titleLabel setFont:font];
        [self.editingTools.ctaButton.titleLabel setFont:font];
    }
}

- (void)setupCtaButtons{
    [self.editingTools.ctaButton addTarget:self action:@selector(onButtonDoneTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.editingTools.drawerDoneButton addTarget:self action:@selector(onDrawerButtonDoneClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.editingTools.halfWidthDrawerDoneButton addTarget:self action:@selector(onDrawerButtonDoneClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.editingTools.halfWidthDrawerCancelButton addTarget:self action:@selector(onDrawerButtonCancelClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupButton1{
    if (![OLKiteUtils imageProvidersAvailable]){
        [self.editingTools.button1 removeFromSuperview];
        return;
    }
    [self.editingTools.button1 setImage:[UIImage imageNamedInKiteBundle:@"add-image-icon"] forState:UIControlStateNormal];
    self.editingTools.button1.tag = kOLEditTagImages;
    [self.editingTools.button1 addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupButton2{
    if (self.product.productTemplate.options.count > 0 && ![self isMemberOfClass:[OLImageEditViewController class]]){
        self.editingTools.button2.tag = kOLEditTagProductOptionsTab;
        [self.editingTools.button2 addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.product.productTemplate.options.firstObject iconWithCompletionHandler:^(UIImage *icon){
            [self.editingTools.button2 setImage:icon forState:UIControlStateNormal];
        }];
    }
    else{
        [self.editingTools.button2 removeFromSuperview];
    }
}

- (void)setupButton3{
    if ([OLUserSession currentSession].kiteVc.disableEditingTools){
        [self.editingTools.button3 removeFromSuperview];
    }
    else{
        [self.editingTools.button3 setImage:[UIImage imageNamedInKiteBundle:@"tools-icon"] forState:UIControlStateNormal];
        self.editingTools.button3.tag = kOLEditTagImageTools;
        [self.editingTools.button3 addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupButton4{
    if ([OLUserSession currentSession].kiteVc.disableEditingTools){
        [self.editingTools.button4 removeFromSuperview];
        [self.artboard.assetViews.firstObject setGesturesEnabled:NO];
    }
    else{
        [self.editingTools.button4 setImage:[UIImage imageNamedInKiteBundle:@"crop"] forState:UIControlStateNormal];
        self.editingTools.button4.tag = kOLEditTagCrop;
        [self.editingTools.button4 addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupButtons{
    [self setupTheme];
    [self setupCtaButtons];
    
    [self setupButton1];
    [self setupButton2];
    [self setupButton3];
    [self setupButton4];
}

- (void)saveEditsToAsset:(OLAsset *)asset{
    self.edits.cropImageRect = [self.artboard.assetViews.firstObject getImageRect];
    self.edits.cropImageFrame = [self.artboard.assetViews.firstObject getFrameRect];
    self.edits.cropImageSize = [self.artboard.assetViews.firstObject croppedImageSize];
    self.edits.cropTransform = [self.artboard.assetViews.firstObject.imageView transform];
    
    for (OLPhotoTextField *textField in self.textFields){
        if (!textField.text || [textField.text isEqualToString:@""]){
            continue;
        }
        OLTextOnPhoto *textOnPhoto = [[OLTextOnPhoto alloc] init];
        textOnPhoto.text = textField.text;
        textOnPhoto.frame = textField.frame;
        textOnPhoto.transform = textField.transform;
        textOnPhoto.color = textField.textColor;
        textOnPhoto.fontName = textField.font.fontName;
        textOnPhoto.fontSize = textField.font.pointSize;
        [self.edits.textsOnPhoto addObject:textOnPhoto];
    }
    
    if (self.borderTextField.text){
        self.edits.bottomBorderText = [[OLTextOnPhoto alloc] init];
        self.edits.bottomBorderText.text = self.borderTextField.text;
    }

    if (asset){
        asset.edits = self.edits;
    }
    
}

- (void)onButtonDoneTapped:(UIButton *)sender {
    sender.enabled = NO;
    [self saveEditsToAsset:nil];
    
    if (self.didReplaceAsset && self.asset && [self.delegate respondsToSelector:@selector(imageEditViewController:didReplaceAssetWithAsset:)]){
        self.asset.edits = self.edits;
        [self.asset unloadImage];
        [self.delegate imageEditViewController:self didReplaceAssetWithAsset:self.asset];
    }
    if ([self.delegate respondsToSelector:@selector(imageEditViewController:didFinishCroppingImage:)]){
        [self.delegate imageEditViewController:self didFinishCroppingImage:[self.artboard.assetViews.firstObject editedImage]];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (IBAction)onBarButtonCancelTapped:(id)sender {
    if (self.ctaButton.enabled && self.previewView && [self.delegate respondsToSelector:@selector(imageEditViewControllerDidDropChanges:)]){ //discard changes
        [self exitCropMode];
        self.previewSourceView.hidden = NO;
        
        CGAffineTransform t = [self.artboard.assetViews.firstObject.imageView transform];
        UIEdgeInsets b = [self imageInsetsOnContainer];
        [self.printContainerView addSubview:self.artboard];
        self.artboard.frame = CGRectMake(b.left, b.top, self.printContainerView.frame.size.width - b.left - b.right, self.previewView.frame.size.height - b.top - b.bottom);
        self.artboard.assetViews.firstObject.imageView.transform = t;
        self.previewView  = [self.printContainerView snapshotViewAfterScreenUpdates:YES];
        
        self.previewView.frame = self.printContainerView.frame;
        [self.view addSubview:self.previewView];
        [UIView animateWithDuration:0.25 animations:^{
            self.view.backgroundColor = [UIColor clearColor];
            for (UIView *view in self.allViews){
                view.alpha = 0;
            }
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.7 animations:^{
                self.previewView.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(0, self.view.frame.size.height * 1.2), -M_PI_4);
            }completion:^(BOOL finished){
                if ([self.delegate respondsToSelector:@selector(imageEditViewControllerDidDropChanges:)]){
                    [self.delegate imageEditViewControllerDidDropChanges:self];
                }
                else{
                    [self dismissViewControllerAnimated:NO completion:NULL];
                }
            }];
        }];
    }
    else if ([self.delegate respondsToSelector:@selector(imageEditViewControllerDidCancel:)]){
        [self.delegate imageEditViewControllerDidCancel:self];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)selectButton:(UIButton *)sender{
    self.editingTools.collectionView.tag = sender.tag;
    
    switch (sender.tag) {
        case kOLEditTagImageTools:
            self.editingTools.drawerLabel.text = NSLocalizedStringFromTableInBundle(@"IMAGE TOOLS", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
            break;
        case kOLEditTagImages:
            [self showImagePicker];
            return;
        case kOLEditTagProductOptionsTab:
            if (self.product.productTemplate.options.count == 1 || self.product.productTemplate.templateUI == OLTemplateUIApparel){
                if (self.product.productTemplate.templateUI == OLTemplateUIApparel && sender == self.editingTools.button4){
                    self.selectedOption = self.product.productTemplate.options[1];
                }
                else{
                    self.selectedOption = self.product.productTemplate.options.firstObject;
                }
                if (self.selectedChoice.color){
                    self.editingTools.drawerLabel.text = [[self.selectedOption.name stringByAppendingString:[NSString stringWithFormat:@" - %@", self.selectedChoice.name]] uppercaseString];
                }
                else{
                    self.editingTools.drawerLabel.text = [self.selectedOption.name uppercaseString];
                }
                self.editingTools.collectionView.tag = self.selectedOption.type;
            }
            else{
                self.editingTools.drawerLabel.text = NSLocalizedStringFromTableInBundle(@"PRODUCT OPTIONS", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
            }

            break;
        case kOLEditTagCrop:
            [self onButtonCropClicked:sender];
            return;
            
        default:
            break;
    }
    
    sender.selected = YES;
    [self.editingTools.collectionView reloadData];
    
    [self showDrawerWithCompletionHandler:NULL];
}

- (void)deselectButton:(UIButton *)sender withCompletionHandler:(void (^)(void))handler{
    sender.selected = NO;
    [self dismissDrawerWithCompletionHandler:^(BOOL finished){
        if (handler){
            handler();
        }
    }];
}

- (void)deselectSelectedButtonWithCompletionHandler:(void (^)(void))handler{
    for (UIButton *button in [self.editingTools buttons]){
        if (button.selected){
            if (button.tag == kOLEditTagCrop){
                [self exitCropMode];
            }
            [self deselectButton:button withCompletionHandler:handler];
            break; //We should never have more than one selected button
        }
    }
    
    [self.activeTextField resignFirstResponder];
    if ([self.activeTextField isKindOfClass:[OLPhotoTextField class]]){
        [self setButtonsHidden:YES forTextField:self.activeTextField];
    }
}

- (void)onButtonClicked:(UIButton *)sender {
    if (self.animating){
        return;
    }
    
    void (^buttonAction)(void) = ^void(void){
        [self selectButton:sender];
    };
    
    [self deselectSelectedTextField];
    
    // Nothing is selected: just action
    if (!self.editingTools.button1.selected && !self.editingTools.button2.selected && !self.editingTools.button3.selected && !self.editingTools.button4.selected){
        buttonAction();
    }
    // Sender is selected but we're showing a 2nd or 3rd level drawer: return to 1st level
    else if (sender.selected && self.product.productTemplate.templateUI != OLTemplateUIApparel && (self.editingTools.collectionView.tag == kOLEditTagTextTools || self.editingTools.collectionView.tag == kOLEditTagFonts || self.editingTools.collectionView.tag == kOLEditTagTextColors || self.editingTools.collectionView.tag == kOLEditTagFilters || (self.selectedOption && self.product.productTemplate.options.count != 1))){
        [self deselectSelectedButtonWithCompletionHandler:^(){
            buttonAction();
        }];
    }
    // Sender is selected: just deselect
    else if (sender.selected){
        [self deselectSelectedButtonWithCompletionHandler:NULL];
    }
    // Other is selected: Deselect and action
    else{
        [self deselectSelectedButtonWithCompletionHandler:^{
            buttonAction();
        }];
    }
}

- (void)updateButtonBadges{
    for (OLProductTemplateOption *option in self.product.productTemplate.options){
        if ([option.code isEqualToString:@"garment_size"]){
            for (OLProductTemplateOptionChoice *choice in option.choices){
                if ([choice.code isEqualToString:self.product.selectedOptions[@"garment_size"]]){
                    [self.editingTools.button2 updateBadge:choice.name];
                }
            }
        }
    }
}

#pragma mark Actions

- (IBAction)onButtonHorizontalFlipClicked:(id)sender {
    if (self.artboard.assetViews.firstObject.isCorrecting || self.animating || !self.artboard.assetViews.firstObject.imageView.image){
        return;
    }
    
    [self disableOverlay];
    self.animating = YES;
    [self.activeTextField resignFirstResponder];
    if ([self.activeTextField isKindOfClass:[OLPhotoTextField class]]){
        [self setButtonsHidden:YES forTextField:self.activeTextField];
    }
    self.activeTextField = nil;
    
    [self.edits performHorizontalFlipEditFromOrientation:self.artboard.assetViews.firstObject.imageView.image.imageOrientation];
    
    UIImage *newImage = [UIImage imageWithCGImage:self.fullImage.CGImage scale:self.artboard.assetViews.firstObject.imageView.image.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.edits.counterClockwiseRotations andInitialOrientation:self.initialOrientation horizontalFlip:self.edits.flipHorizontal verticalFlip:self.edits.flipVertical]];
    
        [UIView transitionWithView:self.artboard.assetViews.firstObject.imageView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
            [self.artboard setImage:newImage];
        }completion:^(BOOL finished){
            self.animating = NO;
            
            [self updateProductRepresentationForChoice:nil];
        }];
    
    self.ctaButton.enabled = YES;
}

- (void)onButtonRotateClicked:(id)sender {
    if (self.artboard.assetViews.firstObject.isCorrecting || self.animating || !self.artboard.assetViews.firstObject.imageView.image){
        return;
    }
    
    [self disableOverlay];
    
    self.animating = YES;
    [self.activeTextField resignFirstResponder];
    if ([self.activeTextField isKindOfClass:[OLPhotoTextField class]]){
        [self setButtonsHidden:YES forTextField:self.activeTextField];
    }
    self.activeTextField = nil;
    
    [(UIBarButtonItem *)sender setEnabled:NO];
    self.edits.counterClockwiseRotations = (self.edits.counterClockwiseRotations + 1) % 4;
    
    UIImage *newImage = [UIImage imageWithCGImage:self.fullImage.CGImage scale:self.artboard.assetViews.firstObject.imageView.image.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.edits.counterClockwiseRotations andInitialOrientation:self.initialOrientation horizontalFlip:self.edits.flipHorizontal verticalFlip:self.edits.flipVertical]];
    
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.artboard.assetViews.firstObject.imageView.transform = CGAffineTransformMakeRotation(-M_PI_2);
            
        } completion:^(BOOL finished){
            [self.artboard setImage:newImage];
            self.artboard.assetViews.firstObject.imageView.transform = CGAffineTransformIdentity;
            
            [(UIBarButtonItem *)sender setEnabled:YES];
            self.ctaButton.enabled = YES;
            
            self.animating = NO;
            
            [self updateProductRepresentationForChoice:nil];
        }];
}

- (void)onButtonAddTextClicked:(UIButton *)sender {
    OLPhotoTextField *textField = [self addTextFieldToView:self.textFieldsView existing:nil];
    [self.view layoutIfNeeded];
    [textField becomeFirstResponder]; //Take focus away from any existing active TF
    [textField becomeFirstResponder]; //Become first responder
    
    self.activeTextField = textField;
    
    self.ctaButton.enabled = YES;
}

- (void)deselectSelectedTextField{
    if ([self.activeTextField isKindOfClass:[OLPhotoTextField class]]){
        [self setButtonsHidden:YES forTextField:self.activeTextField];
    }
    
    _activeTextField = nil;
}

- (void)onButtonCropClicked:(UIButton *)sender{
    self.backupTransform = self.artboard.assetViews.firstObject.imageView.transform;
    self.editingTools.drawerDoneButton.hidden = YES;
    self.editingTools.halfWidthDrawerDoneButton.hidden = NO;
    self.editingTools.halfWidthDrawerCancelButton.hidden = NO;
    
    [self deselectSelectedTextField];
    
    for (UIView *view in self.cropFrameGuideViews){
        [self.printContainerView bringSubviewToFront:view];
    }
    sender.selected = YES;
    self.gestureView.userInteractionEnabled = YES;
    [UIView animateWithDuration:0.2 animations:^{
        for (UIView *textField in self.textFields){
            textField.alpha = 0;
        }
        for (UIView *view in self.cropFrameGuideViews){
            view.alpha = 1;
            [view.superview bringSubviewToFront:view];
        }
        [self.view bringSubviewToFront:self.editingTools];
        [self.view bringSubviewToFront:self.safeAreaView];
        
        [self.view bringSubviewToFront:self.editingTools.drawerView];
        self.editingTools.collectionView.tag = kOLEditTagCrop;
        
        self.editingTools.drawerHeightCon.constant = 80;
        [self.view layoutIfNeeded];
        [(UICollectionViewFlowLayout *)self.editingTools.collectionView.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        
        [self.editingTools.collectionView reloadData];
        [self showDrawerWithCompletionHandler:NULL];
    } completion:^(BOOL finished){
        self.artboard.clipsToBounds = NO;
        [self.view sendSubviewToBack:self.artboard];
    }];
}

- (void)onDrawerButtonCancelClicked:(id)sender{
    self.artboard.assetViews.firstObject.imageView.transform = self.backupTransform;

    [self onDrawerButtonDoneClicked:sender];
}

- (void)exitCropMode{
    self.artboard.clipsToBounds = YES;
    [self orderViews];
    for (UIView *view in self.cropFrameGuideViews){
        [self.printContainerView bringSubviewToFront:view];
    }
    self.gestureView.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.2 animations:^{
        for (UIView *textField in self.textFields){
            textField.alpha = 1;
        }
        for (UIView *view in self.cropFrameGuideViews){
            view.alpha = 0;
        }
    } completion:^(BOOL finished){
        self.editingTools.drawerDoneButton.hidden = NO;
        self.editingTools.halfWidthDrawerDoneButton.hidden = YES;
        self.editingTools.halfWidthDrawerCancelButton.hidden = YES;
    }];
}

- (IBAction)onDrawerButtonDoneClicked:(UIButton *)sender {
    if (self.editingTools.collectionView.tag == kOLEditTagTextColors || self.editingTools.collectionView.tag == kOLEditTagFonts){
        [self dismissDrawerWithCompletionHandler:^(BOOL finished){
            self.editingTools.collectionView.tag = kOLEditTagTextTools;
            self.editingTools.drawerHeightCon.constant = self.originalDrawerHeight;
            [self.view layoutIfNeeded];
            [self.editingTools.collectionView reloadData];
            [self showDrawerWithCompletionHandler:NULL];
        }];
    }
    else if (self.editingTools.collectionView.tag == kOLEditTagCrop && [self cropIsInImageEditingTools]){
        [self dismissDrawerWithCompletionHandler:^(BOOL finished){
            [self exitCropMode];
            self.editingTools.collectionView.tag = kOLEditTagImageTools;
            self.editingTools.drawerHeightCon.constant = self.originalDrawerHeight;
            [self.view layoutIfNeeded];
            [self.editingTools.collectionView reloadData];
            [self showDrawerWithCompletionHandler:NULL];
        }];
    }
    else{
        for (UIButton *button in self.editingTools.buttons){
            if (button.selected){
                [button sendActionsForControlEvents:UIControlEventTouchUpInside];
            }
        }
    }
}

#pragma mark CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView.tag == kOLEditTagTextTools){
        return 2;
    }
    else if (collectionView.tag == kOLEditTagProductOptionsTab){
        if (self.product.productTemplate.options.count == 1){
            return self.product.productTemplate.options.firstObject.choices.count;
        }
        else{
            return self.product.productTemplate.options.count;
        }
    }
    else if (collectionView.tag == kOLEditTagTextColors){
        return self.availableColors.count;
    }
    else if (collectionView.tag == kOLEditTagFonts){
        return self.fonts.count;
    }
    else if (collectionView.tag == kOLEditTagImageTools){
        NSInteger numberOfTools = 4;
        if ([OLUserSession currentSession].kiteVc.disableAdvancedEditingTools){
            numberOfTools -= 2; // Remove filters and text on photo
        }
        else if (self.product.productTemplate.templateUI == OLTemplateUIMug){
            numberOfTools--; // Remove text on photo
        }
        
        if ([self cropIsInImageEditingTools]){
            numberOfTools++;
        }
        return numberOfTools;
    }
    else if (collectionView.tag == kOLEditTagFilters){
        return [self filterNames].count;
    }
    else if (collectionView.tag == kOLEditTagCrop){
        return 0;
    }
    else if (collectionView.tag == -1){
        return 0;
    }
    
    return self.selectedOption.choices.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell;
    if (collectionView.tag == kOLEditTagTextTools){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"toolCell" forIndexPath:indexPath];
        [self setupToolCell:cell];
        
        if (indexPath.item == 0){
            [(UIImageView *)[cell viewWithTag:10] setImage:[UIImage imageNamedInKiteBundle:@"Aa"]];
            NSString *text = NSLocalizedStringFromTableInBundle(@"Fonts", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
            [(UILabel *)[cell viewWithTag:20] setText:text];
            if ([text containsString:@" "]){
                [(UILabel *)[cell viewWithTag:20] setNumberOfLines:2];
            } else {
                [(UILabel *)[cell viewWithTag:20] setNumberOfLines:1];
            }
        }
        else if (indexPath.item == 1){
            [(UIImageView *)[cell viewWithTag:10] setImage:[UIImage imageNamedInKiteBundle:@"paint-bucket-icon"]];
            [(UILabel *)[cell viewWithTag:20] setText:NSLocalizedStringFromTableInBundle(@"Text Colour", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
        }
    }
    else if (collectionView.tag == kOLEditTagImageTools){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"toolCell" forIndexPath:indexPath];
        [self setupToolCell:cell];
        
        NSInteger adjustedIndexPathItem = indexPath.item - ([self cropIsInImageEditingTools] ? 1 : 0);
        
        if (indexPath.item == 0 && [self cropIsInImageEditingTools]){
            [(UIImageView *)[cell viewWithTag:10] setImage:[UIImage imageNamedInKiteBundle:@"crop"]];
            [(UILabel *)[cell viewWithTag:20] setText:NSLocalizedStringFromTableInBundle(@"Crop", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Crop image")];
        }
        else if (adjustedIndexPathItem == 0){
            [(UIImageView *)[cell viewWithTag:10] setImage:[UIImage imageNamedInKiteBundle:@"flip"]];
            [(UILabel *)[cell viewWithTag:20] setText:NSLocalizedStringFromTableInBundle(@"Flip", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Horizontally flip image")];
        }
        else if (adjustedIndexPathItem == 1){
            [(UIImageView *)[cell viewWithTag:10] setImage:[UIImage imageNamedInKiteBundle:@"rotate"]];
            [(UILabel *)[cell viewWithTag:20] setText:NSLocalizedStringFromTableInBundle(@"Rotate", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Rotate image by 90 degrees")];
        }
        else if (adjustedIndexPathItem == 2){
            [(UIImageView *)[cell viewWithTag:10] setImage:[UIImage imageNamedInKiteBundle:@"filters"]];
            [(UILabel *)[cell viewWithTag:20] setText:NSLocalizedStringFromTableInBundle(@"Filters", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Image filters")];
        }
        else if (adjustedIndexPathItem == 3){
            [(UIImageView *)[cell viewWithTag:10] setImage:[UIImage imageNamedInKiteBundle:@"Tt"]];
            [(UILabel *)[cell viewWithTag:20] setText:NSLocalizedStringFromTableInBundle(@"Add Text", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Add text on image")];
        }
    }
    else if (collectionView.tag == kOLEditTagTextColors || collectionView.tag == OLProductTemplateOptionTypeColor1 || collectionView.tag == OLProductTemplateOptionTypeColor2 || collectionView.tag == OLProductTemplateOptionTypeColor3){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"colorSelectionCell" forIndexPath:indexPath];
        [cell setSelected:NO];
        
        UIColor *color;
        if (self.selectedOption.choices[indexPath.item].color){
            color = self.selectedOption.choices[indexPath.item].color;
        }
        else{
            color = self.availableColors[indexPath.item];
        }
        for (UITextField *textField in self.textFields){
            if ([textField isFirstResponder]){
                [cell setSelected:[textField.textColor isEqual:color]];
                break;
            }
        }
        
        [(OLColorSelectionCollectionViewCell *)cell setColor:color];
        
        if (collectionView.tag == kOLEditTagTextColors){
            [cell setSelected:[self.activeTextField.textColor isEqual:color]];
        }
        else{
            [cell setSelected:self.selectedOption.choices[indexPath.item] == self.selectedChoice];
        }
        
        [cell setNeedsDisplay];
    }
    else if (collectionView.tag == kOLEditTagProductOptionsTab){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"labelCell" forIndexPath:indexPath];
        [self setupLabelCell:cell];
        
        OLProductTemplateOption *option = self.product.productTemplate.options[indexPath.item];
        [(UILabel *)[cell viewWithTag:10] setText:[option.name uppercaseString]];
        [(UILabel *)[cell viewWithTag:10] setNumberOfLines:1];
    }
    else if (collectionView.tag == OLProductTemplateOptionTypeGeneric || collectionView.tag == OLProductTemplateOptionTypeTemplateCollection){
        OLProductTemplateOptionChoice *choice = self.selectedOption.choices[indexPath.item];
        __block UIImage *fallbackIcon;
        [choice iconWithCompletionHandler:^(UIImage *image){ //Fallback image returns syncronously
            fallbackIcon = image;
        }];
        if (choice.extraCost){
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"labelCell" forIndexPath:indexPath];
            [self setupLabelCell:cell];
            
            [(UILabel *)[cell viewWithTag:10] setNumberOfLines:2];
            [(UILabel *)[cell viewWithTag:10] setText:[NSString stringWithFormat:@"%@\n%@", choice.name, choice.extraCost]];
        }
        else if (choice.iconImageName || choice.iconURL || fallbackIcon){
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"toolCell" forIndexPath:indexPath];
            [self setupToolCell:cell];
            
            [choice iconWithCompletionHandler:^(UIImage *image){
                [(UIImageView *)[cell viewWithTag:10] setImage:image];
            }];
            [(UILabel *)[cell viewWithTag:20] setText:choice.name];
        }
        else{
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"labelCell" forIndexPath:indexPath];
            [self setupLabelCell:cell];
            
            if (self.product.productTemplate.templateUI == OLTemplateUIApparel){
                [(OLButtonCollectionViewCell *)cell setCircleSelectionStyle:YES];
            }
            
            [(UILabel *)[cell viewWithTag:10] setText:choice.name];
        }
        
        if (self.selectedOption.type == OLProductTemplateOptionTypeGeneric || self.selectedOption.type == OLProductTemplateOptionTypeTemplateCollection){
            [(OLButtonCollectionViewCell *)cell setColorForSelection:self.editingTools.ctaButton.backgroundColor];
        }
        [cell setSelected:[self.product.selectedOptions[self.selectedOption.code] isEqualToString:choice.code] || ([choice.code isEqualToString:self.product.templateId] && !self.product.selectedOptions[self.selectedOption.code])];
    }
    else if (collectionView.tag == kOLEditTagFonts){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"fontCell" forIndexPath:indexPath];
        [self setupLabelCell:cell];
        UILabel *label = [cell viewWithTag:10];
        [label makeRoundRectWithRadius:4];
        label.text = self.fonts[indexPath.item];
        label.font = [OLKiteUtils fontWithName:label.text size:17];
        if ([self.activeTextField.font.fontName isEqualToString:label.text]){
            label.backgroundColor = self.editingTools.ctaButton.backgroundColor;
        }
        else{
            label.backgroundColor = [UIColor clearColor];
        }
        label.textColor = [UIColor blackColor];
    }
    else if (collectionView.tag == kOLEditTagFilters){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
        [self setupImageCell:cell];
        UIImageView *imageView = [cell viewWithTag:10];
        OLAsset *asset = [OLAsset assetWithImageAsJPEG:self.thumbnailOriginalImage];
        asset.edits.filterName = [self filterNames][indexPath.item];
        [imageView setAndFadeInImageWithOLAsset:asset size:[self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath] applyEdits:YES placeholder:nil progress:NULL completionHandler:NULL];
    }
    cell.clipsToBounds = NO;
    return cell;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    if(collectionView.tag == kOLEditTagTextColors || collectionView.tag == OLProductTemplateOptionTypeColor1 || collectionView.tag == OLProductTemplateOptionTypeColor2 || collectionView.tag == OLProductTemplateOptionTypeColor3){
        return 25;
    }
    else if (collectionView.tag == kOLEditTagFilters){
        return 2;
    }
    else{
        return 10;
    }
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag == kOLEditTagFonts){
        return 0;
    }
    else if (collectionView.tag == kOLEditTagFilters){
        return 2;
    }
    else if (collectionView.tag == kOLEditTagTextTools || collectionView.tag == kOLEditTagImageTools){
        return 10;
    }
    
    return 25;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == kOLEditTagTextColors || collectionView.tag == OLProductTemplateOptionTypeColor1 || collectionView.tag == OLProductTemplateOptionTypeColor2 || collectionView.tag == OLProductTemplateOptionTypeColor3){
        return CGSizeMake(self.editingTools.collectionView.frame.size.height, self.editingTools.collectionView.frame.size.height);
    }
    else if (collectionView.tag == kOLEditTagFonts){
        return CGSizeMake(collectionView.frame.size.width - 40, 30);
    }
    else if (collectionView.tag == OLProductTemplateOptionTypeGeneric || collectionView.tag == OLProductTemplateOptionTypeTemplateCollection){
        return CGSizeMake(100, self.editingTools.collectionView.frame.size.height);
    }
    else if (collectionView.tag == kOLEditTagProductOptionsTab){
        return CGSizeMake(120, self.editingTools.collectionView.frame.size.height);
    }
    
    return CGSizeMake(self.editingTools.collectionView.frame.size.height * 1.65, self.editingTools.collectionView.frame.size.height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    CGFloat margin = MAX((collectionView.frame.size.width - ([self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]].width * [self collectionView:collectionView numberOfItemsInSection:section] + [self collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section] * ([self collectionView:collectionView numberOfItemsInSection:section]-1)))/2.0, 5);
    return UIEdgeInsetsMake(0, margin, 0, margin);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == kOLEditTagTextTools){
        if (indexPath.item == 0){
            [self dismissDrawerWithCompletionHandler:^(BOOL finished){
                [self.view bringSubviewToFront:self.editingTools.drawerView];
                collectionView.tag = kOLEditTagFonts;
                
                self.editingTools.drawerHeightCon.constant = self.originalDrawerHeight + 150;
                [self.view layoutIfNeeded];
                [(UICollectionViewFlowLayout *)self.editingTools.collectionView.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
                
                [collectionView reloadData];
                [self showDrawerWithCompletionHandler:NULL];
            }];
        }
        else if (indexPath.item == 1){
            [self dismissDrawerWithCompletionHandler:^(BOOL finished){
                [self.view bringSubviewToFront:self.editingTools.drawerView];
                collectionView.tag = kOLEditTagTextColors;
                [(UICollectionViewFlowLayout *)self.editingTools.collectionView.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
                [collectionView reloadData];
                [self showDrawerWithCompletionHandler:NULL];
            }];
        }
        
    }
    else if (collectionView.tag == kOLEditTagImageTools){
        NSInteger adjustedIndexPathItem = indexPath.item - ([self cropIsInImageEditingTools] ? 1 : 0);
        if (indexPath.item == 0 && [self cropIsInImageEditingTools]){
            [self onButtonCropClicked:nil];
        }
        else if (adjustedIndexPathItem == 0){
            [self onButtonHorizontalFlipClicked:nil];
        }
        else if (adjustedIndexPathItem == 1){
            [self onButtonRotateClicked:nil];
        }
        else if (adjustedIndexPathItem == 2){
            if (!self.artboard.assetViews.firstObject.imageView.image){
                return;
            }
            [self dismissDrawerWithCompletionHandler:^(BOOL finished){
                [self.view bringSubviewToFront:self.editingTools.drawerView];
                collectionView.tag = kOLEditTagFilters;
                [(UICollectionViewFlowLayout *)self.editingTools.collectionView.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
                [collectionView reloadData];
                [self showDrawerWithCompletionHandler:NULL];
            }];
        }
        else if (adjustedIndexPathItem == 3){
            [self onButtonAddTextClicked:nil];
        }
    }
    else if ((collectionView.tag == OLProductTemplateOptionTypeColor1 || collectionView.tag == OLProductTemplateOptionTypeColor2 || collectionView.tag == OLProductTemplateOptionTypeColor3) && self.product.productTemplate.templateUI != OLTemplateUIApparel){
        self.printContainerView.backgroundColor = self.availableColors[indexPath.item];
        self.edits.borderColor = self.availableColors[indexPath.item];
        self.ctaButton.enabled = YES;
        [collectionView reloadData];
    }
    else if (collectionView.tag == kOLEditTagTextColors){
        [self.activeTextField setTextColor:self.availableColors[indexPath.item]];
        self.ctaButton.enabled = YES;
        [collectionView reloadData];
    }
    else if (collectionView.tag == kOLEditTagFonts){
        [self.activeTextField setFont:[OLKiteUtils fontWithName:self.fonts[indexPath.item] size:self.activeTextField.font.pointSize]];
        if ([self.activeTextField isKindOfClass:[OLPhotoTextField class]]){
            [self.activeTextField updateSize];
        }
        self.ctaButton.enabled = YES;
        [collectionView reloadData];
    }
    else if (collectionView.tag == kOLEditTagFilters){
        if (self.animating){
            return;
        }
        self.ctaButton.enabled = YES;
        self.edits.filterName = [self filterNames][indexPath.item];
        
        OLAsset *asset = [self.asset copy];
        asset.edits = nil;
        asset.edits.filterName = self.edits.filterName;
        [self loadImageFromAsset];
    }
    else if (self.selectedOption && self.selectedOption.type == OLProductTemplateOptionTypeTemplateCollection){
        NSString *templateId = self.selectedOption.choices[indexPath.item].code;
        
        OLProduct *product = [OLProduct productWithTemplateId:templateId];
        product.uuid = self.product.uuid;
        [product.selectedOptions removeObjectForKey:self.selectedOption.code];
        
        if (self.navigationController.viewControllers.count > 1){
            OLProductOverviewViewController *vc = self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2];
            if ([vc isKindOfClass:[OLProductOverviewViewController class]]){
                vc.product = product;
                [vc setupProductRepresentation];
            }
        }
        
        [self saveEditsToAsset:self.asset];
        
        UIViewController *vc = [[OLUserSession currentSession].kiteVc reviewViewControllerForProduct:product photoSelectionScreen:NO];
        [vc safePerformSelector:@selector(setProduct:) withObject:product];
        NSMutableArray *vcs = [self.navigationController.viewControllers mutableCopy];
        [vcs replaceObjectAtIndex:vcs.count-1 withObject:vc];
        [self.navigationController setViewControllers:vcs];
    }
    else if (self.selectedOption){
        OLProductTemplateOptionChoice *choice = self.selectedOption.choices[indexPath.item];
        self.product.selectedOptions[self.selectedOption.code] = choice.code;
        [self updateProductRepresentationForChoice:choice];
        self.selectedChoice = self.selectedOption.choices[indexPath.item];
        [collectionView reloadData];
        
        if (self.selectedChoice.color){
            self.editingTools.drawerLabel.text = [[self.selectedOption.name stringByAppendingString:[NSString stringWithFormat:@" - %@", self.selectedChoice.name]] uppercaseString];
        }
    }
    else{
        UIButton *selectedButton;
        for (UIButton *button in self.editingTools.buttons){
            if (button.selected){
                selectedButton = button;
                break;
            }
        }
        [self dismissDrawerWithCompletionHandler:^(BOOL finished){
            self.selectedOption = self.product.productTemplate.options[indexPath.item];
            self.editingTools.drawerLabel.text = [self.selectedOption.name uppercaseString];
            self.editingTools.collectionView.tag = self.selectedOption.type;
            selectedButton.selected = YES;
            [self.editingTools bringSubviewToFront:self.editingTools.drawerView];
            [(UICollectionViewFlowLayout *)self.editingTools.collectionView.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
            [collectionView reloadData];
            [self showDrawerWithCompletionHandler:NULL];            
        }];
    }
    
    [self updateButtonBadges];
}

- (void)updateProductRepresentationForChoice:(OLProductTemplateOptionChoice *)choice{
}

- (void)applyFilterToImage:(UIImage *)image withCompletionHandler:(void(^)(UIImage *image))handler{
    OLAsset *asset = [OLAsset assetWithImageAsJPEG:image];
    asset.edits.filterName = self.edits.filterName;
    
    [asset imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:YES progress:NULL completion:^(UIImage *image, NSError *error){
        handler(image);
    }];
}

- (void)registerCollectionViewCells{
    [self.editingTools.collectionView registerClass:[OLButtonCollectionViewCell class] forCellWithReuseIdentifier:@"fontCell"];
    [self.editingTools.collectionView registerClass:[OLButtonCollectionViewCell class] forCellWithReuseIdentifier:@"iconCell"];
    [self.editingTools.collectionView registerClass:[OLButtonCollectionViewCell class] forCellWithReuseIdentifier:@"toolCell"];
    [self.editingTools.collectionView registerClass:[OLButtonCollectionViewCell class] forCellWithReuseIdentifier:@"labelCell"];
    [self.editingTools.collectionView registerClass:[OLButtonCollectionViewCell class] forCellWithReuseIdentifier:@"imageCell"];
    [self.editingTools.collectionView registerClass:[OLColorSelectionCollectionViewCell class] forCellWithReuseIdentifier:@"colorSelectionCell"];
}

- (void)setupLabelCell:(UICollectionViewCell *)cell{
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 2;
    label.tag = 10;
    label.font = [UIFont systemFontOfSize:17];
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.3;
    label.textColor = [UIColor blackColor];
    if ([label respondsToSelector:@selector(setAllowsDefaultTighteningForTruncation:)]){
        label.allowsDefaultTighteningForTruncation = YES;
    }
    
    [cell.contentView addSubview:label];
    
    label.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(label);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-2-[label]-2-|",
                         @"V:|-0-[label]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [label.superview addConstraints:con];
}

- (void)setupToolCell:(UICollectionViewCell *)cell{
    [(OLButtonCollectionViewCell *)cell setExtendedSelectionBox:YES];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeCenter;
    imageView.tag = 10;
    imageView.tintColor = [UIColor blackColor];
    
    UILabel *label = [[UILabel alloc] init];
    label.tag = 20;
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.5;
    label.numberOfLines = 2;
    [label setTextColor:[UIColor blackColor]];
    if ([label respondsToSelector:@selector(setAllowsDefaultTighteningForTruncation:)]){
        label.allowsDefaultTighteningForTruncation = YES;
    }
    
    [cell.contentView addSubview:imageView];
    [cell.contentView addSubview:label];
    
    label.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(label, imageView);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[imageView]-0-|", @"H:|-0-[label]-0-|",
                         @"V:|-0-[imageView(20)]-0-[label]-(-10)-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [label.superview addConstraints:con];
}

- (void)setupImageCell:(UICollectionViewCell *)cell{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.clipsToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.tag = 10;
    imageView.tintColor = [UIColor blackColor];
    
    [cell.contentView addSubview:imageView];
    
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(imageView);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[imageView]-0-|",
                         @"V:|-0-[imageView]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [imageView.superview addConstraints:con];
}

- (void)setupIconCell:(UICollectionViewCell *)cell{
    
}

#pragma mark Keyboard Notifications

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification{
    NSDictionary *info = [aNotification userInfo];
    NSNumber *durationNumber = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curveNumber = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    [UIView animateWithDuration:[durationNumber doubleValue] delay:0 options:[curveNumber unsignedIntegerValue] animations:^{
        [self.view layoutIfNeeded];
        
        if ([self.borderTextField isFirstResponder]){
            self.printContainerView.transform = CGAffineTransformIdentity;
            self.textFieldKeyboardDiff = 0;
        }
        else{
            for (UITextField *textField in self.textFields){
                if ([textField isFirstResponder]){
                    self.printContainerView.transform = CGAffineTransformIdentity;
                    self.textFieldKeyboardDiff = 0;
                    break;
                }
            }
        }
    }completion:NULL];
}

- (void)keyboardWillChangeFrame:(NSNotification*)aNotification{
    NSDictionary *info = [aNotification userInfo];
    CGFloat keyboardHeight = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    NSNumber *durationNumber = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curveNumber = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    if ([self.borderTextField isFirstResponder]){
        CGPoint p = [self.printContainerView convertRect:self.borderTextField.frame toView:nil].origin;
        
        CGFloat diff = p.y + self.borderTextField.frame.size.height - (self.view.frame.size.height - keyboardHeight);
        if (diff > 0) {
            self.printContainerView.transform = CGAffineTransformMakeTranslation(0, -diff);
            self.textFieldKeyboardDiff = diff;
        }
    }
    else{
        for (UITextField *textField in self.textFields){
            if ([textField isFirstResponder]){
                CGPoint p = [self.artboard convertRect:textField.frame toView:nil].origin;
                
                CGFloat diff = p.y + textField.frame.size.height - (self.view.frame.size.height - keyboardHeight);
                if (diff > 0) {
                    self.printContainerView.transform = CGAffineTransformMakeTranslation(0, -diff);
                    self.textFieldKeyboardDiff = diff;
                }
                
                break;
            }
        }
    }
    
    [UIView animateWithDuration:[durationNumber doubleValue] delay:0 options:[curveNumber unsignedIntegerValue] animations:^{
        [self.view layoutIfNeeded];
    }completion:NULL];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]){
        otherGestureRecognizer.enabled = NO;
        otherGestureRecognizer.enabled = YES;
    }
    
    return NO;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidChange:(UITextField *)textField{
    if ([self.activeTextField isKindOfClass:[OLPhotoTextField class]]){
        [(OLPhotoTextField *)textField updateSize];
    }
    
    self.ctaButton.enabled = YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    [[OLUserSession currentSession].kiteVc setLastTouchDate:[NSDate date] forViewController:self];
    self.ctaButton.enabled = YES;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    if ([textField isKindOfClass:[OLPhotoTextField class]]){
        [(OLPhotoTextField *)textField updateSize];
    }
    [textField setNeedsLayout];
    [textField layoutIfNeeded];
    
    //Remove empty textfield
    if ((!textField.text || [textField.text isEqualToString:@""]) && [textField isKindOfClass:[OLPhotoTextField class]]){
        [textField removeFromSuperview];
        [self.textFields removeObjectIdenticalTo:(OLPhotoTextField *)textField];
        self.activeTextField = nil;
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if (textField == self.borderTextField){
        [self dismissDrawerWithCompletionHandler:NULL];
        return YES;
    }
    
    if (self.activeTextField == textField){
        if (self.editingTools.collectionView.tag == kOLEditTagFonts){
            [self dismissDrawerWithCompletionHandler:^(BOOL finished){
                self.editingTools.collectionView.tag = kOLEditTagTextTools;
                
                self.editingTools.drawerHeightCon.constant = self.originalDrawerHeight;
                [self.view layoutIfNeeded];
                
                [self.editingTools.collectionView reloadData];
                [self showDrawerWithCompletionHandler:NULL];
            }];
        }
        if ([self.activeTextField isKindOfClass:[OLPhotoTextField class]]){
            [(OLPhotoTextField *)textField updateSize];
        }
        return YES;
    }
    [self.activeTextField resignFirstResponder];
    if ([self.activeTextField isKindOfClass:[OLPhotoTextField class]]){
        [self setButtonsHidden:YES forTextField:self.activeTextField];
    }
    self.activeTextField = (OLPhotoTextField *)textField;
    if ([self.activeTextField isKindOfClass:[OLPhotoTextField class]]){
        [self setButtonsHidden:NO forTextField:self.activeTextField];
    }
    return NO;
}

- (void)photoTextFieldDidSendActionTouchUpInsideForX:(OLPhotoTextField *)textField{
    [textField removeFromSuperview];
    [self.textFields removeObjectIdenticalTo:textField];
    self.activeTextField = nil;
}

- (void)photoTextFieldDidSendActionTouchDownForResize:(OLPhotoTextField *)textField{
    self.resizingTextField = YES;
}

- (void)photoTextFieldDidSendActionTouchUpForResize:(OLPhotoTextField *)textField{
    self.resizingTextField = NO;
}

- (void)photoTextFieldDidSendActionTouchDownForRotate:(OLPhotoTextField *)textField{
    self.rotatingTextField = YES;
}

- (void)photoTextFieldDidSendActionTouchUpForRotate:(OLPhotoTextField *)textField{
    self.rotatingTextField = NO;
}

#pragma mark - RMImageCropperDelegate methods

- (void)imageCropperDidTransformImage:(RMImageCropper *)imageCropper {
    self.ctaButton.enabled = YES;
}

#pragma mark Image Picker

- (void)showImagePicker{
    OLImagePickerViewController *vc = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
    vc.delegate = self;
    vc.selectedAssets = [[NSMutableArray alloc] init];
    vc.maximumPhotos = 1;
    vc.product = self.product;
    
    if ([OLKiteUtils numberOfProvidersAvailable] <= 2 && [[OLUserSession currentSession].kiteVc.customImageProviders.firstObject isKindOfClass:[OLCustomViewControllerPhotoProvider class]]){
        //Skip the image picker and only show the custom vc
        
        self.vcDelegateForCustomVc = vc; //Keep strong reference
        UIViewController<OLCustomPickerController> *customVc = [(OLCustomViewControllerPhotoProvider *)[OLUserSession currentSession].kiteVc.customImageProviders.firstObject vc];
        if (!customVc){
            customVc = [[OLUserSession currentSession].kiteVc.delegate imagePickerViewControllerForName:vc.providerForPresentedVc.name];
        }        [customVc safePerformSelector:@selector(setDelegate:) withObject:vc];
        [customVc safePerformSelector:@selector(setProductId:) withObject:self.product.templateId];
        [customVc safePerformSelector:@selector(setSelectedAssets:) withObject:[[NSMutableArray alloc] init]];
        if ([customVc respondsToSelector:@selector(setMaximumPhotos:)]){
            customVc.maximumPhotos = 1;
        }
        
        [self presentViewController:customVc animated:YES completion:NULL];
        self.presentedVc = customVc;
        return;
    }
    else{
        [self presentViewController:[[OLNavigationController alloc] initWithRootViewController:vc] animated:YES completion:NULL];
    }
}

- (void)imagePickerDidCancel:(OLImagePickerViewController *)vc{
    if (self.presentedVc){
        [self.presentedVc dismissViewControllerAnimated:YES completion:NULL];
    }
    else{
        [vc dismissViewControllerAnimated:YES completion:NULL];
    }
    
    self.vcDelegateForCustomVc = nil;
    self.presentedVc = nil;
}

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    self.asset = addedAssets.firstObject;
    self.edits = [self.asset.edits copy];
    if (self.asset){
        self.didReplaceAsset = YES;
        self.ctaButton.enabled = YES;
        id view = [self.view viewWithTag:1010];
        if ([view isKindOfClass:[UIActivityIndicatorView class]]){
            [(UIActivityIndicatorView *)view startAnimating];
        }
        
        [self loadImageFromAsset];
    }
    
    if (self.presentedVc){
        [self.presentedVc dismissViewControllerAnimated:YES completion:^{
            if ([self isUsingMultiplyBlend]){
                [self updateProductRepresentationForChoice:nil];
            }
        }];
    }
    else{
        [vc dismissViewControllerAnimated:YES completion:^{
            if ([self isUsingMultiplyBlend]){
                [self updateProductRepresentationForChoice:nil];
            }
        }];
    }
    
    self.vcDelegateForCustomVc = nil;
    self.presentedVc = nil;
}

- (void)loadImageFromAsset{
    if (!self.asset){
        return;
    }
    self.animating = YES;
    self.fullImage = nil;
    self.artboard.assetViews.firstObject.imageView.image = nil;
    __weak OLImageEditViewController *welf = self;
    [self.asset imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:^(float progress){
        dispatch_async(dispatch_get_main_queue(), ^{
            [welf.artboard.assetViews.firstObject setProgress:progress];
        });
    } completion:^(UIImage *image, NSError *error){
        [self setImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *copy = [[NSArray alloc] initWithArray:welf.edits.textsOnPhoto copyItems:NO];
            for (OLTextOnPhoto *textOnPhoto in copy){
                UITextField *textField = [welf addTextFieldToView:welf.artboard existing:nil];
                textField.text = textOnPhoto.text;
                textField.transform = textOnPhoto.transform;
                textField.textColor = textOnPhoto.color;
                textField.font = [OLKiteUtils fontWithName:textOnPhoto.fontName size:textOnPhoto.fontSize];
                [self.edits.textsOnPhoto removeObject:textOnPhoto];
            }
            
            [welf loadImages];
            
            id view = [welf.view viewWithTag:1010];
            if ([view isKindOfClass:[UIActivityIndicatorView class]]){
                [(UIActivityIndicatorView *)view stopAnimating];
            }
        });
    }];
}

@end
