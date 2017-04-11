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
#import "OLAsset.h"

@interface OLArtboardView ()
@end

@implementation OLArtboardView

- (void)setImage:(UIImage *)image{
    self.assetViews.firstObject.image = image;
}

-(NSMutableArray *) assetViews{
    if (!_assetViews){
        _assetViews = [[NSMutableArray alloc] init];
    }
    
    if (_assetViews.count == 0){
        [self addAssetViewWithRelativeFrame:CGRectMake(0, 0, 1, 1) index:0];
    }
    
    return _assetViews;
}

- (instancetype)init{
    if (self = [super init]){
        self.backgroundColor = [UIColor whiteColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return self;
}

- (void)layoutSubviews{
    for (OLArtboardAssetView *view in self.assetViews){
        view.frame = CGRectMake(view.relativeFrame.origin.x * self.frame.size.width, view.relativeFrame.origin.y * self.frame.size.height, view.relativeFrame.size.width * self.frame.size.width, view.relativeFrame.size.height * self.frame.size.height);
    }
}

- (void)addAssetViewWithRelativeFrame:(CGRect)frame index:(NSUInteger)index{
    OLArtboardAssetView *view = [[OLArtboardAssetView alloc] init];
    view.contentMode = UIViewContentModeScaleAspectFill;
    view.clipsToBounds = YES;
    [view setGesturesEnabled:NO];
    [self addSubview:view];
    [_assetViews addObject:view];
    
    view.index = index;
    view.relativeFrame = frame;
}

@end
