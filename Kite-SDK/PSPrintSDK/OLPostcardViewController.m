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

#import "OLPostcardViewController.h"
#import "OLRemoteImageCropper.h"

@interface OLSingleImageProductReviewViewController (Private)

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet OLRemoteImageCropper *imageCropView;

@end

@interface OLPostcardViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *shadowView;
@property (strong, nonatomic) UIView *postcardBackView;
@property (assign, nonatomic) BOOL showingBack;

@end

@implementation OLPostcardViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.postcardBackView = [[NSBundle mainBundle] loadNibNamed:@"PostcardBackView" owner:nil options:nil].firstObject;
    self.postcardBackView.backgroundColor = [UIColor blackColor];
    [self.containerView addSubview:self.postcardBackView];
    self.postcardBackView.hidden = YES;
//    if (!self.navigationItem.rightBarButtonItem){
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
//                                                  initWithTitle:NSLocalizedString(@"Next", @"")
//                                                  style:UIBarButtonItemStylePlain
//                                                  target:self
//                                                  action:@selector(onButtonNextClicked)];
//    }
}

- (void)viewDidLayoutSubviews{
    self.postcardBackView.frame = self.imageCropView.frame;
}

- (IBAction)onButtonTurnClicked:(UIButton *)sender {
    [UIView transitionWithView:self.containerView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
        if (self.showingBack){
            self.showingBack = NO;
            self.postcardBackView.hidden = YES;
        }
        else{
            self.showingBack = YES;
            self.postcardBackView.hidden = NO;
        }
    }completion:NULL];
}

#pragma mark - Autorotate and Orientation Methods
// Currently here to disable landscape orientations and rotation on iOS 7. When support is dropped, these can be deleted.

- (BOOL)shouldAutorotate {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return YES;
    }
    else{
        return NO;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
