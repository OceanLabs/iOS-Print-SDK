//
//  FrameSelectionViewController.h
//  Print Studio
//
//  Created by Deon Botha on 13/02/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLPrintOrder;

@interface OLFrameSelectionViewController : UITableViewController

@property (strong, nonatomic) OLPrintOrder *printOrder;

@end
