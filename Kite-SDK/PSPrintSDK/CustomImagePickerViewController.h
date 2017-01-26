//
//  CustomImagePickerViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 14/10/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLCustomPickerController.h"
#import "OLCustomImagePickerViewControllerDelegate.h"

@interface CustomImagePickerViewController : UIViewController <OLCustomPickerController>
@property (weak, nonatomic) id<OLCustomImagePickerViewControllerDelegate> delegate;
@property (strong, nonatomic) NSString *productId;
@end
