//
//  OLPostcardViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/7/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPostcardViewController.h"
#import "OLAsset+Private.h"
#import "OLPostcardPrintJob.h"

@interface OLSingleImageProductReviewViewController (Private)

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet RMImageCropper *imageCropView;

@end

@interface OLPostcardViewController ()

@property (strong, nonatomic) UIView *postcardBackView;
@property (assign, nonatomic) BOOL showingBack;

@end

@interface OLKitePrintSDK (InternalUtils)
+ (NSString *)userEmail:(UIViewController *)topVC;
+ (NSString *)userPhone:(UIViewController *)topVC;
+ (id<OLKiteDelegate>)kiteDelegate:(UIViewController *)topVC;
+ (void)checkoutViewControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(OLCheckoutViewController *vc))handler;
@end

@implementation OLPostcardViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.postcardBackView = [[NSBundle mainBundle] loadNibNamed:@"PostcardBackView" owner:nil options:nil].firstObject;
    self.postcardBackView.backgroundColor = [UIColor blackColor];
    [self.containerView addSubview:self.postcardBackView];
    self.postcardBackView.hidden = YES;
    
    self.containerView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.containerView.layer.shadowOpacity = .3;
    self.containerView.layer.shadowOffset = CGSizeMake(-4,3);
    self.containerView.layer.shadowRadius = 2;

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
    }completion:^(BOOL finished){
        
    }];
}

-(void) doCheckout{
    if (!self.imageCropView.image) {
        return;
    }
    
    UIImage *croppedImage = self.imageCropView.editedImage;
    
    OLAsset *asset = [OLAsset assetWithImageAsJPEG:croppedImage];
    
    [asset dataLengthWithCompletionHandler:^(long long dataLength, NSError *error){
        if (dataLength < 40000){
            if ([UIAlertController class]){
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Image Is Too Small", @"") message:NSLocalizedString(@"Please zoom out or pick a higher quality image", @"") preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:NULL]];
                [self presentViewController:alert animated:YES completion:NULL];
            }
            else{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Image Too Small", @"") message:NSLocalizedString(@"Please zoom out or pick higher quality image", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil] show];
            }
        }
        else{
            
            
            NSUInteger iphonePhotoCount = 1;
            OLPostcardPrintJob *job = [[OLPostcardPrintJob alloc] initWithTemplateId:self.product.templateId frontImageOLAsset:asset message:@" " address:nil];
            OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
            NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
            NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
            NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
            printOrder.userData = @{@"photo_count_iphone": [NSNumber numberWithUnsignedInteger:iphonePhotoCount],
                                    @"sdk_version": kOLKiteSDKVersion,
                                    @"platform": @"iOS",
                                    @"uid": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                    @"app_version": [NSString stringWithFormat:@"Version: %@ (%@)", appVersion, buildNumber]
                                    };
            [printOrder addPrintJob:job];
            
            [OLKitePrintSDK checkoutViewControllerForPrintOrder:printOrder handler:^(OLCheckoutViewController *vc){
                vc.userEmail = [OLKitePrintSDK userEmail:self];
                vc.userPhone = [OLKitePrintSDK userPhone:self];
                vc.kiteDelegate = [OLKitePrintSDK kiteDelegate:self];
                
                [self.navigationController pushViewController:vc animated:YES];
            }];
        }
    }];
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

- (NSUInteger)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
