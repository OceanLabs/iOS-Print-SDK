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

@interface OLSingleImageProductReviewViewController ()

@property (weak, nonatomic) IBOutlet RMImageCropper *imageCropView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *maskAspectRatio;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@end

@implementation OLSingleImageProductReviewViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.product.productTemplate.templateClass == kOLTemplateClassCase){
        NSString *imageName;
        if ([self.product.productTemplate.productCode hasSuffix:@"PHONE_4"]){
            imageName = @"iphone4";
        }
        else if ([self.product.productTemplate.productCode hasSuffix:@"PHONE_5"]){
            imageName = @"iphone5";
        }
        else if ([self.product.productTemplate.productCode hasSuffix:@"PHONE_5C"]){
            imageName = @"iphone5c";
        }
        else if ([self.product.productTemplate.productCode hasSuffix:@"PHONE_6"]){
            imageName = @"iphone6";
        }
        else if ([self.product.productTemplate.productCode hasSuffix:@"PHONE_6P"]){
            imageName = @"iphone6plus";
        }
        
        UIImage* mask = [UIImage imageNamed:imageName];
        
        [self.containerView removeConstraint:self.maskAspectRatio];
        NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeWidth multiplier:mask.size.height / mask.size.width constant:0];
        [self.containerView addConstraints:@[con]];
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        [self maskWithImage:mask targetView:self.imageCropView];
    }
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
}

-(void)onButtonNextClicked{
    [self doCheckout];
}

-(void) doCheckout{
    
}

@end
