//
//  OLProductDetailsViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 21/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import "OLProductDetailsViewController.h"
#import "OLProductOptionsViewController.h"
#import "TSMarkdownParser.h"
#import "OLAnalytics.h"
#import "OLKiteABTesting.h"

@interface OLProductDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIView *moreOptionsView;
@property (weak, nonatomic) IBOutlet UILabel *selectedOptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *optionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chevron;
@property (weak, nonatomic) IBOutlet UILabel *detailsLabel;

@end

@interface OLProductOverViewViewController

- (IBAction)onLabelDetailsTapped:(UITapGestureRecognizer *)sender;
@property (strong, nonatomic) UILabel *detailsTextLabel;

@end

@implementation OLProductDetailsViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    if ([OLKiteABTesting sharedInstance].darkTheme){
        self.detailsLabel.textColor = [UIColor whiteColor];
        self.optionLabel.textColor = [UIColor whiteColor];
        self.selectedOptionLabel.textColor = [UIColor whiteColor];
        self.priceLabel.textColor = [UIColor whiteColor];
    }
    
    NSMutableAttributedString *attributedString = [[[TSMarkdownParser standardParser] attributedStringFromMarkdown:[self.product detailsString]] mutableCopy];
    
    if ([OLKiteABTesting sharedInstance].darkTheme){
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attributedString.length)];
    }
    else{
        [attributedString addAttribute:NSForegroundColorAttributeName value:self.detailsTextLabel.tintColor range:NSMakeRange(0, attributedString.length)];
    }
    self.detailsTextLabel.attributedText = attributedString;
    
    if (self.product.productTemplate.options.count == 0){
        [self.moreOptionsView removeFromSuperview];
    }
    else if (self.product.productTemplate.options.count != 1){
        [self.selectedOptionLabel removeFromSuperview];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.product.productTemplate.options.count == 1){
        OLProductTemplateOption *option = self.product.productTemplate.options.firstObject;
        self.optionLabel.text = option.name;
        self.selectedOptionLabel.text = [option nameForSelection:self.product.selectedOptions[[option code]]];
    }
}

- (CGFloat)recommendedDetailsBoxHeight{
    if ([self respondsToSelector:@selector(traitCollection)]){
        return self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ? 340 : 450;
    }
    else{
        return 340;
    }
}

- (IBAction)onOptionsClicked:(UIButton *)sender {
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackDetailsViewProductOptionsTappedForProductName:self.product.productTemplate.name];
#endif
    
    OLProductOptionsViewController *options = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOptionsViewController"];
    options.product = self.product;
    [UIView animateWithDuration:0.25 animations:^{
        [self.navigationController pushViewController:options animated:YES];
    }];
    
    if ([self.delegate respondsToSelector:@selector(optionsButtonClicked)]){
        [self.delegate optionsButtonClicked];
    }
}

- (IBAction)onDetailsAreaTapped:(UITapGestureRecognizer *)sender {
    if ([self.delegate respondsToSelector:@selector(onLabelDetailsTapped:)]){
        [self.delegate performSelector:@selector(onLabelDetailsTapped:) withObject:nil];
    }
}


@end
