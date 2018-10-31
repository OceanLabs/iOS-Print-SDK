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
#import "OLArtboardView.h"
#import "UIView+AutoLayoutHelper.h"
#import "OLAsset+Private.h"
#import "OLImageEditViewController.h"
#import "OLProduct.h"
#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLImagePickerViewController.h"
#import "OLUserSession.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController+Private.h"
#import "OLCustomViewControllerPhotoProvider.h"
#import "OLNavigationController.h"
#import "OLCustomPickerController.h"

@interface OLArtboardView () <UIGestureRecognizerDelegate, OLImageEditViewControllerDelegate, OLImagePickerViewControllerDelegate>
@property (assign, nonatomic) CGRect sourceAssetViewRect;
@property (assign, nonatomic) NSUInteger sourceAssetIndex;
@property (strong, nonatomic) NSTimer *scrollingTimer;
@property (strong, nonatomic) UIView *draggingView;
@property (weak, nonatomic) OLArtboardAssetView *sourceAssetView;
@property (weak, nonatomic) OLArtboardAssetView *targetAssetView;
@property (strong, nonatomic) OLImagePickerViewController *vcDelegateForCustomVc;
@property (strong, nonatomic) UIViewController *presentedVc;
@end

@implementation OLArtboardView

- (void)setImage:(UIImage *)image{
    self.assetViews.firstObject.image = image;
}

- (NSMutableArray *) assetViews{
    if (!_assetViews){
        _assetViews = [[NSMutableArray alloc] init];
    }
    
    if (_assetViews.count == 0){
        [self addAssetViewWithRelativeFrame:CGRectMake(0, 0, 1, 1) index:0];
    }
    
    return _assetViews;
}

- (void)setTargetAssetView:(OLArtboardAssetView *)targetAssetView{
    if (_targetAssetView && _targetAssetView != targetAssetView){
        _targetAssetView.targeted = NO;
    }
    _targetAssetView = targetAssetView;
}

- (void)setSourceAssetView:(OLArtboardAssetView *)sourceAssetView{
    _sourceAssetView = sourceAssetView;
    UIView *view = [self.delegate viewToAddDraggingAsset];
    if ([self.delegate respondsToSelector:@selector(scrollViewForVerticalScolling)]){
        view = [self.delegate scrollViewForVerticalScolling];
    }
    self.sourceAssetViewRect = [view convertRect:sourceAssetView.frame fromView:sourceAssetView.superview];
    self.sourceAssetIndex = sourceAssetView.index;
}

- (instancetype)init{
    if (self = [super init]){
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return self;
}

- (void)layoutSubviews{
    for (OLArtboardAssetView *view in self.assetViews){
        if (!CGRectEqualToRect(view.relativeFrame, CGRectZero)){
            view.frame = CGRectMake(view.relativeFrame.origin.x * self.frame.size.width, view.relativeFrame.origin.y * self.frame.size.height, view.relativeFrame.size.width * self.frame.size.width, view.relativeFrame.size.height * self.frame.size.height);
        }
    }
}

- (void)addAssetView{
    [self addAssetViewWithRelativeFrame:CGRectZero index:0];
}

- (void)addAssetViewWithRelativeFrame:(CGRect)frame index:(NSUInteger)index{
    OLArtboardAssetView *view = [[OLArtboardAssetView alloc] init];
    view.backgroundColor = [UIColor colorWithWhite: 0.937 alpha: 1];
    view.contentMode = UIViewContentModeScaleAspectFill;
    view.clipsToBounds = YES;
    [view setGesturesEnabled:NO];
    [self addSubview:view];
    [_assetViews addObject:view];
    
    view.index = index;
    view.relativeFrame = frame;
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    longPressGesture.delegate = self;
    [view addGestureRecognizer:longPressGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.delegate = self;
    [view addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [view addGestureRecognizer:tapGesture];
}

- (void)pickUpView:(OLArtboardAssetView *)assetView{
    self.sourceAssetView = assetView;
    self.draggingView = [[UIView alloc] init];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:assetView.imageView.image];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    UIView *viewToAddDraggingAsset = [self.delegate viewToAddDraggingAsset];
    
    [self.draggingView addSubview:imageView];
    [viewToAddDraggingAsset addSubview:self.draggingView];
    self.draggingView.frame = [self convertRect:assetView.frame toView:viewToAddDraggingAsset];
    imageView.frame = CGRectMake(0, 0, self.draggingView.frame.size.width, self.draggingView.frame.size.height);
    
    [UIView animateWithDuration:0.15 animations:^{
        self.draggingView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        self.draggingView.layer.shadowRadius = 10;
        self.draggingView.layer.shadowOpacity = 0.5;
    } completion:^(BOOL finished){
        assetView.image = nil;
    }];
    
}

- (void)dropView:(UIView *)viewDropped onView:(OLArtboardAssetView *)targetView{
    UIImageView *swappingView;
    if (targetView != self.sourceAssetView){
        swappingView = [[UIImageView alloc] initWithImage:targetView.imageView.image];
        swappingView.contentMode = [[OLAsset userSelectedAssets][targetView.index] isKindOfClass:[OLPlaceholderAsset class]] ? UIViewContentModeCenter : UIViewContentModeScaleAspectFill;
        swappingView.clipsToBounds = YES;
        UIView *viewToAddDraggingAsset = [self.delegate viewToAddDraggingAsset];
        [viewToAddDraggingAsset insertSubview:swappingView belowSubview:self.draggingView];
        swappingView.frame = [viewToAddDraggingAsset convertRect:targetView.frame fromView:targetView.superview];
    }
    
    targetView.imageView.image = nil;
    [UIView animateWithDuration:0.25 animations:^{
        self.draggingView.transform = CGAffineTransformIdentity;
        self.draggingView.layer.shadowRadius = 0;
        self.draggingView.layer.shadowOpacity = 0.0;
        self.draggingView.frame = [[self.delegate viewToAddDraggingAsset] convertRect:targetView.frame fromView:targetView.superview];
        
        UIView *view = [self.delegate viewToAddDraggingAsset];
        if ([self.delegate respondsToSelector:@selector(scrollViewForVerticalScolling)]){
            view = [self.delegate scrollViewForVerticalScolling];
        }
        swappingView.frame = [view convertRect:self.sourceAssetViewRect toView:[self.delegate viewToAddDraggingAsset]];
    } completion:^(BOOL finished){
        if (self.sourceAssetIndex == self.sourceAssetView.index){
            self.sourceAssetView.image = swappingView.image;
            self.sourceAssetView.imageView.contentMode = [[OLAsset userSelectedAssets][targetView.index] isKindOfClass:[OLPlaceholderAsset class]] ? UIViewContentModeCenter : UIViewContentModeScaleAspectFill;
        }
        if (!self.targetAssetView){
            self.targetAssetView = self.sourceAssetView;
        }
        self.targetAssetView.image = [self.draggingView.subviews.firstObject image];
        self.targetAssetView.imageView.contentMode = [[OLAsset userSelectedAssets][self.sourceAssetIndex] isKindOfClass:[OLPlaceholderAsset class]] ? UIViewContentModeCenter : UIViewContentModeScaleAspectFill;
        self.targetAssetView = nil;
        
        [[OLAsset userSelectedAssets] exchangeObjectAtIndex:self.sourceAssetIndex withObjectAtIndex:targetView.index];
        
        [self.draggingView removeFromSuperview];
        [swappingView removeFromSuperview];
        self.sourceAssetView.dragging = NO;
        self.sourceAssetView = nil;
    }];
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender{
    if (sender.state == UIGestureRecognizerStateBegan){
        OLArtboardAssetView *assetView = (OLArtboardAssetView *)sender.view;
        if ([[OLAsset userSelectedAssets][assetView.index] isKindOfClass:[OLPlaceholderAsset class]]){
            return;
        }
        assetView.dragging = YES;
        [self pickUpView:assetView];
    }
    else if(sender.state == UIGestureRecognizerStateEnded){
        OLArtboardAssetView *target = self.targetAssetView;
        if (!target){
            target = self.sourceAssetView;
        }
        [self.scrollingTimer invalidate];
        self.scrollingTimer = nil;
        [self dropView:self.draggingView onView:target];
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender{
    if(sender.state == UIGestureRecognizerStateChanged){
        UIView *viewToAddDraggingAsset = [self.delegate viewToAddDraggingAsset];
        if (!viewToAddDraggingAsset){
            return;
        }
        CGPoint translation = [sender translationInView:viewToAddDraggingAsset];
        self.draggingView.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(translation.x, translation.y), 1.1, 1.1);
        
        OLArtboardAssetView *targetView = [self.delegate assetViewAtPoint:CGPointMake(self.draggingView.frame.origin.x + self.draggingView.frame.size.width/2.0, self.draggingView.frame.origin.y + self.draggingView.frame.size.height/2.0)];
        if (!targetView.targeted){
            [targetView setTargeted:YES];
            self.targetAssetView = targetView;
        }
        
        if (self.draggingView.frame.origin.y + self.draggingView.frame.size.height/2.0 > self.draggingView.superview.frame.size.height * 0.9){
            UIScrollView *scrollView;
            if ([self.delegate respondsToSelector:@selector(scrollViewForVerticalScolling)]){
                scrollView = [self.delegate scrollViewForVerticalScolling];
            }
            if (self.scrollingTimer || !scrollView){
                return;
            }
            self.scrollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 repeats:YES block:^(NSTimer *timer){
                if (scrollView.contentOffset.y - scrollView.contentInset.bottom + scrollView.frame.size.height + 6 < scrollView.contentSize.height){
                    scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, scrollView.contentOffset.y + 6);
                }
            }];
        }
        else if (self.draggingView.frame.origin.y + self.draggingView.frame.size.height/2.0 < self.draggingView.superview.frame.size.height * 0.1){
            UIScrollView *scrollView;
            if ([self.delegate respondsToSelector:@selector(scrollViewForVerticalScolling)]){
                scrollView = [self.delegate scrollViewForVerticalScolling];
            }
            if (self.scrollingTimer || !scrollView){
                return;
            }
            self.scrollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 repeats:YES block:^(NSTimer *timer){
                if (scrollView.contentOffset.y + scrollView.contentInset.top - 6 > 0){
                    scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, scrollView.contentOffset.y - 6);
                }
            }];
        }
        else{
            [self.scrollingTimer invalidate];
            self.scrollingTimer = nil;
        }
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender{
    UIViewController *vc = [self.delegate viewControllerForPresenting];
    if (!vc){
        return;
    }
    OLProduct *product = [vc safePerformSelectorWithReturn:@selector(product) withObject:nil];
    if (!product){
        return;
    }
    
    OLArtboardAssetView *assetView = (OLArtboardAssetView *)sender.view;
    self.sourceAssetView = assetView;
    OLAsset *asset = [OLAsset userSelectedAssets][assetView.index];
    if ([asset isKindOfClass:[OLPlaceholderAsset class]] || [OLUserSession currentSession].kiteVc.disableEditingTools){
        OLImagePickerViewController *imagePicker = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
        imagePicker.delegate = self;
        imagePicker.selectedAssets = [[[OLAsset userSelectedAssets] nonPlaceholderAssets] mutableCopy];;
        if ([self.delegate respondsToSelector:@selector(maxNumberOfPhotosToPick)]){
            imagePicker.maximumPhotos = [self.delegate maxNumberOfPhotosToPick];
        }
        imagePicker.product = product;
        
        if ([OLKiteUtils numberOfProvidersAvailable] <= 2 && [[OLUserSession currentSession].kiteVc.customImageProviders.firstObject isKindOfClass:[OLCustomViewControllerPhotoProvider class]]){
            //Skip the image picker and only show the custom vc
            
            self.vcDelegateForCustomVc = imagePicker; //Keep strong reference
            UIViewController<OLCustomPickerController> *customVc = [(OLCustomViewControllerPhotoProvider *)[OLUserSession currentSession].kiteVc.customImageProviders.firstObject vc];
            if (!customVc){
                customVc = [[OLUserSession currentSession].kiteVc.delegate imagePickerViewControllerForName:imagePicker.providerForPresentedVc.name];
            }
            [customVc safePerformSelector:@selector(setDelegate:) withObject:imagePicker];
            [customVc safePerformSelector:@selector(setProductId:) withObject:product.templateId];
            [customVc safePerformSelector:@selector(setSelectedAssets:) withObject:imagePicker.selectedAssets];
            if ([customVc respondsToSelector:@selector(setMaximumPhotos:)] && [self.delegate respondsToSelector:@selector(maxNumberOfPhotosToPick)]){
                customVc.maximumPhotos = imagePicker.maximumPhotos;
            }
            
            [vc presentViewController:customVc animated:YES completion:NULL];
            self.presentedVc = customVc;
            return;
        }
        else{
            [vc presentViewController:[[OLNavigationController alloc] initWithRootViewController:imagePicker] animated:YES completion:NULL];
        }
    }
    else{
        [asset imageWithSize:vc.view.frame.size applyEdits:NO progress:NULL completion:^(UIImage *image, NSError *error){
            [asset unloadImage];
            
            OLImageEditViewController *cropVc = [[OLImageEditViewController alloc] init];
            cropVc.borderInsets = product.productTemplate.imageBorder;
            cropVc.enableCircleMask = product.productTemplate.templateUI == OLTemplateUICircle;
            cropVc.delegate = self;
            cropVc.aspectRatio = assetView.frame.size.height / assetView.frame.size.width;
            cropVc.product = product;
            
            cropVc.previewView = [assetView snapshotViewAfterScreenUpdates:YES];
            cropVc.previewView.frame = [self convertRect:assetView.frame toView:nil];
            cropVc.previewSourceView = assetView;
            cropVc.providesPresentationContextTransitionStyle = true;
            cropVc.definesPresentationContext = true;
            cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            [cropVc setImage:image];
            cropVc.edits = asset.edits;
            cropVc.asset = asset;
            
            [vc presentViewController:cropVc animated:NO completion:NULL];
        }];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer{
    return otherGestureRecognizer.view == gestureRecognizer.view && [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]){
        if (![self.delegate respondsToSelector:@selector(assetViewAtPoint:)] || ![self.delegate respondsToSelector:@selector(viewToAddDraggingAsset)]){
            return NO;
        }
        UIView *viewToAddDraggingAsset = [self.delegate viewToAddDraggingAsset];
        if (!viewToAddDraggingAsset){
            return NO;
        }
        else{
            return YES;
        }
    }
    
    OLArtboardAssetView *assetView = (OLArtboardAssetView *)gestureRecognizer.view;
    if ([assetView isKindOfClass:[OLArtboardAssetView class]]){
        return assetView.dragging;
    }
    else{
        return YES;
    }
}

- (void)refreshAssetViewsWithIndexSet:(NSIndexSet *)indexSet{
    for (OLArtboardAssetView *assetView in self.assetViews){
        if ([indexSet containsIndex:assetView.index]){
            [assetView loadImageWithCompletionHandler:NULL];
        }
    }
}

- (void)loadImageOnAllAssetViews{
    for (OLArtboardAssetView *assetView in self.assetViews){
        [assetView loadImageWithCompletionHandler:NULL];
    }
}

- (OLArtboardAssetView *)findAssetViewAtPoint:(CGPoint)point{
    for (OLArtboardAssetView *assetView in self.assetViews){
        if (!assetView.dragging && CGRectContainsPoint(assetView.frame, [assetView.superview convertPoint:point fromView:[self.delegate viewToAddDraggingAsset]])){
            return assetView;
        }
    }
    
    return nil;
}

- (void)setupBottomBorderTextField{
    UIView *assetView = self.assetViews.firstObject;
    CGFloat heightFactor = self.frame.size.height / 212.0;
    UITextField *tf = [[UITextField alloc] init];
    tf.userInteractionEnabled = NO;
    tf.textAlignment = NSTextAlignmentCenter;
    tf.adjustsFontSizeToFitWidth = YES;
    tf.minimumFontSize = 1;
    tf.font = [UIFont fontWithName:@"HelveticaNeue" size:35 * heightFactor];
    tf.textColor = [UIColor blackColor];
    tf.tag = 1556;
    
    [self addSubview:tf];
    
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(tf, assetView);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-5-[tf]-5-|",
                         [NSString stringWithFormat:@"V:[assetView]-0-[tf]-0-|"]];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [tf.superview addConstraints:con];
}

#pragma mark - OLImageEditViewController delegate

- (void)imageEditViewControllerDidCancel:(OLImageEditViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imageEditViewControllerDidDropChanges:(OLImageEditViewController *)cropper{
    [cropper dismissViewControllerAnimated:NO completion:NULL];
}

- (void)imageEditViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    OLAsset *asset = [OLAsset userSelectedAssets][self.sourceAssetView.index];
    [asset unloadImage];
    asset.edits = cropper.edits;
    
    [[self viewWithTag:1556] removeFromSuperview];
    if (asset.edits.bottomBorderText.text){
        [self setupBottomBorderTextField];
        [(UITextView *)[self viewWithTag:1556] setText:asset.edits.bottomBorderText.text];
    }

    [self.sourceAssetView loadImageWithCompletionHandler:NULL];
    
    [cropper dismissViewControllerAnimated:YES completion:NULL];    
}

- (void)imageEditViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset{
    asset.extraCopies = [OLAsset userSelectedAssets][self.sourceAssetView.index].extraCopies;
    [OLAsset userSelectedAssets][self.sourceAssetView.index].extraCopies = 0;
    [[OLAsset userSelectedAssets] replaceObjectAtIndex:self.sourceAssetView.index withObject:asset];
    [self.sourceAssetView loadImageWithCompletionHandler:NULL];
}

#pragma mark OLImagePickerViewControllerDelegate

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
    NSIndexSet *changedIndexes = [[OLAsset userSelectedAssets] updateUserSelectedAssetsAtIndex:self.sourceAssetView.index withAddedAssets:addedAssets removedAssets:removedAssets];
    
    if ([self.delegate respondsToSelector:@selector(refreshAssetViewsWithIndexSet:)]){
        [self.delegate refreshAssetViewsWithIndexSet:changedIndexes];
    }
    else{
        [self refreshAssetViewsWithIndexSet:changedIndexes];
    }
    
    if (self.presentedVc){
        [self.presentedVc dismissViewControllerAnimated:YES completion:NULL];
    }
    else{
        [vc dismissViewControllerAnimated:YES completion:NULL];
    }
    
    self.vcDelegateForCustomVc = nil;
    self.presentedVc = nil;
}

@end
