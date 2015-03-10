//
//  OLSingleImageProductReviewViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 2/24/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLSingleImageProductReviewViewController.h"
#import "OLPrintPhoto.h"
#import "OLAnalytics.h"
#import "OLAsset+Private.h"
#import <SDWebImageManager.h>
#import "RMImageCropper.h"
#import "OLProductPrintJob.h"

@interface OLSingleImageProductReviewViewController ()

@property (weak, nonatomic) IBOutlet RMImageCropper *imageCropView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *maskAspectRatio;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *quantityLabel;
@property (assign, nonatomic) NSUInteger quantity;

@property (strong, nonatomic) UIImage *maskImage;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;


@end

@implementation OLSingleImageProductReviewViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
#endif
    
    OLPrintPhoto *printPhoto = (OLPrintPhoto *)[self.userSelectedPhotos firstObject];
    if ([(OLAsset *)printPhoto.asset assetType] == kOLAssetTypeRemoteImageURL){
        [[SDWebImageManager sharedManager] downloadImageWithURL:[((OLAsset *)printPhoto.asset) imageURL] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *url) {
            if (finished) {
                self.imageCropView.image = image;
            }
        }];
    }
    else{
        [printPhoto dataWithCompletionHandler:^(NSData *data, NSError *error){
            self.imageCropView.image = [UIImage imageWithData:data];
        }];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Next"
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(onButtonNextClicked)];
    [self setTitle:NSLocalizedString(@"Reposition the Photo", @"")];
    
    self.quantity = 1;
    [self updateQuantityLabel];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        
        self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        UIView *view = self.visualEffectView;
        [self.containerView addSubview:view];
        
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[view]-0-|",
                             @"V:|-0-[view]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
        
    }
    else{
        
    }
    
    UIImage *tempMask = [UIImage imageNamed:@"dummy mask"];
    [self.containerView removeConstraint:self.maskAspectRatio];
    NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeWidth multiplier:tempMask.size.height / tempMask.size.width constant:0];
    [self.containerView addConstraints:@[con]];
    self.maskAspectRatio = con;
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    [self maskWithImage:tempMask targetView:self.imageCropView];
    
    [[SDWebImageManager sharedManager] downloadImageWithURL:self.product.productTemplate.maskImageURL options:SDWebImageHighPriority progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
        
        [self.containerView removeConstraint:self.maskAspectRatio];
        NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeWidth multiplier:image.size.height / image.size.width constant:0];
        [self.containerView addConstraints:@[con]];
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        [self maskWithImage:image targetView:self.imageCropView];
        self.visualEffectView.alpha = 0;
        [self.visualEffectView removeFromSuperview];
        self.visualEffectView = nil;
        
    }];
}

-(void) maskWithImage:(UIImage*) maskImage targetView:(UIView*) targetView{
    CALayer *_maskingLayer = [CALayer layer];
    _maskingLayer.frame = targetView.bounds;
    [_maskingLayer setContents:(id)[maskImage CGImage]];
    [targetView.layer setMask:_maskingLayer];
}

-(NSMutableArray *) userSelectedPhotos{
    if (!_userSelectedPhotos){
        NSMutableArray *mutableUserSelectedPhotos = [[NSMutableArray alloc] init];
        for (id asset in self.assets){
            OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
            printPhoto.asset = asset;
            [mutableUserSelectedPhotos addObject:printPhoto];
        }
        _userSelectedPhotos = mutableUserSelectedPhotos;
    }
    return _userSelectedPhotos;
}

- (void) updateQuantityLabel{
    self.quantityLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.quantity];
}

- (IBAction)onButtonDownArrowClicked:(UIButton *)sender {
    if (self.quantity > 1){
        self.quantity--;
        [self updateQuantityLabel];
    }
}

- (IBAction)onButtonUpArrowClicked:(UIButton *)sender {
    self.quantity++;
    [self updateQuantityLabel];
}

-(void)onButtonNextClicked{
    [self doCheckout];
}

-(void) doCheckout{
    NSUInteger iphonePhotoCount = 1;
    
    OLAsset *asset = [OLAsset assetWithImageAsJPEG:self.imageCropView.editedImage];
    
    NSMutableArray *assetArray = [[NSMutableArray alloc] initWithCapacity:self.quantity];
    for (NSInteger i = 0; i < self.quantity; i++){
        [assetArray addObject:asset];
    }
    
    OLProductPrintJob *job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:assetArray];
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
    
    OLCheckoutViewController *vc = [[OLCheckoutViewController alloc] initWithPrintOrder:printOrder];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
