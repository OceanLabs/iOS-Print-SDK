//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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

#import "OLShippingMethodsViewController.h"
#import "OLKiteUtils.h"
#import "OLAnalytics.h"
#import "OLUserSession.h"
#import "OLShippingClass.h"
#import "NSDecimalNumber+CostFormatter.h"
#import "OLProductTemplate.h"
#import "OLPrintJob.h"
#import "OLPrintOrderCost.h"
#import "OLPaymentLineItem.h"

@interface OLShippingMethodsViewController () <UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (assign, nonatomic) CGSize rotationSize;

@end

@implementation OLShippingMethodsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.title = NSLocalizedStringFromTableInBundle(@"Shipping Method", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackShippingMethodScreenViewed:[OLUserSession currentSession].printOrder];
#endif
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackShippingMethodScreenHitBack:[OLUserSession currentSession].printOrder];
    }
#endif
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.rotationSize = size;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView reloadData];
        [self.collectionView.collectionViewLayout invalidateLayout];
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
        
    }];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return [OLUserSession currentSession].printOrder.jobs.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    id<OLPrintJob> job = printOrder.jobs[section];
    return [printOrder shippingMethodsForJobs:@[job]].count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize size = self.rotationSize.width != 0 ? self.rotationSize : self.view.frame.size;
    
    return CGSizeMake(size.width, 50);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    id<OLPrintJob> job = printOrder.jobs[indexPath.section];
    OLShippingClass *shippingMethod = [[OLUserSession currentSession].printOrder shippingMethodsForJobs:@[job]][indexPath.item];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackShippingMethodSelected:[OLUserSession currentSession].printOrder methodName:shippingMethod.className];
#endif
    printOrder.jobs[indexPath.section].selectedShippingMethodIdentifier = shippingMethod.identifier;
    
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < [self collectionView:collectionView numberOfItemsInSection:indexPath.section]; i++){
        [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:indexPath.section]];
    }
    [collectionView reloadItemsAtIndexPaths:indexPaths];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sectionHeader" forIndexPath:indexPath];
    
    UILabel *label = (UILabel *)[cell viewWithTag:10];
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    id<OLPrintJob> job = printOrder.jobs[indexPath.section];
    [printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
        for (OLPaymentLineItem *item in cost.lineItems){
            if ([item.identifier isEqualToString:[job uuid]]){
                label.text = item.description;
            }
        }
    }];
    
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"shippingMethodCell" forIndexPath:indexPath];
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    id<OLPrintJob> job = printOrder.jobs[indexPath.section];
    OLShippingClass *shippingClass = [printOrder shippingMethodsForJobs:@[job]][indexPath.item];
    
    [cell viewWithTag:10].hidden = job.selectedShippingMethodIdentifier != shippingClass.identifier;
    [(UILabel *)[cell viewWithTag:20] setText:shippingClass.displayName];
    [(UILabel *)[cell viewWithTag:30] setText:[[printOrder costForShippingMethodName:shippingClass.className forJobs:@[job]] formatCostForCurrencyCode:printOrder.currencyCode]];
    [(UILabel *)[cell viewWithTag:40] setText:[printOrder deliveryEstimatedDaysStringForShippingMethodName:shippingClass.className forJobs:@[job]]];
    
    return cell;
}

@end
