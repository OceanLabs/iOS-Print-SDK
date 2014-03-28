//
//  OLCountryPickerController.h
//  PS SDK
//
//  Created by Deon Botha on 05/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLCountryPickerController;

@protocol OLCountryPickerControllerDelegate <NSObject>
- (void)countryPicker:(OLCountryPickerController *)picker didSucceedWithCountries:(NSArray/*<OLCountry>*/ *)countries;
- (void)countryPickerDidCancelPicking:(OLCountryPickerController *)picker;
@end

@interface OLCountryPickerController : UINavigationController
@property (weak, nonatomic) id<UINavigationControllerDelegate, OLCountryPickerControllerDelegate> delegate;
@property (strong, nonatomic) NSArray/*<OLCountry>*/ *selected;
@property (assign, nonatomic) BOOL allowsMultipleSelection;
@end
