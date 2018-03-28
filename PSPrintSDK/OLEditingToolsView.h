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

#import <UIKit/UIKit.h>
#import "OLSelectedEffectButton.h"
IB_DESIGNABLE
@interface OLEditingToolsView : UIView

@property (weak, nonatomic) IBOutlet OLSelectedEffectButton *button1;
@property (weak, nonatomic) IBOutlet OLSelectedEffectButton *button2;
@property (weak, nonatomic) IBOutlet OLSelectedEffectButton *button3;
@property (weak, nonatomic) IBOutlet OLSelectedEffectButton *button4;

@property (weak, nonatomic) IBOutlet UIButton *ctaButton;

@property (weak, nonatomic) IBOutlet UIView *drawerView;
@property (weak, nonatomic) IBOutlet UIButton *drawerDoneButton;
@property (weak, nonatomic) IBOutlet UIButton *halfWidthDrawerDoneButton;
@property (weak, nonatomic) IBOutlet UIButton *halfWidthDrawerCancelButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *drawerLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *drawerHeightCon;

- (void)setColor:(UIColor *)color;
- (NSArray *)buttons;


@end
