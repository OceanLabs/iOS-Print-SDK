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
@property (weak, nonatomic) IBOutlet UILabel *selectedOptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *optionLabel;

@end

@implementation OLProductDetailsViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    NSMutableAttributedString *attributedString = [[[TSMarkdownParser standardParser] attributedStringFromMarkdown:[self.product detailsString]] mutableCopy];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:self.detailsTextLabel.tintColor range:NSMakeRange(0, attributedString.length)];
    self.detailsTextLabel.attributedText = attributedString;
    
    if (self.product.productTemplate.supportedOptions.allKeys.count == 0){
        [self.moreOptionsView removeFromSuperview];
    }
    else if (self.product.productTemplate.supportedOptions.allKeys.count != 1){
        [self.selectedOptionLabel removeFromSuperview];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.product.productTemplate.supportedOptions.allKeys.count == 1){
        self.optionLabel.text = self.product.productTemplate.supportedOptions.allKeys.firstObject;
        self.selectedOptionLabel.text = self.product.selectedOptions[self.product.productTemplate.supportedOptions.allKeys.firstObject];
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
    OLProductOptionsViewController *options = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOptionsViewController"];
    options.product = self.product;
    [self.navigationController pushViewController:options animated:YES];
}


@end
