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
    NSInteger sections = [OLUserSession currentSession].printOrder.shippingMethods.count;
    
    return sections;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize size = self.rotationSize.width != 0 ? self.rotationSize : self.view.frame.size;
    
    return CGSizeMake(size.width, 50);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    OLShippingClass *shippingMethod = [OLUserSession currentSession].printOrder.shippingMethods[indexPath.section];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackShippingMethodSelected:[OLUserSession currentSession].printOrder methodName:shippingMethod.className];
#endif
    [self.delegate shippingMethodsViewController:self didPickShippingMethod:shippingMethod];
    [self.collectionView reloadData];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"shippingMethodCell" forIndexPath:indexPath];
    
    OLShippingClass *shippingClass = [OLUserSession currentSession].printOrder.shippingMethods[indexPath.section];
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    
    [cell viewWithTag:10].hidden = [printOrder.selectedShippingMethod isEqualToString:shippingClass.className];
    [(UILabel *)[cell viewWithTag:20] setText:shippingClass.className];
    [(UILabel *)[cell viewWithTag:30] setText:[[printOrder costForShippingMethodName:shippingClass.className] formatCostForCurrencyCode:printOrder.currencyCode]];
    
    return cell;
}

@end
