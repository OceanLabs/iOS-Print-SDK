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

#import "OLScrollCropViewController.h"
#import "OLPhotoTextField.h"
#import "OLColorSelectionCollectionViewCell.h"
#import "OLKiteUtils.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIView+RoundRect.h"
#import "OLEditingToolsView.h"
#import "OLAsset+Private.h"

const NSInteger kOLEditDrawerTagTools = 10;
const NSInteger kOLEditDrawerTagColors = 20;
const NSInteger kOLEditDrawerTagFonts = 30;

@interface OLScrollCropViewController () <RMImageCropperDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, OLPhotoTextFieldDelegate>
@property (weak, nonatomic) UIButton *doneButton;
@property (assign, nonatomic) NSInteger initialOrientation;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerYCon;

@property (strong, nonatomic) NSMutableArray<OLPhotoTextField *> *textFields;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView2;
@property (strong, nonatomic) NSArray<UIColor *> *availableColors;
@property (weak, nonatomic) IBOutlet UIView *textFieldsView;
@property (strong, nonatomic) NSArray<NSString *> *fonts;
@property (assign, nonatomic) CGFloat textFieldKeyboardDiff;
@property (assign, nonatomic) BOOL resizingTextField;
@property (assign, nonatomic) BOOL rotatingTextField;
@property (weak, nonatomic) IBOutlet UIView *drawerView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *drawerHeightCon;
@property (weak, nonatomic) IBOutlet UILabel *drawerLabel;

@property (strong, nonatomic) OLPhotoTextField *activeTextField;
@property (assign, nonatomic) CGFloat originalDrawerHeight;
@property (weak, nonatomic) IBOutlet OLEditingToolsView *editingTools;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *allViews;

@end

@implementation OLScrollCropViewController

-(NSArray<NSString *> *) fonts{
    if (!_fonts){
        NSMutableArray<NSString *> *fonts = [[NSMutableArray<NSString *> alloc] init];
        for (NSString *familyName in [UIFont familyNames]){
            for (NSString *fontName in [UIFont fontNamesForFamilyName:familyName]) {
                [fonts addObject:fontName];
            }
        }
        [fonts addObject:NSLocalizedString(@"Default", @"")];
        _fonts = [fonts sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    return _fonts;
}

-(OLPhotoEdits *) edits{
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

- (void)setActiveTextField:(OLPhotoTextField *)activeTextField{
    if (activeTextField){
        if (self.collectionView.tag != kOLEditDrawerTagTools && activeTextField != _activeTextField){ //Showing colors/fonts for another textField. Dismiss first
            [self dismissDrawerWithCompletionHandler:^(BOOL finished){
                self.collectionView.tag = kOLEditDrawerTagTools;
                
                self.drawerHeightCon.constant = self.originalDrawerHeight;
                [self.view layoutIfNeeded];
                
                [self.collectionView reloadData];
                [self showDrawerWithCompletionHandler:NULL];
            }];
        }
        else{
            self.collectionView.tag = kOLEditDrawerTagTools;
            
            self.drawerHeightCon.constant = self.originalDrawerHeight;
            [self.view layoutIfNeeded];
            
            [self.collectionView reloadData];
            [self showDrawerWithCompletionHandler:NULL];
        }
    }
    else{
        [self dismissDrawerWithCompletionHandler:NULL];
    }
     _activeTextField = activeTextField;
}

- (void)dismissDrawerWithCompletionHandler:(void(^)(BOOL finished))handler{
    self.editingTools.button1.selected = NO;
    self.editingTools.button2.selected = NO;
    self.editingTools.button3.selected = NO;
    self.editingTools.button4.selected = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.drawerView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        [self.view bringSubviewToFront:self.editingTools];
        if (handler){
            handler(finished);
        }
    }];
}

- (void)showDrawerWithCompletionHandler:(void(^)(BOOL finished))handler{
    if (self.collectionView.tag == kOLEditDrawerTagTools){
        self.drawerLabel.text = NSLocalizedString(@"Tools", @"");
        self.editingTools.button3.selected = YES;
    }
    else if (self.collectionView.tag == kOLEditDrawerTagColors){
        self.drawerLabel.text = NSLocalizedString(@"Text Colour", @"");
    }
    else if (self.collectionView.tag == kOLEditDrawerTagFonts){
        self.drawerLabel.text = NSLocalizedString(@"Fonts", @"");
    }
    //set height
    [UIView animateWithDuration:0.25 animations:^{
        self.drawerView.transform = CGAffineTransformMakeTranslation(0, -self.drawerView.frame.size.height);
    } completion:^(BOOL finished){
        if (handler){
            handler(finished);
        }
    }];
}

- (void)dismissKeyboard{
    for (OLPhotoTextField *textField in self.textFields){
        if ([textField isFirstResponder]){
            [textField resignFirstResponder];
            return;
        }
    }
    
    [self.activeTextField hideButtons];
    self.activeTextField = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.availableColors = @[[UIColor blackColor], [UIColor whiteColor], [UIColor darkGrayColor], [UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor yellowColor], [UIColor magentaColor], [UIColor cyanColor], [UIColor brownColor], [UIColor orangeColor], [UIColor purpleColor], [UIColor colorWithRed:0.890 green:0.863 blue:0.761 alpha:1.000], [UIColor colorWithRed:0.765 green:0.678 blue:0.588 alpha:1.000], [UIColor colorWithRed:0.624 green:0.620 blue:0.612 alpha:1.000], [UIColor colorWithRed:0.976 green:0.910 blue:0.933 alpha:1.000], [UIColor colorWithRed:0.604 green:0.522 blue:0.741 alpha:1.000], [UIColor colorWithRed:0.996 green:0.522 blue:0.886 alpha:1.000], [UIColor colorWithRed:0.392 green:0.271 blue:0.576 alpha:1.000], [UIColor colorWithRed:0.906 green:0.573 blue:0.565 alpha:1.000], [UIColor colorWithRed:0.984 green:0.275 blue:0.404 alpha:1.000], [UIColor colorWithRed:0.918 green:0.000 blue:0.200 alpha:1.000], [UIColor colorWithRed:0.776 green:0.176 blue:0.157 alpha:1.000], [UIColor colorWithRed:0.965 green:0.831 blue:0.239 alpha:1.000], [UIColor colorWithRed:0.961 green:0.682 blue:0.118 alpha:1.000], [UIColor colorWithRed:0.945 green:0.482 blue:0.204 alpha:1.000], [UIColor colorWithRed:0.827 green:0.859 blue:0.898 alpha:1.000], [UIColor colorWithRed:0.616 green:0.710 blue:0.851 alpha:1.000], [UIColor colorWithRed:0.400 green:0.541 blue:0.784 alpha:1.000], [UIColor colorWithRed:0.400 green:0.541 blue:0.784 alpha:1.000], [UIColor colorWithRed:0.173 green:0.365 blue:0.725 alpha:1.000], [UIColor colorWithRed:0.102 green:0.247 blue:0.361 alpha:1.000], [UIColor colorWithRed:0.765 green:0.933 blue:0.898 alpha:1.000], [UIColor colorWithRed:0.506 green:0.788 blue:0.643 alpha:1.000], [UIColor colorWithRed:0.345 green:0.502 blue:0.400 alpha:1.000], [UIColor colorWithRed:0.337 green:0.427 blue:0.208 alpha:1.000]];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.originalDrawerHeight = self.drawerHeightCon.constant;
    
    if (self.previewView && !self.skipPresentAnimation){
        self.view.backgroundColor = [UIColor clearColor];
        self.previewView.alpha = 0.15;
        [self.view addSubview:self.previewView];
        [self.view sendSubviewToBack:self.previewView];
        for (UIView *view in self.allViews){
            view.alpha = 0;
        }
    }
    
    [self.cropView setClipsToBounds:NO];
    self.cropView.backgroundColor = [UIColor clearColor];
    
    self.initialOrientation = self.fullImage.imageOrientation;
    self.cropView.delegate = self;
    
    if (self.forceSourceViewDimensions && self.previewSourceView){
        UIView *view = self.cropView;
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
    
    UITapGestureRecognizer *dismissKeyboardTapGesture = [[UITapGestureRecognizer alloc] init];
    [dismissKeyboardTapGesture addTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:dismissKeyboardTapGesture];
    
    NSArray *copy = [[NSArray alloc] initWithArray:self.edits.textsOnPhoto copyItems:NO];
    for (OLTextOnPhoto *textOnPhoto in copy){
        UITextField *textField = [self addTextFieldToView:self.cropView temp:NO];
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
    [self.drawerView addSubview:view];
    [self.drawerView sendSubviewToBack:view];
    
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    self.drawerView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    
    
    [self.editingTools.ctaButton addTarget:self action:@selector(onBarButtonDoneTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.editingTools.button4 removeFromSuperview];
    [self.editingTools.button1 setImage:[UIImage imageNamedInKiteBundle:@"flip"] forState:UIControlStateNormal];
    [self.editingTools.button3 setImage:[UIImage imageNamedInKiteBundle:@"Tt"] forState:UIControlStateNormal];
    [self.editingTools.button2 setImage:[UIImage imageNamedInKiteBundle:@"rotate"] forState:UIControlStateNormal];
    
    [self.editingTools.button1 addTarget:self action:@selector(onButtonHorizontalFlipClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.editingTools.button3 addTarget:self action:@selector(onButtonAddTextClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.editingTools.button2 addTarget:self action:@selector(onButtonRotateClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    self.doneButton = self.editingTools.ctaButton;
    self.doneButton.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.previewView && !self.skipPresentAnimation){
        [UIView animateWithDuration:0.10 animations:^{
            self.previewView.alpha = 1;
        } completion:^(BOOL finished){
            self.previewSourceView.hidden = YES;
            [UIView animateWithDuration:0.25 animations:^{
                self.previewView.frame = self.cropView.frame;
            }completion:^(BOOL finished){
                [UIView animateWithDuration:0.25 animations:^{
                    self.view.backgroundColor = [UIColor blackColor];
                    for (UIView *view in self.allViews){
                        view.alpha = 1;
                    }
                } completion:^(BOOL finished){
                    [self.previewView removeFromSuperview];
                }];
            }];
        }];
    }
}

- (void)setupImage{
    [self.cropView removeConstraint:self.aspectRatioConstraint];
    self.aspectRatioConstraint = [NSLayoutConstraint constraintWithItem:self.cropView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.cropView attribute:NSLayoutAttributeWidth multiplier:self.aspectRatio constant:0];
    [self.cropView addConstraints:@[self.aspectRatioConstraint]];
    
    if (self.edits.counterClockwiseRotations > 0 || self.edits.flipHorizontal || self.edits.flipVertical){
        self.cropView.image = [UIImage imageWithCGImage:self.fullImage.CGImage scale:self.fullImage.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.edits.counterClockwiseRotations andInitialOrientation:self.fullImage.imageOrientation horizontalFlip:self.edits.flipHorizontal verticalFlip:self.edits.flipVertical]];
    }
    else{
        [self.cropView setImage:self.fullImage];
    }
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    self.cropView.imageView.transform = self.edits.cropTransform;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setupImage];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    for (NSLayoutConstraint *con in self.cropView.superview.constraints){
        if ((con.firstItem == self.cropView && con.firstAttribute == NSLayoutAttributeWidth) || (con.firstItem == self.cropView && con.firstAttribute == NSLayoutAttributeHeight)){
            [self.cropView.superview removeConstraint:con];
        }
    }
    [self.cropView removeConstraint:self.aspectRatioConstraint];
    self.cropView.imageView.image = nil;
    self.edits.cropImageRect = [self.cropView getImageRect];
    self.edits.cropImageFrame = [self.cropView getFrameRect];
    self.edits.cropImageSize = [self.cropView croppedImageSize];
    self.edits.cropTransform = [self.cropView.imageView transform];
    
    [coordinator animateAlongsideTransition:^(id context){
        [self setupImage];
    }completion:NULL];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if (self.enableCircleMask){
        CAShapeLayer *aCircle=[CAShapeLayer layer];
        aCircle.path=[UIBezierPath bezierPathWithRoundedRect:self.cropView.bounds cornerRadius:self.cropView.frame.size.height/2].CGPath;
        
        aCircle.fillColor=[UIColor blackColor].CGColor;
        self.cropView.layer.mask=aCircle;
    }
}

- (void)onBarButtonDoneTapped:(id)sender {
    self.edits.cropImageRect = [self.cropView getImageRect];
    self.edits.cropImageFrame = [self.cropView getFrameRect];
    self.edits.cropImageSize = [self.cropView croppedImageSize];
    self.edits.cropTransform = [self.cropView.imageView transform];
    
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
    
    if ([self.delegate respondsToSelector:@selector(scrollCropViewController:didFinishCroppingImage:)]){
        [self.delegate scrollCropViewController:self didFinishCroppingImage:[self.cropView editedImage]];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (IBAction)onBarButtonCancelTapped:(UIBarButtonItem *)sender {
    if (self.doneButton.enabled && self.previewView && [self.delegate respondsToSelector:@selector(scrollCropViewControllerDidDropChanges:)]){ //discard changes
        self.previewSourceView.hidden = NO;
        
        self.previewView = [self.cropView snapshotViewAfterScreenUpdates:YES];
        self.previewView.frame = self.cropView.frame;
        [self.view addSubview:self.previewView];
        [UIView animateWithDuration:0.25 animations:^{
            self.view.backgroundColor = [UIColor clearColor];
            for (UIView *view in self.allViews){
                view.alpha = 0;
            }
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.7 animations:^{
                self.previewView.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(0, self.view.frame.size.height), -M_PI_4);
            }completion:^(BOOL finished){
                if ([self.delegate respondsToSelector:@selector(scrollCropViewControllerDidDropChanges:)]){
                    [self.delegate scrollCropViewControllerDidCancel:self];
                }
                else{
                    [self dismissViewControllerAnimated:NO completion:NULL];
                }
            }];
        }];
    }
    else if ([self.delegate respondsToSelector:@selector(scrollCropViewControllerDidCancel:)]){
        [self.delegate scrollCropViewControllerDidCancel:self];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:NULL];
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
        self.previewView = [self.cropView snapshotViewAfterScreenUpdates:YES];
        self.previewView.frame = self.cropView.frame;
        [self.view addSubview:self.previewView];
        [UIView animateWithDuration:0.25 animations:^{
            self.view.backgroundColor = [UIColor clearColor];
            for (UIView *view in self.allViews){
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

- (IBAction)onButtonHorizontalFlipClicked:(id)sender {
    if (self.cropView.isCorrecting){
        return;
    }
    
    [self.activeTextField resignFirstResponder];
    [self.activeTextField hideButtons];
    self.activeTextField = nil;
    
    [self.edits performHorizontalFlipEditFromOrientation:self.cropView.imageView.image.imageOrientation];
    
    [UIView transitionWithView:self.cropView.imageView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
        
        [self.cropView setImage:[UIImage imageWithCGImage:self.fullImage.CGImage scale:self.cropView.imageView.image.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.edits.counterClockwiseRotations andInitialOrientation:self.initialOrientation horizontalFlip:self.edits.flipHorizontal verticalFlip:self.edits.flipVertical]]];
        
    }completion:NULL];
    
    self.doneButton.enabled = YES;
}

- (IBAction)onButtonRotateClicked:(id)sender {
    if (self.cropView.isCorrecting){
        return;
    }
    
    [self.activeTextField resignFirstResponder];
    [self.activeTextField hideButtons];
    self.activeTextField = nil;
    
    for (UITextField *textField in self.textFields){
        UITextField *textFieldCopy = [self addTextFieldToView:self.textFieldsView temp:YES];
        textFieldCopy.text = textField.text;
        textFieldCopy.transform = textField.transform;
        textFieldCopy.textColor = textField.textColor;
        textFieldCopy.font = textField.font;
        textField.hidden = YES;
    }
    
    [(UIBarButtonItem *)sender setEnabled:NO];
    self.edits.counterClockwiseRotations = (self.edits.counterClockwiseRotations + 1) % 4;
    CGAffineTransform transform = self.cropView.imageView.transform;
    transform.tx = self.cropView.imageView.transform.ty;
    transform.ty = -self.cropView.imageView.transform.tx;
    
    CGRect cropboxRect = self.cropView.frame;
    
    UIImage *newImage = [UIImage imageWithCGImage:self.fullImage.CGImage scale:self.cropView.imageView.image.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.edits.counterClockwiseRotations andInitialOrientation:self.initialOrientation horizontalFlip:self.edits.flipHorizontal verticalFlip:self.edits.flipVertical]];
    CGFloat imageAspectRatio = newImage.size.height/newImage.size.width;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.cropView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        
        CGFloat boxWidth = self.cropView.frame.size.width;
        CGFloat boxHeight = self.cropView.frame.size.height;
        
        CGFloat imageWidth;
        CGFloat imageHeight;
        
        if (imageAspectRatio > 1.0){
            imageHeight = boxHeight;
            imageWidth = boxHeight * imageAspectRatio;
        }
        else{
            imageWidth = boxWidth;
            imageHeight = boxWidth / imageAspectRatio;
        }
        
        self.cropView.imageView.frame = CGRectMake((boxHeight - imageWidth)/ 2.0, (boxWidth - imageHeight) / 2.0, imageWidth, imageHeight);
        
    } completion:^(BOOL finished){
        for (UITextField *textField in self.textFields){
            textField.hidden = NO;
        }
        for (UITextField *textField in [self.textFieldsView.subviews copy]){
            [textField removeFromSuperview];
        }
        
        self.cropView.transform = CGAffineTransformIdentity;
        self.cropView.frame = cropboxRect;
        [self.cropView setImage:newImage];
        
        [(UIBarButtonItem *)sender setEnabled:YES];
        self.doneButton.enabled = YES;
    }];
}

- (UITextField *)addTextFieldToView:(UIView *)view temp:(BOOL)temp{
    OLPhotoTextField *textField = [[OLPhotoTextField alloc] initWithFrame:CGRectMake(0, 0, 130, 70)];
    textField.center = self.cropView.center;
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
    
    if (!temp){
        [self.textFields addObject:textField];
    }
    
    return textField;
}

- (IBAction)onButtonAddTextClicked:(UIBarButtonItem *)sender {
    UITextField *textField = [self addTextFieldToView:self.cropView temp:NO];
    [self.view layoutIfNeeded];
    [textField becomeFirstResponder]; //Take focus away from any existing active TF
    [textField becomeFirstResponder]; //Become first responder

    self.doneButton.enabled = YES;
}
- (IBAction)onDrawerButtonDoneClicked:(UIButton *)sender {
    [self dismissDrawerWithCompletionHandler:^(BOOL finished){
        self.collectionView.tag = kOLEditDrawerTagTools;
        
        self.drawerHeightCon.constant = self.originalDrawerHeight;
        [self.view layoutIfNeeded];
        
        [self.collectionView reloadData];
        [self showDrawerWithCompletionHandler:NULL];
    }];
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
        original = gesture.view.transform;
        originalFrame = gesture.view.frame;
        CGPoint gesturePoint = [gesture locationInView:self.cropView];
        CGPoint translatedPoint = CGPointMake(gesturePoint.x - original.tx, gesturePoint.y - original.ty);
        originalAngle = [self angleOfTouchPoint:translatedPoint fromPoint:gesture.view.center];
        
        
        
        OLPhotoTextField *textField = (OLPhotoTextField *)gesture.view;
        originalFontSize = textField.font.pointSize;
        
        if (self.activeTextField != textField){
            [self.activeTextField resignFirstResponder];
            [self.activeTextField hideButtons];
            self.activeTextField = (OLPhotoTextField *)textField;
            [self.activeTextField showButtons];
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
            
            CGPoint gesturePoint = [gesture locationInView:self.cropView];
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
            CGFloat minY = gesture.view.frame.size.height/2.0 - self.cropView.frame.size.height / 2.0;
            CGFloat maxY = -minY;
            CGFloat minX = gesture.view.frame.size.width/2.0 - self.cropView.frame.size.width / 2.0;
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
        self.resizingTextField = NO;
        self.rotatingTextField = NO;
    }
    
    self.doneButton.enabled = YES;
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView.tag == kOLEditDrawerTagTools){
        return 2;
    }
    else if (collectionView.tag == kOLEditDrawerTagColors){
        return self.availableColors.count;
    }
    else if (collectionView.tag == kOLEditDrawerTagFonts){
        return self.fonts.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell;
    if (collectionView.tag == kOLEditDrawerTagTools){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"toolCell" forIndexPath:indexPath];
        [cell viewWithTag:10].tintColor = [UIColor blackColor];
        [(UILabel *)[cell viewWithTag:20] setTextColor:[UIColor blackColor]];
        if (indexPath.item == 0){
            [(UIImageView *)[cell viewWithTag:10] setImage:[UIImage imageNamedInKiteBundle:@"Aa"]];
            [(UILabel *)[cell viewWithTag:20] setText:NSLocalizedString(@"Fonts", @"")];
        }
        else if (indexPath.item == 1){
            [(UIImageView *)[cell viewWithTag:10] setImage:[UIImage imageNamedInKiteBundle:@"paint-bucket-icon"]];
            [(UILabel *)[cell viewWithTag:20] setText:NSLocalizedString(@"Text Colour", @"")];
        }
    }
    else if (collectionView.tag == kOLEditDrawerTagColors){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"colorSelectionCell" forIndexPath:indexPath];
        
        [cell setSelected:NO];
        for (UITextField *textField in self.textFields){
            if ([textField isFirstResponder]){
                [cell setSelected:[textField.textColor isEqual:self.availableColors[indexPath.item]]];
                break;
            }
        }
        
        [(OLColorSelectionCollectionViewCell *)cell setColor:self.availableColors[indexPath.item]];
        
        [cell setSelected:[self.activeTextField.textColor isEqual:self.availableColors[indexPath.item]]];
        
        [cell setNeedsDisplay];
    }
    else if (collectionView.tag == kOLEditDrawerTagFonts){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"fontCell" forIndexPath:indexPath];
        UILabel *label = [cell viewWithTag:10];
        [label makeRoundRectWithRadius:4];
        label.text = self.fonts[indexPath.item];
        label.font = [OLKiteUtils fontWithName:label.text size:17];
        if ([self.activeTextField.font.fontName isEqualToString:label.text]){
            label.backgroundColor = [UIColor colorWithRed:0.349 green:0.757 blue:0.890 alpha:1.000];
        }
        else{
            label.backgroundColor = [UIColor clearColor];
        }
        label.textColor = [UIColor blackColor];
    }
    
    return cell;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 25;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    if (self.collectionView.tag == kOLEditDrawerTagFonts){
        return 0;
    }
    
    return 25;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == kOLEditDrawerTagTools){
        return CGSizeMake(self.collectionView.frame.size.height * 2.0, self.collectionView.frame.size.height);
    }
    if (collectionView.tag == kOLEditDrawerTagColors){
        return CGSizeMake(self.collectionView.frame.size.height, self.collectionView.frame.size.height);
    }
    else if (collectionView.tag == kOLEditDrawerTagFonts){
        return CGSizeMake(collectionView.frame.size.width - 40, 30);
    }
    
    return CGSizeZero;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag == kOLEditDrawerTagTools){
        CGFloat margin = (collectionView.frame.size.width - ([self collectionView:collectionView layout:self.collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]].width * 2 + [self collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section]))/2.0;
        return UIEdgeInsetsMake(0, margin, 0, margin);
    }
    else if (collectionView.tag == kOLEditDrawerTagColors){
        return UIEdgeInsetsMake(0, 5, 0, 5);
    }
    
    return UIEdgeInsetsZero;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == kOLEditDrawerTagTools){
        if (indexPath.item == 0){
            [self dismissDrawerWithCompletionHandler:^(BOOL finished){
                [self.view bringSubviewToFront:self.drawerView];
                collectionView.tag = kOLEditDrawerTagFonts;
                
                self.drawerHeightCon.constant = self.originalDrawerHeight + 150;
                [self.view layoutIfNeeded];
                [(UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
                
                [collectionView reloadData];
                [self showDrawerWithCompletionHandler:NULL];
            }];
        }
        else if (indexPath.item == 1){
            [self dismissDrawerWithCompletionHandler:^(BOOL finished){
                [self.view bringSubviewToFront:self.drawerView];
                collectionView.tag = kOLEditDrawerTagColors;
                [(UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
                [collectionView reloadData];
                [self showDrawerWithCompletionHandler:NULL];
            }];
        }
        
    }
    else if (collectionView.tag == kOLEditDrawerTagColors){
        [self.activeTextField setTextColor:self.availableColors[indexPath.item]];
        self.doneButton.enabled = YES;
        [collectionView reloadData];
    }
    else if (collectionView.tag == kOLEditDrawerTagFonts){
        [self.activeTextField setFont:[OLKiteUtils fontWithName:self.fonts[indexPath.item] size:self.activeTextField.font.pointSize]];
        [self.activeTextField updateSize];
        self.doneButton.enabled = YES;
        [collectionView reloadData];
    }
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
        
        for (UITextField *textField in self.textFields){
            if ([textField isFirstResponder]){
                textField.transform = CGAffineTransformTranslate(textField.transform, 0, self.textFieldKeyboardDiff);
                self.textFieldKeyboardDiff = 0;
                break;
            }
        }
    }completion:NULL];
}

- (void)keyboardWillChangeFrame:(NSNotification*)aNotification{
    NSDictionary *info = [aNotification userInfo];
    CGFloat keyboardHeight = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    NSNumber *durationNumber = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curveNumber = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    for (UITextField *textField in self.textFields){
        if ([textField isFirstResponder]){
            CGPoint p = [self.cropView convertRect:textField.frame toView:nil].origin;
            
            CGFloat diff = p.y + textField.frame.size.height - (self.view.frame.size.height - keyboardHeight);
            if (diff > 0) {
                textField.transform = CGAffineTransformTranslate(textField.transform, 0, -diff);
                self.textFieldKeyboardDiff = diff;
            }
            
            break;
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
    [(OLPhotoTextField *)textField updateSize];
    
    self.doneButton.enabled = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [(OLPhotoTextField *)textField updateSize];
    [textField setNeedsLayout];
    [textField layoutIfNeeded];
    
    //Remove empty textfield
    if (!textField.text || [textField.text isEqualToString:@""]){
        [textField removeFromSuperview];
        [self.textFields removeObjectIdenticalTo:(OLPhotoTextField *)textField];
        self.activeTextField = nil;
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if (self.activeTextField == textField){
        if (self.collectionView.tag == kOLEditDrawerTagFonts){
            [self dismissDrawerWithCompletionHandler:^(BOOL finished){
                self.collectionView.tag = kOLEditDrawerTagTools;
                
                self.drawerHeightCon.constant = self.originalDrawerHeight;
                [self.view layoutIfNeeded];
                
                [self.collectionView reloadData];
                [self showDrawerWithCompletionHandler:NULL];
            }];
        }

        [(OLPhotoTextField *)textField updateSize];
        return YES;
    }
    [self.activeTextField resignFirstResponder];
    [self.activeTextField hideButtons];
    self.activeTextField = (OLPhotoTextField *)textField;
    [self.activeTextField showButtons];
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
    self.doneButton.enabled = YES;
}

@end
