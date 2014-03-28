//
//  OLAddressPicker.m
//  PS SDK
//
//  Created by Deon Botha on 04/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLAddressPickerController.h"
#import "OLAddressSelectionViewController.h"

@interface OLAddressPickerController () <OLAddressSelectionViewControllerDelegate>
@property (strong, nonatomic) OLAddressSelectionViewController *selectionVC;
@end

@implementation OLAddressPickerController

- (id)init {
    OLAddressSelectionViewController *vc = [[OLAddressSelectionViewController alloc] init];
    if (self = [super initWithRootViewController:vc]) {
        self.selectionVC = vc;
        vc.delegate = self;
    }
    
    return self;
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection {
    self.selectionVC.allowMultipleSelection = allowsMultipleSelection;
}

- (BOOL)allowsMultipleSelection {
    return self.selectionVC.allowMultipleSelection;
}

- (NSArray *)selected {
    return self.selectionVC.selected;
}

- (void)setSelected:(NSArray *)selected {
    self.selectionVC.selected = selected;
}

- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark - OLAddressSelectionViewControllerDelegate methods

- (void)addressSelectionController:(OLAddressSelectionViewController *)vc didFinishPickingAddresses:(NSArray/*<OLAddress>*/ *)addresses {
    if (addresses.count > 0) {
        [self.delegate addressPicker:self didFinishPickingAddresses:addresses];
    } else {
        [self.delegate addressPickerDidCancelPicking:self];
    }
}

-(void)addressSelectionControllerDidCancelPicking:(OLAddressSelectionViewController *)vc {
    [self.delegate addressPickerDidCancelPicking:self];
}

@end
