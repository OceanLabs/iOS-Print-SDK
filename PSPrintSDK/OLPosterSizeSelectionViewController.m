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
    deselectedColor = [UIColor colorWithRed:0.753 green:0.867 blue:0.922 alpha:1]; /*#c0ddeb*/
    [self pressedClassic:nil];
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Next"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(pressedContinue)];
    self.navigationItem.rightBarButtonItem = nextButton;
    [self setTitle:NSLocalizedString(@"Size", @"")];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - actions
- (IBAction)pressedClassic:(UIButton *)sender {
    for (OLProduct *product in [OLProduct products]){
        if (product.templateType == kOLTemplateTypeLargeFormatA3){
            self.product = product;
        }
    }
    self.classicBtn.backgroundColor = [UIColor whiteColor];
    self.grandBtn.backgroundColor = deselectedColor;
    self.deluxeBtn.backgroundColor = deselectedColor;
    self.sizeLabel.text = @"A3:";
    [self.product setProductPhotography:0 toImageView:self.productImageView];
    self.posterDimensionLabel.text = [NSString stringWithFormat:@"%@", self.product.dimensions];
    [self.posterDimensionLabel sizeToFit];
    self.priceLabel.text = self.product.unitCost;
}

- (IBAction)pressedGrand:(UIButton *)sender {
    for (OLProduct *product in [OLProduct products]){
        if (product.templateType == kOLTemplateTypeLargeFormatA2){
            self.product = product;
        }
    }
    self.grandBtn.backgroundColor = [UIColor whiteColor];
    self.deluxeBtn.backgroundColor = deselectedColor;
    self.classicBtn.backgroundColor = deselectedColor;
    self.sizeLabel.text = @"A2:";
    [self.product setProductPhotography:0 toImageView:self.productImageView];
    self.posterDimensionLabel.text = [NSString stringWithFormat:@"%@", self.product.dimensions];
    [self.posterDimensionLabel sizeToFit];
    self.priceLabel.text = self.product.unitCost;
}

- (IBAction)pressedDeluxe:(UIButton *)sender {
    for (OLProduct *product in [OLProduct products]){
        if (product.templateType == kOLTemplateTypeLargeFormatA1){
            self.product = product;
        }
    }
    self.classicBtn.backgroundColor = deselectedColor;
    self.grandBtn.backgroundColor = deselectedColor;
    self.deluxeBtn.backgroundColor = [UIColor whiteColor];
    self.sizeLabel.text = @"A1:";
    [self.product setProductPhotography:0 toImageView:self.productImageView];
    self.posterDimensionLabel.text = [NSString stringWithFormat:@"%@", self.product.dimensions];
    [self.posterDimensionLabel sizeToFit];
    self.priceLabel.text = self.product.unitCost;
}

- (IBAction)pressedContinue {
    OLPosterViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"p1x1ViewController"];
    dest.product = self.product;
    dest.printOrder = self.printOrder;
    [self.navigationController pushViewController:dest animated:YES];
}

@end
