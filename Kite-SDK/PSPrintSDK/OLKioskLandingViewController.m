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
#import "OLKioskLandingViewController.h"
#import "UIView+AutoLayoutHelper.h"
#import "OLProductHomeViewController.h"
#import "OLUserSession.h"
#import "OLKiteUtils.h"
#import "OLKiteABTesting.h"
#import "OLImageDownloader.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIImage+OLUtils.h"

@interface OLKiteViewController ()
- (void)startTimer;
- (void)stopTimer;
@end

@interface OLKioskLandingViewController ()
@property (strong, nonatomic) UIImageView *imageView;
@end

@implementation OLKioskLandingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    [self.imageView fillSuperView];
    
    [self pickBestImageForSize:self.view.frame.size];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
    [self.imageView addGestureRecognizer:tap];
    self.imageView.userInteractionEnabled = YES;    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.alpha = 0;
    [[OLUserSession currentSession].kiteVc stopTimer];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [UIView animateWithDuration:0.15 animations:^{
        self.navigationController.navigationBar.alpha = 1;
    }];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id context){
        [self pickBestImageForSize:size];
    }completion:NULL];
}

- (void)pickBestImageForSize:(CGSize)size{
    if (size.width > size.height){
        if ([OLKiteABTesting sharedInstance].theme.startScreenLandscape){
            [[OLImageDownloader sharedInstance] downloadImageAtURL:[OLKiteABTesting sharedInstance].theme.startScreenLandscape withCompletionHandler:^(UIImage *image, NSError *error){
                self.imageView.image = [UIImage imageWithCGImage:image.CGImage scale:2.0 orientation:UIImageOrientationUp];
                self.imageView.backgroundColor = [self.imageView.image colorAtPixel:CGPointMake(3, 3)];
            }];
        }
        else{
            self.imageView.image = [UIImage imageNamedInKiteBundle:@"kiosk-landing-landscape"];
            self.imageView.backgroundColor = [self.imageView.image colorAtPixel:CGPointMake(3, 3)];
        }
    }
    else{
        if ([OLKiteABTesting sharedInstance].theme.startScreenPortrait){
            [[OLImageDownloader sharedInstance] downloadImageAtURL:[OLKiteABTesting sharedInstance].theme.startScreenPortrait withCompletionHandler:^(UIImage *image, NSError *error){
                self.imageView.image = [UIImage imageWithCGImage:image.CGImage scale:2.0 orientation:UIImageOrientationUp];
                self.imageView.backgroundColor = [self.imageView.image colorAtPixel:CGPointMake(3, 3)];
            }];
        }
        else{
            self.imageView.image = [UIImage imageNamedInKiteBundle:@"kiosk-landing-portrait"];
            self.imageView.backgroundColor = [self.imageView.image colorAtPixel:CGPointMake(3, 3)];
        }
    }
}

- (void)tapGestureRecognized:(UITapGestureRecognizer *)sender{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ProductHomeViewController"];
    [self.navigationController pushViewController:vc animated:YES];
    
    [[OLUserSession currentSession].kiteVc startTimer];
}


@end
