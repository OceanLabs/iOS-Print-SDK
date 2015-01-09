//
//  FrameSelectionViewController.m
//  Print Studio
//
//  Created by Deon Botha on 13/02/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "FrameSelectionViewController.h"
#import "UITableViewController+ScreenWidthFactor.h"

@interface FrameSelectionViewController ()

@end

@implementation FrameSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Choose Frame Style", @"");
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    PhotoSelectionViewController *photoSelectionVC = segue.destinationViewController;
//    if ([segue.identifier isEqualToString:@"Selected2x2FrameStyleSegue"]) {
//        photoSelectionVC.product = [Product productForFrame2x2];
//    } else if ([segue.identifier isEqualToString:@"Selected3x3FrameStyleSegue"]) {
//        photoSelectionVC.product = [Product productForFrame3x3];
//    } else if ([segue.identifier isEqualToString:@"Selected4x4FrameStyleSegue"]) {
//        photoSelectionVC.product = [Product productForFrame4x4];
//    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 233 * [self screenWidthFactor];
}



@end
