//
//  OLPosterSizeSelectionViewController.m
//  Photo Mosaic
//
//  Created by Alberto De Capitani on 23/09/2014.
//  Copyright (c) 2014 Ocean Labs App Ltd. All rights reserved.
//

#import "OLPosterSizeSelectionViewController.h"
#import "OLProduct.h"
#import "OLPosterViewController.h"
#import "OLKiteViewController.h"
#import "OLAnalytics.h"

static UIColor *deselectedColor;


@interface OLPosterSizeSelectionViewController ()
@property (weak, nonatomic) IBOutlet UIButton *classicBtn;
@property (weak, nonatomic) IBOutlet UIButton *grandBtn;
@property (weak, nonatomic) IBOutlet UIButton *deluxeBtn;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *shipping;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *posterDimensionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *productImageView;
@property (strong, nonatomic) OLProduct *product;
@property (strong, nonatomic) NSMutableArray *availableButtons;

@end

@implementation OLPosterSizeSelectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductDescriptionScreenViewed:@"Posters"];
#endif
    
    self.availableButtons = [@[self.classicBtn, self.grandBtn, self.deluxeBtn] mutableCopy];
    deselectedColor = [UIColor colorWithRed:0.365 green:0.612 blue:0.925 alpha:1]; /*#5d9cec*/
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Next"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(pressedContinue)];
    self.navigationItem.rightBarButtonItem = nextButton;
    [self setTitle:NSLocalizedString(@"Choose Size", @"")];
    
    OLProduct *productA1;
    OLProduct *productA2;
    OLProduct *productA3;
    for (OLProduct *product in [OLProduct products]){
        if ([product.productTemplate.productCode isEqualToString:@"LFA1"] && product.productTemplate.quantityPerSheet == 1){
            productA1 = product;
        }
        if ([product.productTemplate.productCode isEqualToString:@"LFA2"] && product.productTemplate.quantityPerSheet == 1){
            productA2 = product;
        }
        if ([product.productTemplate.productCode isEqualToString:@"LFA3"] && product.productTemplate.quantityPerSheet == 1){
            productA3 = product;
        }
    }
    if (!productA1){
        [self.deluxeBtn removeFromSuperview];
        [self.availableButtons removeObject:self.deluxeBtn];
    }
    if (!productA2){
        [self.grandBtn removeFromSuperview];
        [self.availableButtons removeObject:self.grandBtn];
    }
    if (!productA3){
        [self.classicBtn removeFromSuperview];
        [self.availableButtons removeObject:self.classicBtn];
    }
    
    UIButton *firstButton = [self.availableButtons firstObject];
    if (firstButton == self.classicBtn){
        [self pressedClassic:nil];
    }
    else if (firstButton == self.grandBtn){
        [self pressedGrand:nil];
    }
    else if (firstButton == self.deluxeBtn){
        [self pressedDeluxe:nil];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    if (self.navigationController){
        NSMutableArray *navigationStack = self.navigationController.viewControllers.mutableCopy;
        if (navigationStack.count > 1 && [navigationStack[navigationStack.count - 2] isKindOfClass:[OLKiteViewController class]]) {
            OLKiteViewController *kiteVc = navigationStack[navigationStack.count - 2];
            if (!kiteVc.presentingViewController){
                [navigationStack removeObject:kiteVc];
                self.navigationController.viewControllers = navigationStack;
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - actions
- (IBAction)pressedClassic:(UIButton *)sender {
    for (OLProduct *product in [OLProduct products]){
        if ([product.productTemplate.productCode isEqualToString:@"LFA3"] && product.productTemplate.quantityPerSheet == 1){
            self.product = product;
        }
    }
    self.classicBtn.backgroundColor = [UIColor whiteColor];
    [self.classicBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.grandBtn.backgroundColor = deselectedColor;
    [self.grandBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.deluxeBtn.backgroundColor = deselectedColor;
    [self.deluxeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.sizeLabel.text = @"A3:";
    [self.product setProductPhotography:0 toImageView:self.productImageView];
    self.posterDimensionLabel.text = [NSString stringWithFormat:@"%@", self.product.dimensions];
    [self.posterDimensionLabel sizeToFit];
    self.priceLabel.text = self.product.unitCost;
}

- (IBAction)pressedGrand:(UIButton *)sender {
    for (OLProduct *product in [OLProduct products]){
        if ([product.productTemplate.productCode isEqualToString:@"LFA2"] && product.productTemplate.quantityPerSheet == 1){
            self.product = product;
        }
    }
    self.grandBtn.backgroundColor = [UIColor whiteColor];
    [self.grandBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.deluxeBtn.backgroundColor = deselectedColor;
    [self.deluxeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.classicBtn.backgroundColor = deselectedColor;
    [self.classicBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.sizeLabel.text = @"A2:";
    [self.product setProductPhotography:0 toImageView:self.productImageView];
    self.posterDimensionLabel.text = [NSString stringWithFormat:@"%@", self.product.dimensions];
    [self.posterDimensionLabel sizeToFit];
    self.priceLabel.text = self.product.unitCost;
}

- (IBAction)pressedDeluxe:(UIButton *)sender {
    for (OLProduct *product in [OLProduct products]){
        if ([product.productTemplate.productCode isEqualToString:@"LFA1"] && product.productTemplate.quantityPerSheet == 1){
            self.product = product;
        }
    }
    self.classicBtn.backgroundColor = deselectedColor;
    [self.classicBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.grandBtn.backgroundColor = deselectedColor;
    [self.grandBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.deluxeBtn.backgroundColor = [UIColor whiteColor];
    [self.deluxeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    self.sizeLabel.text = @"A1:";
    [self.product setProductPhotography:0 toImageView:self.productImageView];
    self.posterDimensionLabel.text = [NSString stringWithFormat:@"%@", self.product.dimensions];
    [self.posterDimensionLabel sizeToFit];
    self.priceLabel.text = self.product.unitCost;
}

- (IBAction)pressedContinue {
    OLPosterViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"p1x1ViewController"];
    dest.product = self.product;
    dest.assets = self.assets;
    [self.navigationController pushViewController:dest animated:YES];
}

@end
