//
//  OLAddressPicker.h
//  Kite SDK
//
//  Created by Deon Botha on 04/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLAddressPickerController;

@protocol OLAddressPickerControllerDelegate <NSObject>
- (void)addressPicker:(OLAddressPickerController *)picker didFinishPickingAddresses:(NSArray/*<OLAddress>*/ *)addresses;
- (void)addressPickerDidCancelPicking:(OLAddressPickerController *)picker;
@end

@interface OLAddressPickerController : UINavigationController

@property (weak, nonatomic) id<UINavigationControllerDelegate, OLAddressPickerControllerDelegate> delegate;
@property (assign, nonatomic) BOOL allowsMultipleSelection;
@property (assign, nonatomic) BOOL allowsAddressSearch;
@property (strong, nonatomic) NSArray/*<OLAddress>*/ *selected;

@end
