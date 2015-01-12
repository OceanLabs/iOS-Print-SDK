//
//  ProductHomeViewController.m
//  Print Studio
//
//  Created by Elliott Minns on 12/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import "OLProductHomeViewController.h"
#import "OLProductOverviewViewController.h"
#import "UITableViewController+ScreenWidthFactor.h"

#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLKiteViewController.h"
#import "OLKitePrintSDK.h"

@interface OLProductHomeViewController ()
@property (nonatomic, strong) NSArray *products;
@property (nonatomic, strong) UIImageView *topSurpriseImageView;
@property (nonatomic, strong) UIView *huggleBotSpeechBubble;
@property (nonatomic, weak) IBOutlet UILabel *huggleBotFriendNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *letsStartLabel;
@property (nonatomic, assign) BOOL startHuggleBotOnViewWillAppear;
@end

@implementation OLProductHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Products", @"");
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [OLProductTemplate sync];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ToProductOverviewSegue"]) {
        OLProductOverviewViewController *vc = segue.destinationViewController;
        vc.printOrder = self.printOrder;
        NSIndexPath *path = [self.tableView indexPathForCell:sender];
        vc.product = self.products[path.row];
    }
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 233 * [self screenWidthFactor];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.products.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"ProductCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    UIImageView *cellImage = (UIImageView *)[cell.contentView viewWithTag:40];
    
    
    OLProduct *product = self.products[indexPath.row];
    [product setCoverImageToImageView:cellImage];
    
    UILabel *productTypeLabel = (UILabel *)[cell.contentView viewWithTag:300];
    productTypeLabel.text = [product.productTemplate.name uppercaseString];
    productTypeLabel.backgroundColor = [product labelColor];
    
    return cell;
}

#pragma mark - Autorotate and Orientation Methods

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
