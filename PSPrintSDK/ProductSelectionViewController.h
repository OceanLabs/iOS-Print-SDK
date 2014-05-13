//
//  ProductSelectionViewController.h
//  Kite SDK
//
//  Created by Deon Botha on 24/03/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kProductSquares,
    kProductSquaresMini,
    kProductPolaroidStyle,
    kProductPolaroidStyleMini,
    kProductMagnets,
    kProductPostcard
} Product;

NSString *displayNameWithProduct(Product product);
NSString *templateWithProduct(Product product);

@protocol ProductSelectionViewControllerDelegate <NSObject>
- (void)productSelectionViewControllerUserDidSelectProduct:(Product)product;
@end

@interface ProductSelectionViewController : UITableViewController
@property (nonatomic, weak) id<ProductSelectionViewControllerDelegate> delegate;
@property (nonatomic, assign) Product selectedProduct;
@end
