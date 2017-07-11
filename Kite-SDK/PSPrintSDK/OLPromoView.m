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

#import "OLPromoView.h"
#import "OLAsset+Private.h"
#import "OLKiteUtils.h"
#import "OLImageRenderOptions.h"
#import "UIImageView+FadeIn.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLImageDownloader.h"

@interface OLPromoView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (strong, nonatomic) NSArray <OLAsset *>*assets;
@property (strong, nonatomic) NSArray <NSString *>*templates;

@property (strong, nonatomic) UICollectionView *collectionView;

@property (assign, nonatomic) NSInteger numberOfRendersToDownloadBeforeReadyHandler;
@property (strong, nonatomic) NSError *error;
@end

@interface OLAsset ()
- (NSURL *)imageRenderURLWithOptions:(OLImageRenderOptions *)options;
@end

@implementation OLPromoView

+ (OLPromoView *)promoViewWithAssets:(NSArray <OLAsset *>*_Nonnull)assets templates:(NSArray <NSString *>*_Nullable)templates{
    NSAssert(assets.count != 0 && templates.count != 0, @"Please supply at least one asset and product to render.");
    
#ifdef DEBUG
    for (OLAsset *asset in assets){
        NSAssert(asset.assetType == kOLAssetTypeRemoteImageURL, @"Only URL assets are supported at this time.");
    }
#endif
    
    OLPromoView *promoView = [[OLPromoView alloc] initWithFrame:CGRectMake(0, 0, 200, 60)];
    promoView.assets = assets;
    promoView.templates = templates;
    
    promoView.numberOfRendersToDownloadBeforeReadyHandler = promoView.assets.count > 1 || promoView.templates.count > 1 ? 2 : 1;
    
    [promoView setupSubviews];
    
    return promoView;
}


+ (void)requestPromoViewWithAssets:(NSArray <OLAsset *>*_Nonnull)assets templates:(NSArray <NSString *>*_Nullable)templates completionHandler:(void(^ _Nonnull)(OLPromoView *_Nullable promoView, NSError *_Nullable error))handler{
    OLPromoView *promoView = [OLPromoView promoViewWithAssets:assets templates:templates];
    
    NSBlockOperation *readyHandlerOperation = [NSBlockOperation blockOperationWithBlock:^{
        handler(promoView, promoView.error);
    }];
    
    NSBlockOperation *downloadOperation0 = [[NSBlockOperation alloc] init];
    [readyHandlerOperation addDependency:downloadOperation0];
    [[OLImageDownloader sharedInstance] downloadDataAtURL:[promoView urlForAssetAtIndex:0] priority:0.8 progress:NULL withCompletionHandler:^(NSData *data, NSError *error){
        [[NSOperationQueue mainQueue] addOperation:downloadOperation0];
    }];
    
    if (promoView.numberOfRendersToDownloadBeforeReadyHandler > 1){
        NSBlockOperation *downloadOperation1 = [[NSBlockOperation alloc] init];
        [readyHandlerOperation addDependency:downloadOperation1];
        [[OLImageDownloader sharedInstance] downloadDataAtURL:[promoView urlForAssetAtIndex:1] priority:0.8 progress:NULL withCompletionHandler:^(NSData *data, NSError *error){
            [[NSOperationQueue mainQueue] addOperation:downloadOperation1];
        }];
    }
    
    [[NSOperationQueue mainQueue] addOperation:readyHandlerOperation];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView reloadData];
}

- (void)setupSubviews{    
    self.backgroundColor = [UIColor whiteColor];
    
    UICollectionView *main = [[UICollectionView alloc] initWithFrame:self.frame collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    main.dataSource = self;
    main.delegate = self;
    main.backgroundColor = [UIColor clearColor];
    [(UICollectionViewFlowLayout *)main.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    self.collectionView = main;
    [self addSubview:self.collectionView];
    main.translatesAutoresizingMaskIntoConstraints = NO;
    [main registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"imageCell"];
    
    UIButton *button = [[UIButton alloc] init];
    self.button = button;
    [self addSubview:button];
    [button setImage:[UIImage imageNamedInKiteBundle:@"bigX"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = OLLocalizedString(@"Great gifts for all the family", @"");
    self.label = label;
    [self addSubview:label];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    //Label-super: Top
    NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self addConstraint:con];
    
    //Label-super: Leading
    con = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:10];
    [self addConstraint:con];
    
    //Label: Height
    con = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40];
    [label addConstraint:con];
    
    //Label-Main: Vertical
    con = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:main attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    con.priority = UILayoutPriorityDefaultHigh;
    [self addConstraint:con];
    
    //Label-button: Horizontal
    con = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
    [self addConstraint:con];
    
    //Button-super: Trailing
    con = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:-10];
    [self addConstraint:con];
    
    //Button-super: Top
    con = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self addConstraint:con];
    
    //Button: Height
    con = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40];
    [button addConstraint:con];
    //Button: Width
    con = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40];
    [button addConstraint:con];
    
    //Buttom-Main: Vertical
    con = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:main attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    con.priority = UILayoutPriorityDefaultHigh;
    [self addConstraint:con];
    
    //Main-Super: Leading
    con = [NSLayoutConstraint constraintWithItem:main attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
    [self addConstraint:con];
    
    //Main-Super: Trailing
    con = [NSLayoutConstraint constraintWithItem:main attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
    [self addConstraint:con];
    
    //Main-Super: Bottom
    con = [NSLayoutConstraint constraintWithItem:main attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    [self addConstraint:con];
    
    //Main: Height
    con = [NSLayoutConstraint constraintWithItem:main attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100];
    [main addConstraint:con];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
    UIImageView *imageView = [cell viewWithTag:10];
    if (!imageView){
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] init];
        activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        activity.tag = 20;
        [cell.contentView addSubview:activity];
        activity.translatesAutoresizingMaskIntoConstraints = NO;
        [activity.superview addConstraint:[NSLayoutConstraint constraintWithItem:activity attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:activity.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [activity.superview addConstraint:[NSLayoutConstraint constraintWithItem:activity attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:activity.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        imageView = [[UIImageView alloc] init];
        imageView.tag = 10;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
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
    
    UIActivityIndicatorView *activity = [cell.contentView viewWithTag:20];
    if (![activity isKindOfClass:[UIActivityIndicatorView class]]){
        activity = nil;
    }
    [activity startAnimating];
    [imageView setAndFadeInImageWithURL:[self urlForAssetAtIndex:indexPath.item] size:collectionView.frame.size placeholder:nil progress:NULL completionHandler:^{
        [activity stopAnimating];
    }];
    
    return cell;
}

- (NSURL *)urlForAssetAtIndex:(NSInteger)index{
    OLImageRenderOptions *options = [[OLImageRenderOptions alloc] init];
    options.productId = self.templates[index % self.templates.count];
    options.variant = @"cover";
    options.background = [UIColor clearColor];
    OLAsset *asset = self.assets[index % self.assets.count];
    NSURL *url = [asset imageRenderURLWithOptions:options];
    return url;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return MAX(self.assets.count, self.templates.count);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat height = collectionView.frame.size.height;
    CGFloat width;
    NSInteger numberOfCells = [self collectionView:collectionView numberOfItemsInSection:indexPath.section];
    width = MAX(MIN(collectionView.frame.size.width / numberOfCells, height / .625), height / 0.86);
    return CGSizeMake(width, height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    CGFloat margin = MAX((collectionView.frame.size.width - ([self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]].width * [self collectionView:collectionView numberOfItemsInSection:section] + [self collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section] * ([self collectionView:collectionView numberOfItemsInSection:section]-1)))/2.0, 0);
    return UIEdgeInsetsMake(0, margin, 0, margin);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.delegate respondsToSelector:@selector(promoView:didSelectTemplateId:withAsset:)]){
        [self.delegate promoView:self didSelectTemplateId:self.templates[indexPath.item % self.templates.count] withAsset:self.assets[indexPath.item % self.assets.count]];
    }
}

- (void)buttonAction:(UIButton *)sender{
    if ([self.delegate respondsToSelector:@selector(promoViewDidFinish:)]){
        [self.delegate promoViewDidFinish:self];
    }
}

@end
