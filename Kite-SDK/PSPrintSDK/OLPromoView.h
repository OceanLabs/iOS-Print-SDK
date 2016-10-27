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

#import <UIKit/UIKit.h>
@class OLAsset;
@class OLPromoView;

@protocol OLPromoViewDelegate <NSObject>
- (void)promoViewDidFinish:(OLPromoView * _Nonnull )promoView;
@end

@interface OLPromoView : UIView

/**
 Request a promo view to be returned asyncronously when it's ready.

 @param assets The assets to use to generate the previews
 @param templates The product templates to generate the previews
 @param handler Completion handler with the promo view
 */
+ (void)requestPromoViewWithAssets:(NSArray <OLAsset *>*_Nonnull)assets templates:(NSArray <NSString *>*_Nullable)templates completionHandler:(void(^ _Nonnull)(OLPromoView *_Nullable promoView, NSError *_Nullable error))handler;


/**
 Request a promo view to be returned immediately. Previews will start loading when the view is shown.

 @param assets The assets to use to generate the previews
 @param templates The product templates to generate the previews
 @return Completion handler with the promo view
 */
+ (OLPromoView *_Nonnull)promoViewWithAssets:(NSArray <OLAsset *>*_Nonnull)assets templates:(NSArray <NSString *>*_Nullable)templates;


/**
 Label that shows the lagline on the promo view
 */
@property (strong, nonatomic) UILabel *_Nullable label;


/**
 The dimiss button.
 */
@property (strong, nonatomic) UIButton *_Nullable button;


/**
 Delegate to be notified when the user taps on the X button to dismiss. The dimissal needs to be handled in the delegate.
 */
@property (weak, nonatomic) id<OLPromoViewDelegate> _Nullable delegate;

@end
