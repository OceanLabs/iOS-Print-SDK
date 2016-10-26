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

#import "OLPromoView.h"
#import "OLAsset+Private.h"
#import "OLKiteUtils.h"
#import "OLImageRenderOptions.h"
#import "UIImageView+FadeIn.h"
#import "UIImage+ImageNamedInKiteBundle.h"

@interface OLPromoView ()
@property (strong, nonatomic) NSArray <OLAsset *>*assets;
@property (strong, nonatomic) NSArray <NSString *>*templates;

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) UIButton *button;
@end

@interface OLAsset ()
- (void)uploadToKiteWithProgress:(void(^)(float progress, float total))progressHandler completionHandler:(void(^)(NSError *error))handler;
- (NSURL *)imageRenderURLWithOptions:(OLImageRenderOptions *)options;
@end

@implementation OLPromoView

- (instancetype)init{
    if (self = [super init]){
        [self setupSubviews];
    }
    
    return self;
}


- (void)setupSubviews{
    self.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [[UIButton alloc] init];
    self.button = button;
    [self addSubview:button];
    [button setImage:[UIImage imageNamedInKiteBundle:@"bigX"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = self.tagline;
    self.label = label;
    [self addSubview:label];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView = imageView;
    [self addSubview:self.imageView];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
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
    con = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeTop multiplier:1 constant:0];
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
    con = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    con.priority = UILayoutPriorityDefaultHigh;
    [self addConstraint:con];
    
    //Main-Super: Leading
    con = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
    [self addConstraint:con];
    
    //Main-Super: Trailing
    con = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
    [self addConstraint:con];
    
    //Main-Super: Bottom
    con = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    [self addConstraint:con];
    
    //Main: Height
    con = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100];
    [imageView addConstraint:con];
}

- (NSString *)tagline{
    if (!_tagline){
        return NSLocalizedStringFromTableInBundle(@"Great gifts for all the family", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    }
    
    return _tagline;
}

- (void)prepareRendersWithCompletionHandler:(void(^)(NSError *error))handler{
    if (self.assets.count == 0 || self.templates.count == 0){
        return;
    }
    
    if (self.assets.firstObject.assetType == kOLAssetTypeRemoteImageURL && !self.assets.firstObject.isEdited){
        [self downloadRenderedImageWithCompletionHandler:handler];
    }
    else{
        [self.assets.firstObject uploadToKiteWithProgress:NULL completionHandler:^(NSError *error){
            if (error){
                handler(error);
            }
            
            [self downloadRenderedImageWithCompletionHandler:handler];
        }];
    }
}

- (void) downloadRenderedImageWithCompletionHandler:(void(^)(NSError *error))handler{
    OLImageRenderOptions *options = [[OLImageRenderOptions alloc] init];
    options.productId = self.templates.firstObject;
    options.variant = @"cover";
    options.background = [UIColor clearColor];
    NSURL *url = [self.assets.firstObject imageRenderURLWithOptions:options];
    [self.imageView setAndFadeInImageWithURL:url size:self.frame.size placeholder:nil progress:NULL completionHandler:^{
        if (handler){
            handler(nil);
        }
    }];
}

+ (void)requestPromoViewWithAssets:(NSArray <OLAsset *>*_Nonnull)assets templates:(NSArray <NSString *>*_Nullable)templates completionHandler:(void(^ _Nonnull)(UIView *_Nullable promoView, NSError *_Nullable error))handler{
    OLPromoView *promoView = [[OLPromoView alloc] init];
    promoView.assets = assets;
    promoView.templates = templates;
    
    [promoView prepareRendersWithCompletionHandler:^(NSError *error){
        handler(promoView, error);
    }];
}

- (void)buttonAction:(UIButton *)sender{
    if ([self.delegate respondsToSelector:@selector(promoViewDidFinish:)]){
        [self.delegate promoViewDidFinish:self];
    }
}

@end
