//
//  OLPostcardViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/7/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
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
