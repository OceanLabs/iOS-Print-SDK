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
#import "OLDragAndDropHelper.h"

@interface OLArtboardView () <UIGestureRecognizerDelegate, OLImageEditViewControllerDelegate, OLImagePickerViewControllerDelegate, UIDragInteractionDelegate, UIDropInteractionDelegate>
@property (strong, nonatomic) NSTimer *scrollingTimer;
@property (strong, nonatomic) UIView *draggingView;
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
    if ([OLDragAndDropHelper sharedInstance].targetAssetView && [OLDragAndDropHelper sharedInstance].targetAssetView != targetAssetView){
        [OLDragAndDropHelper sharedInstance].targetAssetView.targeted = NO;
    }
    [OLDragAndDropHelper sharedInstance].targetAssetView = targetAssetView;
}

- (void)setSourceAssetView:(OLArtboardAssetView *)sourceAssetView{
    [OLDragAndDropHelper sharedInstance].sourceAssetView = sourceAssetView;
    UIView *view = [self.delegate viewToAddDraggingAsset];
    if ([self.delegate respondsToSelector:@selector(scrollViewForVerticalScolling)]){
        view = [self.delegate scrollViewForVerticalScolling];
    }
    [OLDragAndDropHelper sharedInstance].sourceAssetViewRect = [view convertRect:sourceAssetView.frame fromView:sourceAssetView.superview];
    [OLDragAndDropHelper sharedInstance].sourceAssetIndex = sourceAssetView.index;
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
    
    if (@available(iOS 11.0, *)) {
        UIDragInteraction *dragInteraction = [[UIDragInteraction alloc] initWithDelegate:self];
        [view addInteraction:dragInteraction];
        
        UIDropInteraction *dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
        [view addInteraction:dropInteraction];
    }
    else {
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        longPressGesture.delegate = self;
        [view addGestureRecognizer:longPressGesture];
    }
    
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
    if (targetView != [OLDragAndDropHelper sharedInstance].sourceAssetView){
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
        swappingView.frame = [view convertRect:[OLDragAndDropHelper sharedInstance].sourceAssetViewRect toView:[self.delegate viewToAddDraggingAsset]];
    } completion:^(BOOL finished){
        if ([OLDragAndDropHelper sharedInstance].sourceAssetIndex == [OLDragAndDropHelper sharedInstance].sourceAssetView.index){
            [OLDragAndDropHelper sharedInstance].sourceAssetView.image = swappingView.image;
            [OLDragAndDropHelper sharedInstance].sourceAssetView.imageView.contentMode = [[OLAsset userSelectedAssets][targetView.index] isKindOfClass:[OLPlaceholderAsset class]] ? UIViewContentModeCenter : UIViewContentModeScaleAspectFill;
        }
        if (![OLDragAndDropHelper sharedInstance].targetAssetView){
            self.targetAssetView = [OLDragAndDropHelper sharedInstance].sourceAssetView;
        }
        [OLDragAndDropHelper sharedInstance].targetAssetView.image = [self.draggingView.subviews.firstObject image];
        [OLDragAndDropHelper sharedInstance].targetAssetView.imageView.contentMode = [[OLAsset userSelectedAssets][[OLDragAndDropHelper sharedInstance].sourceAssetIndex] isKindOfClass:[OLPlaceholderAsset class]] ? UIViewContentModeCenter : UIViewContentModeScaleAspectFill;
        self.targetAssetView = nil;
        
        [[OLAsset userSelectedAssets] exchangeObjectAtIndex:[OLDragAndDropHelper sharedInstance].sourceAssetIndex withObjectAtIndex:targetView.index];
        
        [self.draggingView removeFromSuperview];
        [swappingView removeFromSuperview];
        [OLDragAndDropHelper sharedInstance].sourceAssetView.dragging = NO;
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
        OLArtboardAssetView *target = [OLDragAndDropHelper sharedInstance].targetAssetView;
        if (!target){
            target = [OLDragAndDropHelper sharedInstance].sourceAssetView;
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
        OLImagePickerViewController *imagePicker = [[OLUserSession currentSession].kiteVc.storyboard instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
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
            }        [customVc safePerformSelector:@selector(setDelegate:) withObject:vc];
            [customVc safePerformSelector:@selector(setProductId:) withObject:product.templateId];
            [customVc safePerformSelector:@selector(setSelectedAssets:) withObject:[[NSMutableArray alloc] init]];
            if ([vc respondsToSelector:@selector(setMaximumPhotos:)] && [self.delegate respondsToSelector:@selector(maxNumberOfPhotosToPick)]){
                imagePicker.maximumPhotos = imagePicker.maximumPhotos;
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
            [cropVc setFullImage:image];
            cropVc.edits = asset.edits;
            
            [vc presentViewController:cropVc animated:NO completion:NULL];
            
#ifndef OL_NO_ANALYTICS
            [OLAnalytics trackEditPhotoTappedForProductName:product.productTemplate.name];
#endif
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

#pragma mark - OLImageEditViewController delegate

- (void)imageEditViewControllerDidCancel:(OLImageEditViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imageEditViewControllerDidDropChanges:(OLImageEditViewController *)cropper{
    [cropper dismissViewControllerAnimated:NO completion:NULL];
}

- (void)imageEditViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    OLAsset *asset = [OLAsset userSelectedAssets][[OLDragAndDropHelper sharedInstance].sourceAssetView.index];
    [asset unloadImage];
    asset.edits = cropper.edits;

    [[OLDragAndDropHelper sharedInstance].sourceAssetView loadImageWithCompletionHandler:NULL];
    
    [cropper dismissViewControllerAnimated:YES completion:NULL];
    
#ifndef OL_NO_ANALYTICS
    UIViewController *vc = [self.delegate viewControllerForPresenting];
    OLProduct *product = [vc safePerformSelectorWithReturn:@selector(product) withObject:nil];
    [OLAnalytics trackEditScreenFinishedEditingPhotoForProductName:product.productTemplate.name];
#endif
}

- (void)imageEditViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset{
    [[OLAsset userSelectedAssets] replaceObjectAtIndex:[OLDragAndDropHelper sharedInstance].sourceAssetView.index withObject:asset];
    [[OLDragAndDropHelper sharedInstance].sourceAssetView loadImageWithCompletionHandler:NULL];
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
    NSIndexSet *changedIndexes = [[OLAsset userSelectedAssets] updateUserSelectedAssetsAtIndex:[OLDragAndDropHelper sharedInstance].sourceAssetView.index withAddedAssets:addedAssets removedAssets:removedAssets];
    
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

#pragma mark Drag & Drop delegates

- (nonnull NSArray<UIDragItem *> *) dragInteraction:(nonnull UIDragInteraction *)interaction itemsForBeginningSession:(nonnull id<UIDragSession>)session {
    
    self.sourceAssetView = interaction.view;
    OLAsset *asset = [OLAsset userSelectedAssets][[(OLArtboardAssetView *)interaction.view index]];
    NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:asset typeIdentifier:@"ly.kite.olasset"];
    UIDragItem *dragItem = [[UIDragItem alloc] initWithItemProvider:itemProvider];
    return @[dragItem];
}

- (void)dragInteraction:(UIDragInteraction *)interaction willAnimateLiftWithAnimator:(id<UIDragAnimating>)animator session:(id<UIDragSession>)session{
    OLArtboardAssetView *view = interaction.view;
    [animator addCompletion:^(UIViewAnimatingPosition position){
        view.image = nil;
    }];
}

- (void)dragInteraction:(UIDragInteraction *)interaction item:(UIDragItem *)item willAnimateCancelWithAnimator:(id<UIDragAnimating>)animator{
    [animator addCompletion:^(UIViewAnimatingPosition position){
        [[OLDragAndDropHelper sharedInstance].sourceAssetView loadImageWithCompletionHandler:NULL];
    }];
}

//- (UITargetedDragPreview *)dragInteraction:(UIDragInteraction *)interaction previewForCancellingItem:(UIDragItem *)item withDefault:(UITargetedDragPreview *)defaultPreview{
//    return [[UITargetedDragPreview alloc] initWithView:interaction.view];
//}

- (BOOL) dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session{
    return [session hasItemsConformingToTypeIdentifiers:@[@"ly.kite.olasset"]];
}

- (void)dragInteraction:(UIDragInteraction *)interaction sessionDidMove:(id<UIDragSession>)session{
    OLArtboardAssetView *view = [OLDragAndDropHelper sharedInstance].targetAssetView;
    if (view){
        CGPoint dropLocation = [session locationInView:view];
        if (!CGRectContainsPoint(view.frame, dropLocation)){
            view.targeted = NO;
        }
    }
}

- (UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session{
    UIDropOperation operation = UIDropOperationCancel;
    
    for (OLArtboardAssetView *view in self.assetViews){
        CGPoint dropLocation = [session locationInView:self];
        if (CGRectContainsPoint(view.frame, dropLocation)){
            self.targetAssetView = view;
            if (view != [OLDragAndDropHelper sharedInstance].sourceAssetView){
                view.targeted = YES;
            }
            
            operation = session.localDragSession == nil ? UIDropOperationCopy : UIDropOperationMove;
            break;
        }
    }
    
    if (@available(iOS 11.0, *)) {
        return [[UIDropProposal alloc] initWithDropOperation:operation];
    } else {
        return nil;
    }
}

- (void)dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session{
    NSItemProvider *itemProvider = session.items.firstObject.itemProvider;
    [itemProvider loadItemForTypeIdentifier:@"ly.kite.olasset" options:nil completionHandler:^(id item, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            OLAsset *asset = item;
            
            OLArtboardAssetView *destAssetView = interaction.view;
            NSUInteger sourceIndex = [[OLAsset userSelectedAssets] indexOfObject:asset];
            
            [[OLAsset userSelectedAssets] exchangeObjectAtIndex:destAssetView.index withObjectAtIndex:sourceIndex];
            [destAssetView loadImageWithCompletionHandler:NULL];
        });
    }];
    
}

- (UITargetedDragPreview *)dropInteraction:(UIDropInteraction *)interaction previewForDroppingItem:(UIDragItem *)item withDefault:(UITargetedDragPreview *)defaultPreview{
    return [[UITargetedDragPreview alloc] initWithView:interaction.view];
}

- (void)dropInteraction:(UIDropInteraction *)interaction item:(UIDragItem *)item willAnimateDropWithAnimator:(id<UIDragAnimating>)animator{
    OLArtboardAssetView *destAssetView = interaction.view;
    destAssetView.targeted = NO;
    
    UIImageView *swappingView;
    if (destAssetView != [OLDragAndDropHelper sharedInstance].sourceAssetView){
        swappingView = [[UIImageView alloc] initWithImage:destAssetView.imageView.image];
        swappingView.contentMode = [[OLAsset userSelectedAssets][destAssetView.index] isKindOfClass:[OLPlaceholderAsset class]] ? UIViewContentModeCenter : UIViewContentModeScaleAspectFill;
        swappingView.clipsToBounds = YES;
        UIView *viewToAddDraggingAsset = [self.delegate viewToAddDraggingAsset];
        [viewToAddDraggingAsset addSubview:swappingView];
        swappingView.frame = [viewToAddDraggingAsset convertRect:destAssetView.frame fromView:destAssetView.superview];
    }
    [animator addAnimations:^{
        UIView *view = [self.delegate viewToAddDraggingAsset];
        if ([self.delegate respondsToSelector:@selector(scrollViewForVerticalScolling)]){
            view = [self.delegate scrollViewForVerticalScolling];
        }
        swappingView.frame = [view convertRect:[OLDragAndDropHelper sharedInstance].sourceAssetViewRect toView:[self.delegate viewToAddDraggingAsset]];
    }];
    [animator addCompletion:^(UIViewAnimatingPosition position){
        if ([OLDragAndDropHelper sharedInstance].sourceAssetIndex == [OLDragAndDropHelper sharedInstance].sourceAssetView.index){
            [OLDragAndDropHelper sharedInstance].sourceAssetView.image = swappingView.image;
        }
        if (![OLDragAndDropHelper sharedInstance].targetAssetView){
            self.targetAssetView = [OLDragAndDropHelper sharedInstance].sourceAssetView;
        }
        
        [destAssetView loadImageWithCompletionHandler:NULL];
        [[OLDragAndDropHelper sharedInstance].sourceAssetView loadImageWithCompletionHandler:NULL];
        
        [swappingView removeFromSuperview];
        self.sourceAssetView = nil;
    }];
}

@end
