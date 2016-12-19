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


#import "OLProductOverviewPageAnimatedContentViewController.h"
#import "OLProductOverviewPageContentViewController.h"
@import AVKit;
@import AVFoundation;

@interface OLProductOverviewPageAnimatedContentViewController ()
@property (strong, nonatomic) AVPlayerViewController *playerViewController;
@end

@implementation OLProductOverviewPageAnimatedContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.playerViewController = [[AVPlayerViewController alloc] init];
    self.playerViewController.player = [AVPlayer playerWithURL:[NSURL URLWithString:self.product.productTemplate.productPhotographyURLs[self.pageIndex % [self.product.productTemplate.productPhotographyURLs count]]]];
    self.playerViewController.showsPlaybackControls = NO;
    [self.playerViewController.player play];
    self.playerViewController.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerViewController.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    self.playerViewController.view.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.playerViewController.player currentItem]];
    
    [self addChildViewController:self.playerViewController];
    [self.view addSubview:self.playerViewController.view];
    UIView *view = self.playerViewController.view;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    UIView *gestureView = [[UIView alloc] init];
    [self.view addSubview:gestureView];
    gestureView.translatesAutoresizingMaskIntoConstraints = NO;
    views = NSDictionaryOfVariableBindings(gestureView);
    con = [[NSMutableArray alloc] init];
    
    visuals = @[@"H:|-0-[gestureView]-0-|",
                         @"V:|-0-[gestureView]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [gestureView.superview addConstraints:con];
    [gestureView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapOnImage:)]];

}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

- (void)userDidTapOnImage:(UITapGestureRecognizer *)sender {
    if ([(id<OLProductOverviewPageContentViewControllerDelegate>)self.delegate respondsToSelector:@selector(userDidTapOnImage)]){
        [(id<OLProductOverviewPageContentViewControllerDelegate>)self.delegate userDidTapOnImage];
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
