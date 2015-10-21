//
//  OLProductDetailsViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 21/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import "OLProductDetailsViewController.h"
#import <TSMarkdownParser/TSMarkdownParser.h>

@interface OLProductDetailsViewController ()

@property (strong, nonatomic) UIVisualEffectView *visualEffectView;

@end

@implementation OLProductDetailsViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        
        self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        UIView *view = self.visualEffectView;
        [self.view addSubview:view];
        [self.view sendSubviewToBack:view];
        self.view.backgroundColor = [UIColor clearColor];
        
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
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    NSMutableAttributedString *attributedString = [[[TSMarkdownParser standardParser] attributedStringFromMarkdown:[self.product detailsString]] mutableCopy];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed: 0.341 green: 0.341 blue: 0.341 alpha: 1] range:NSMakeRange(0, attributedString.length)];
    self.detailsTextLabel.attributedText = attributedString;
}

- (CGFloat)recommendedDetailsBoxHeight{
    if ([self respondsToSelector:@selector(traitCollection)]){
        return self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ? 340 : 450;
    }
    else{
        return 340;
    }
}

@end
