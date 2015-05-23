//
//  OLAddressSelectionViewController.h
//  Kite SDK
//
//  Created by Deon Botha on 04/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLAddressSelectionViewController;

@protocol OLAddressSelectionViewControllerDelegate <NSObject>
- (void)addressSelectionController:(OLAddressSelectionViewController *)vc didFinishPickingAddresses:(NSArray/*<OLAddress>*/ *)addresses;
- (void)addressSelectionControllerDidCancelPicking:(OLAddressSelectionViewController *)vc;
@end

@interface OLAddressSelectionViewController : UITableViewController
@property (weak, nonatomic) id<OLAddressSelectionViewControllerDelegate> delegate;
@property (assign, nonatomic) BOOL allowMultipleSelection;
@property (assign, nonatomic) BOOL allowAddressSearch;
@property (strong, nonatomic) NSArray/*<OLAddress>*/ *selected;
@end
