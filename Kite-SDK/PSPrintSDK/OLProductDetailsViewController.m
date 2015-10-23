//
//  OLProductDetailsViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 21/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import "OLProductDetailsViewController.h"
#import "OLProductOptionsViewController.h"
#import <TSMarkdownParser/TSMarkdownParser.h>

@interface OLProductDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIView *moreOptionsView;

@end

@implementation OLProductDetailsViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    NSMutableAttributedString *attributedString = [[[TSMarkdownParser standardParser] attributedStringFromMarkdown:[self.product detailsString]] mutableCopy];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.341 alpha:1.000] range:NSMakeRange(0, attributedString.length)];
    self.detailsTextLabel.attributedText = attributedString;
    
    if (self.product.productTemplate.supportedOptions.allKeys.count == 0){
        [self.moreOptionsView removeFromSuperview];
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
    self.moreOptionsView.backgroundColor = [UIColor clearColor];
    OLProductOptionsViewController *options = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOptionsViewController"];
    options.product = self.product;
    [self.navigationController pushViewController:options animated:YES];
}

- (IBAction)onOptionsTouchDown:(UIButton *)sender {
    self.moreOptionsView.backgroundColor = [UIColor whiteColor];
}
- (IBAction)optionsCanceled:(UIButton *)sender {
    self.moreOptionsView.backgroundColor = [UIColor clearColor];
}


@end
