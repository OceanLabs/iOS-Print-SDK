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
#import "OLAsset.h"
#import "OLKiteUtils.h"
#import "OLImageRenderOptions.h"
#import "UIImageView+FadeIn.h"

@interface OLPromoView ()
@property (strong, nonatomic) NSArray <OLAsset *>*assets;
@property (strong, nonatomic) NSArray <NSString *>*templates;

@property (strong, nonatomic) UIImageView *imageView;
@end

@interface OLAsset ()
- (void)uploadToKiteWithProgress:(void(^)(float progress, float total))progressHandler completionHandler:(void(^)(NSError *error))handler;
- (NSURL *)imageRenderURLWithOptions:(OLImageRenderOptions *)options;
@end

@implementation OLPromoView

- (instancetype)init{
    if (self = [super init]){
        UIImageView *imageView = [[UIImageView alloc] init];
        self.imageView = imageView;
        [self addSubview:self.imageView];
        
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
    
    return self;
}

- (NSString *)tagline{
    if (!_tagline){
        return NSLocalizedStringFromTableInBundle(@"", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    }
    
    return _tagline;
}

- (void)prepareRendersWithCompletionHandler:(void(^)(NSError *error))handler{
    if (self.assets.count == 0 || self.templates.count == 0){
        return;
    }
    
    [self.assets.firstObject uploadToKiteWithProgress:NULL completionHandler:^(NSError *error){
        if (error){
            handler(error);
        }
        
        OLImageRenderOptions *options = [[OLImageRenderOptions alloc] init];
        options.productId = self.templates.firstObject;
        options.variant = @"cover";
        NSURL *url = [self.assets.firstObject imageRenderURLWithOptions:options];
        [self.imageView setAndFadeInImageWithURL:url size:CGSizeMake(320, 100) placeholder:nil progress:NULL completionHandler:^{
            if (handler){
                handler(nil);
            }
        }];
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

@end
