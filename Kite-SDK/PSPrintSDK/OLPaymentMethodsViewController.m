//
//  OLPaymentMethodsViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 16/05/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
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

@interface OLPaymentMethodsViewController () <UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, OLCreditCardCaptureDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (assign, nonatomic) CGSize rotationSize;

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
    
    OLPaymentMethod method = [self paymentMethodForSection:indexPath.section];
    id existingCard = [OLKitePrintSDK useStripeForCreditCards] ? [OLStripeCard lastUsedCard] : [OLPayPalCard lastUsedCard];
    if (method == kOLPaymentMethodCreditCard && indexPath.row == 0 && existingCard){
        imageView.image = [existingCard cardIcon];
        label.text = [NSString stringWithFormat:@"•••• •••• •••• %@", [[existingCard numberMasked] substringFromIndex:[[existingCard numberMasked] length] - 4]];
        if (self.selectedPaymentMethod == kOLPaymentMethodCreditCard){
            [cell viewWithTag:30].hidden = NO;
        }
        else{
            [cell viewWithTag:30].hidden = YES;
        }
    }
    else if (method == kOLPaymentMethodCreditCard){
        imageView.image = [UIImage imageNamed:@"add-payment"];
        label.text = NSLocalizedStringFromTableInBundle(@"Add Credit/Debit Card", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
        [cell viewWithTag:30].hidden = YES;
    }
    else if (method == kOLPaymentMethodApplePay){
        imageView.image = [UIImage imageNamed:@"apple-pay-method"];
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
        imageView.image = [UIImage imageNamed:@"paypal-method"];
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
    else{
        self.selectedPaymentMethod = method;
        [self.collectionView reloadData];
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
    OLCreditCardCaptureViewController *ccCaptureController = [[OLCreditCardCaptureViewController alloc] initWithPrintOrder:nil];
    ccCaptureController.delegate = self;
    ccCaptureController.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:ccCaptureController animated:YES completion:nil];
}


@end
