//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
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
