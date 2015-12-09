//
//  OLProductOptionsViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 21/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import "OLProductOptionsViewController.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLAnalytics.h"

@interface OLProductOptionsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;
@property (weak, nonatomic) IBOutlet UIImageView *backChevron;

@end

@implementation OLProductOptionsViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.backChevron.transform = CGAffineTransformMakeRotation(M_PI);
    
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
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    if (!self.navigationController){
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackDetailsViewProductOptionsHitBackForProductName:self.product.productTemplate.name];
#endif
    }
}

- (IBAction)onButtonBackTapped:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.product.productTemplate.options.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.product.productTemplate.options[section] selections].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"optionCell"];
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    UILabel *label = (UILabel *)[cell viewWithTag:20];
    OLProductTemplateOption *option = self.product.productTemplate.options[indexPath.section];
    label.text = [option nameForSelection:option.selections[indexPath.row]];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:10];
    if ([self.product.selectedOptions[option.code] isEqualToString:option.selections[indexPath.row]]){
        imageView.image = [[UIImage imageNamedInKiteBundle:@"checkmark_on"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else{
        imageView.image = nil;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    OLProductTemplateOption *option = self.product.productTemplate.options[section];
    return option.name;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath{
    OLProductTemplateOption *option = self.product.productTemplate.options[indexPath.section];
    self.product.selectedOptions[option.code] = option.selections[indexPath.row];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackDetailsViewProductOptionsSelectedOption:[option nameForSelection:option.selections[indexPath.row]] forProductName:self.product.productTemplate.name];
#endif
    
    [tableView reloadData];
    
    return NO;
}

@end
