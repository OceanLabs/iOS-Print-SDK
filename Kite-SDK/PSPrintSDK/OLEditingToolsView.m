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

#import "OLEditingToolsView.h"
#import "OLKiteUtils.h"
#import "OLUserSession.h"

@implementation OLEditingToolsView

- (void)setColor:(UIColor *)color{
    self.button1.effectColor = color;
    self.button2.effectColor = color;
    self.button3.effectColor = color;
    self.button4.effectColor = color;
    [self.ctaButton setBackgroundColor:color];
}

- (id)initWithFrame:(CGRect)frame{
    if ((self = [super initWithFrame:frame])){
        UIView *view = [[[OLKiteUtils kiteResourcesBundle] loadNibNamed:@"OLEditingToolsView"
                                                      owner:self
                                                    options:nil] objectAtIndex:0];
        view.frame = self.bounds;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:view];
        
        [self.collectionView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)]];
        
        [self.drawerDoneButton setTitle:NSLocalizedStringFromTableInBundle(@"Done", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
        [self.halfWidthDrawerDoneButton setTitle:NSLocalizedStringFromTableInBundle(@"Done", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
        [self.halfWidthDrawerCancelButton setTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
        
        if ([OLUserSession currentSession].capitalizeCtaTitles){
            [self.drawerDoneButton setTitle:[[self.drawerDoneButton titleForState:UIControlStateNormal] uppercaseString] forState:UIControlStateNormal];
            [self.halfWidthDrawerDoneButton setTitle:[[self.halfWidthDrawerDoneButton titleForState:UIControlStateNormal] uppercaseString] forState:UIControlStateNormal];
            [self.halfWidthDrawerCancelButton setTitle:[[self.halfWidthDrawerCancelButton titleForState:UIControlStateNormal] uppercaseString] forState:UIControlStateNormal];
        }
    }
    return self;
}

- (void)tapGestureRecognizer:(id)sender{
    //Do nothing for now
}

- (NSArray *)buttons{
    NSMutableArray *buttons = [[NSMutableArray alloc] init];
    if (self.button1){
        [buttons addObject:self.button1];
    }
    if (self.button2){
        [buttons addObject:self.button2];
    }
    if (self.button3){
        [buttons addObject:self.button3];
    }
    if (self.button4){
        [buttons addObject:self.button4];
    }
    
    return buttons;
}

@end
