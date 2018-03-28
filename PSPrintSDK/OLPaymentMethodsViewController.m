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

#import "OLPaymentMethodsViewController.h"
#import "OLPaymentViewController.h"
#import "OLStripeCard.h"
#import "OLPayPalCard.h"
#import "OLCreditCardCaptureViewController.h"
#import "OLKiteUtils.h"
#import "OLKitePrintSDK.h"
#import "OLPayPalCard+OLCardIcon.h"
#import "OLStripeCard+OLCardIcon.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLUserSession.h"
#import "OLPaymentViewController.h"

@interface OLPaymentMethodsViewController () <UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, OLCreditCardCaptureDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (assign, nonatomic) CGSize rotationSize;

@end

@interface OLPaymentViewController ()
@property (strong, nonatomic) OLPrintOrder *printOrder;
@end

@interface OLKitePrintSDK ()
+ (BOOL)useStripeForCreditCards;
@end

@implementation OLPaymentMethodsViewController

- (void)setSelectedPaymentMethod:(OLPaymentMethod)selectedPaymentMethod{
    _selectedPaymentMethod = selectedPaymentMethod;
    
    if ([self.delegate respondsToSelector:@selector(paymentMethodsViewController:didPickPaymentMethod:)]){
        [self.delegate paymentMethodsViewController:self didPickPaymentMethod:selectedPaymentMethod];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.title = NSLocalizedStringFromTableInBundle(@"Payment Method", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentMethodScreenViewed:[(OLPaymentViewController *)self.delegate printOrder]];
#endif
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackPaymentMethodScreenHitBack:[(OLPaymentViewController *)self.delegate printOrder]];
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
    NSInteger sections = 1; //Credit Cards for everyone!
    
    if ([OLKiteUtils isApplePayAvailable]){
        sections++;
    }
    
    if ([OLKiteUtils isPayPalAvailable]){
        sections++;
    }
    
    return sections;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    id existingCard = [OLKitePrintSDK useStripeForCreditCards] ? [OLStripeCard lastUsedCard] : [OLPayPalCard lastUsedCard];
    if (section == 0 && existingCard){
        return 2;
    }
    
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"paymentMethodCell" forIndexPath:indexPath];
    
    UIImageView *imageView = [cell viewWithTag:10];
    UILabel *label = [cell viewWithTag:20];
    
    UIView *view = [cell viewWithTag:100];
    view.transform = CGAffineTransformIdentity;
    
    for (UIGestureRecognizer *gesture in cell.gestureRecognizers){
        [cell removeGestureRecognizer:gesture];
    }
    
    OLPaymentMethod method = [self paymentMethodForSection:indexPath.section];
    id existingCard = [OLKitePrintSDK useStripeForCreditCards] ? [OLStripeCard lastUsedCard] : [OLPayPalCard lastUsedCard];
    if (method == kOLPaymentMethodCreditCard && indexPath.row == 0 && existingCard){
        imageView.image = [existingCard cardIcon];
        label.text = [NSString stringWithFormat:[existingCard isAmex] ? @"•••• •••••• •%@" : @"•••• •••• •••• %@", [[existingCard numberMasked] substringFromIndex:[[existingCard numberMasked] length] - 4]];
        if (self.selectedPaymentMethod == kOLPaymentMethodCreditCard){
            [cell viewWithTag:30].hidden = NO;
        }
        else{
            [cell viewWithTag:30].hidden = YES;
        }
        
        UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeftGestureRecognized:)];
        gesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [cell addGestureRecognizer:gesture];
    }
    else if (method == kOLPaymentMethodCreditCard){
        imageView.image = [UIImage imageNamedInKiteBundle:@"add-payment"];
        label.text = NSLocalizedStringFromTableInBundle(@"Add Credit/Debit Card", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        [cell viewWithTag:30].hidden = YES;
    }
    else if (method == kOLPaymentMethodApplePay){
        imageView.image = [UIImage imageNamedInKiteBundle:@"apple-pay-method"];
        label.text = @"Apple Pay";
        
        if (self.selectedPaymentMethod == kOLPaymentMethodNone){
            self.selectedPaymentMethod = kOLPaymentMethodApplePay;
        }
        
        if (self.selectedPaymentMethod == kOLPaymentMethodApplePay){
            [cell viewWithTag:30].hidden = NO;
        }
        else{
            [cell viewWithTag:30].hidden = YES;
        }
    }
    else if (method == kOLPaymentMethodPayPal){
        imageView.image = [UIImage imageNamedInKiteBundle:@"paypal-method"];
        label.text = @"PayPal";
        if (self.selectedPaymentMethod == kOLPaymentMethodPayPal){
            [cell viewWithTag:30].hidden = NO;
        }
        else{
            [cell viewWithTag:30].hidden = YES;
        }        
    }
    else{
        NSAssert(NO, @"Too many cells?");
    }
    
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    OLPaymentMethod method = [self paymentMethodForSection:indexPath.section];
    id existingCard = [OLKitePrintSDK useStripeForCreditCards] ? [OLStripeCard lastUsedCard] : [OLPayPalCard lastUsedCard];
    if (method == kOLPaymentMethodCreditCard && (indexPath.item > 0 || !existingCard)){
        [self addNewCard];
    }
    else if (self.selectedPaymentMethod != method){
        self.selectedPaymentMethod = method;
        [self.collectionView reloadData];
    }
    else{
        UIView *view = [[collectionView cellForItemAtIndexPath:indexPath] viewWithTag:100];
        view.transform = CGAffineTransformIdentity;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize size = self.rotationSize.width != 0 ? self.rotationSize : self.view.frame.size;
    
    return CGSizeMake(size.width, 50);
}

- (void)creditCardCaptureController:(OLCreditCardCaptureViewController *)vc didFinishWithProofOfPayment:(NSString *)proofOfPayment{
    self.selectedPaymentMethod = kOLPaymentMethodCreditCard;
    [self.collectionView reloadData];
    [vc dismissViewControllerAnimated:YES completion:^(){
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (OLPaymentMethod)paymentMethodForSection:(NSInteger)section{
    if (section == 0){
        return kOLPaymentMethodCreditCard;
    }
    else if (section == 1 && [OLKiteUtils isApplePayAvailable]){
        return kOLPaymentMethodApplePay;
    }
    else if (section == 1 && [OLKiteUtils isPayPalAvailable]){
        return kOLPaymentMethodPayPal;
    }
    else if (section == 2 && [OLKiteUtils isPayPalAvailable]){
        return kOLPaymentMethodPayPal;
    }
    NSAssert(NO, @"Should not reach here");
    return kOLPaymentMethodNone;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if (section == 0){
        return UIEdgeInsetsMake(40, 0, 25, 0);
    }
    return UIEdgeInsetsMake(15, 0, 0, 0);
}

- (void)addNewCard {
    OLCreditCardCaptureViewController *ccCaptureController = [[OLCreditCardCaptureViewController alloc] init];
    ccCaptureController.delegate = self;
    ccCaptureController.modalPresentationStyle = [OLUserSession currentSession].kiteVc.modalPresentationStyle;
    [self presentViewController:ccCaptureController animated:YES completion:nil];
}
- (IBAction)swipeLeftGestureRecognized:(UISwipeGestureRecognizer *)sender {
    UIView *view = [sender.view viewWithTag:100];
    [UIView animateWithDuration:0.25 animations:^{
        view.transform = CGAffineTransformMakeTranslation(-view.frame.size.width, 0);
    }];
}

- (IBAction)onButtonDeleteCardTapped:(UIButton *)sender {
    [OLStripeCard clearLastUsedCard];
    [OLPayPalCard clearLastUsedCard];
    
    if (self.selectedPaymentMethod == kOLPaymentMethodCreditCard){
        self.selectedPaymentMethod = kOLPaymentMethodNone;
    }
    
    [self.collectionView reloadData];
}

@end
