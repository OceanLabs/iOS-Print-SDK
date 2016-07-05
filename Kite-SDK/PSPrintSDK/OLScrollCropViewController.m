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
#import "OLPrintPhoto.h"
#import "OLPhotoTextField.h"
#import "OLColorSelectionCollectionViewCell.h"
#import "OLKiteUtils.h"

@interface OLScrollCropViewController () <RMImageCropperDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, OLPhotoTextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (assign, nonatomic) NSInteger initialOrientation;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerYCon;

@property (strong, nonatomic) NSMutableArray<OLPhotoTextField *> *textFields;
@property (weak, nonatomic) IBOutlet UIView *colorsView;
@property (weak, nonatomic) IBOutlet UIView *fontsView;
@property (weak, nonatomic) IBOutlet UIToolbar *textToolsToolbar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *colorsViewBottomCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fontsCollectionViewBottomCon;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView2;
@property (weak, nonatomic) IBOutlet UICollectionView *colorsCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *fontsCollectionView;
@property (strong, nonatomic) NSArray<UIColor *> *availableColors;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *colorsTrailingCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fontsLeadingCon;
@property (weak, nonatomic) IBOutlet UIView *textFieldsView;
@property (strong, nonatomic) NSArray<NSString *> *fonts;
@property (assign, nonatomic) CGFloat textFieldKeyboardDiff;


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

- (void)dismissKeyboard{
    for (OLPhotoTextField *textField in self.textFields){
        if ([textField isFirstResponder]){
            [textField resignFirstResponder];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.availableColors = @[[UIColor blackColor], [UIColor whiteColor], [UIColor grayColor], [UIColor greenColor], [UIColor redColor], [UIColor blueColor], [UIColor magentaColor], [UIColor orangeColor]];
    
    self.colorsCollectionView.dataSource = self;
    self.colorsCollectionView.delegate = self;
    self.fontsCollectionView.dataSource = self;
    self.fontsCollectionView.delegate = self;
    
    self.colorsTrailingCon.constant = -self.colorsView.frame.size.width;
    self.fontsLeadingCon.constant = -self.fontsView.frame.size.width;
    
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
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
        [doneButton addTarget:self action:@selector(onBarButtonDoneTapped:) forControlEvents:UIControlEventTouchUpInside];
        [doneButton setTitle: NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
        [doneButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
        [doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
        [doneButton sizeToFit];
        
        UIBarButtonItem *item =[[UIBarButtonItem alloc] initWithCustomView:doneButton];
        self.navigationItem.rightBarButtonItem = item;
    }
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
    
    self.textToolsToolbar.transform = CGAffineTransformMakeTranslation(0, -self.textToolsToolbar.frame.origin.x - self.textToolsToolbar.frame.size.height - [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height);
    
    [self registerForKeyboardNotifications];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        
        self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        UIView *view = self.visualEffectView;
        [self.colorsView addSubview:view];
        [self.colorsView sendSubviewToBack:view];
        
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
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        
        self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        UIView *view = self.visualEffectView;
        [self.fontsView addSubview:view];
        [self.fontsView sendSubviewToBack:view];
        
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
        self.colorsView.backgroundColor = [UIColor blackColor];
        self.fontsView.backgroundColor = [UIColor blackColor];
    }
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

- (IBAction)onBarButtonDoneTapped:(UIBarButtonItem *)sender {
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
    textField.photoTextFieldDelegate = self;
    
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
    [textField becomeFirstResponder];

    self.doneButton.enabled = YES;
}

- (void)onTextfieldGesturePanRecognized:(UIPanGestureRecognizer *)gesture{
    static CGAffineTransform original;
    
    if (gesture.state == UIGestureRecognizerStateBegan){
        original = gesture.view.transform;
    }
    else if (gesture.state == UIGestureRecognizerStateChanged){
        CGPoint translate = [gesture translationInView:gesture.view.superview];
        CGAffineTransform transform = CGAffineTransformTranslate(original, translate.x, translate.y);
        
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
    
    self.doneButton.enabled = YES;
}

- (IBAction)onButtonFontTapped:(UIBarButtonItem *)sender {
    self.fontsLeadingCon.constant = self.fontsLeadingCon.constant == 0 ? -self.fontsView.frame.size.width : 0;
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self.view layoutIfNeeded];
    } completion:NULL];
}


- (IBAction)onButtonColorTapped:(UIBarButtonItem *)sender {
    self.colorsTrailingCon.constant = self.colorsTrailingCon.constant == 0 ? -self.colorsView.frame.size.width : 0;
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self.view layoutIfNeeded];
    } completion:NULL];
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView == self.colorsCollectionView){
        return self.availableColors.count;
    }
    else if (collectionView == self.fontsCollectionView){
        return self.fonts.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell;
    if (collectionView == self.colorsCollectionView){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"colorSelectionCell" forIndexPath:indexPath];
        [(OLColorSelectionCollectionViewCell *)cell setDarkMode:YES];
        
        [cell setSelected:NO];
        for (UITextField *textField in self.textFields){
            if ([textField isFirstResponder]){
                [cell setSelected:[textField.textColor isEqual:self.availableColors[indexPath.item]]];
                break;
            }
        }
        
        [(OLColorSelectionCollectionViewCell *)cell setColor:self.availableColors[indexPath.item]];
        [cell setNeedsDisplay];
    }
    else if (collectionView == self.fontsCollectionView){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"fontCell" forIndexPath:indexPath];
        UILabel *label = [cell viewWithTag:10];
        label.text = self.fonts[indexPath.item];
        label.font = [OLKiteUtils fontWithName:label.text size:17];
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 3;
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView == self.colorsCollectionView){
        return CGSizeMake(collectionView.frame.size.width * 0.8, collectionView.frame.size.width * 0.8);
    }
    else if (collectionView == self.fontsCollectionView){
        return CGSizeMake(collectionView.frame.size.width, collectionView.frame.size.width/2);
    }
    
    return CGSizeZero;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView == self.colorsCollectionView){
        for (UITextField *textField in self.textFields){
            if ([textField isFirstResponder]){
                [textField setTextColor:self.availableColors[indexPath.item]];
                self.doneButton.enabled = YES;
                break;
            }
        }
        [collectionView reloadData];
    }
    else if (collectionView == self.fontsCollectionView){
        for (UITextField *textField in self.textFields){
            if ([textField isFirstResponder]){
                [textField setFont:[OLKiteUtils fontWithName:self.fonts[indexPath.item] size:30]];
                self.doneButton.enabled = YES;
                break;
            }
        }
    }
}

#pragma mark Keyboard Notifications

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification{
    NSDictionary *info = [aNotification userInfo];
    NSNumber *durationNumber = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curveNumber = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    [UIView animateWithDuration:[durationNumber doubleValue] delay:0 options:[curveNumber unsignedIntegerValue] animations:^{
        self.textToolsToolbar.transform = CGAffineTransformIdentity;
    }completion:NULL];
    
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification{
    NSDictionary *info = [aNotification userInfo];
    NSNumber *durationNumber = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curveNumber = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    self.colorsTrailingCon.constant = -self.colorsView.frame.size.width;
    self.fontsLeadingCon.constant = -self.fontsView.frame.size.width;
    [UIView animateWithDuration:[durationNumber doubleValue] delay:0 options:[curveNumber unsignedIntegerValue] animations:^{
        [self.view layoutIfNeeded];
        
        self.textToolsToolbar.transform = CGAffineTransformMakeTranslation(0, -self.textToolsToolbar.frame.origin.x - self.textToolsToolbar.frame.size.height - [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height);
        
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
    
    self.colorsViewBottomCon.constant = keyboardHeight;
    self.fontsCollectionViewBottomCon.constant = keyboardHeight;
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

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    [(OLPhotoTextField *)textField updateSize];
    
    self.doneButton.enabled = YES;
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [(OLPhotoTextField *)textField updateSize];
    if (!textField.text || [textField.text isEqualToString:@""]){
        [textField removeFromSuperview];
        [self.textFields removeObjectIdenticalTo:(OLPhotoTextField *)textField];
    }
}

- (void)photoTextFieldDidSendActionTouchUpInsideForX:(OLPhotoTextField *)textField{
    [textField removeFromSuperview];
    [self.textFields removeObjectIdenticalTo:textField];
}

#pragma mark - RMImageCropperDelegate methods

- (void)imageCropperDidTransformImage:(RMImageCropper *)imageCropper {
    self.doneButton.enabled = YES;
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 80000
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
#endif

@end
