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

#ifdef COCOAPODS
#import <DACircularProgress/DACircularProgressView.h>
#else
#import "DACircularProgressView.h"
#endif

#import "OLRemoteImageView.h"

@interface OLRemoteImageView ()

@property (strong, nonatomic) DACircularProgressView *loadingView;

@end

@implementation OLRemoteImageView

- (void)initializeViews{
    self.loadingView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    self.loadingView.innerTintColor = [UIColor lightGrayColor];
    self.loadingView.trackTintColor = [UIColor lightGrayColor];
    self.loadingView.progressTintColor = [UIColor whiteColor];
    self.loadingView.thicknessRatio = 1;
    self.loadingView.hidden = YES;
    
    [self addSubview:self.loadingView];
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [self initializeViews];
}

- (instancetype)init{
    self = [super init];
    if (self){
        [self initializeViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self){
        [self initializeViews];
    }
    return self;
}

- (void)setProgress:(float)progress{
    if (progress == 1 && self.loadingView.progress < 0.1){
        self.loadingView.hidden = YES;
        return;
    }
    
    if (progress == 0){
        progress = 0.05;
    }
    
    self.loadingView.hidden = NO;
    [self.loadingView setProgress:progress animated:YES];
    
    if (progress == 1){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.loadingView.hidden = YES;
        });
    }
}

@end
