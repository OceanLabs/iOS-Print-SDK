//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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

#import "OLAddressPickerController.h"
#import "OLAddressSelectionViewController.h"
#import "OLKiteABTesting.h"

@interface OLAddressPickerController () <OLAddressSelectionViewControllerDelegate>
@property (strong, nonatomic) OLAddressSelectionViewController *selectionVC;
@end

@implementation OLAddressPickerController

@dynamic delegate;

- (BOOL)prefersStatusBarHidden {
    BOOL hidden = [OLKiteABTesting sharedInstance].darkTheme;
    
    if ([self respondsToSelector:@selector(traitCollection)]){
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact && self.view.frame.size.height < self.view.frame.size.width){
            hidden |= YES;
        }
    }
    
    return hidden;
}

- (id)init {
    OLAddressSelectionViewController *vc = [[OLAddressSelectionViewController alloc] init];
    if (self = [super initWithRootViewController:vc]) {
        self.selectionVC = vc;
        vc.delegate = self;
        self.allowsAddressSearch = YES;
    }
    
    return self;
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection {
    self.selectionVC.allowMultipleSelection = allowsMultipleSelection;
}

- (BOOL)allowsMultipleSelection {
    return self.selectionVC.allowMultipleSelection;
}

- (void)setAllowsAddressSearch:(BOOL)allowsAddressSearch {
    self.selectionVC.allowAddressSearch = allowsAddressSearch;
}

- (BOOL)allowsAddressSearch {
    return self.selectionVC.allowAddressSearch;
}

- (NSArray *)selected {
    return self.selectionVC.selected;
}

- (void)setSelected:(NSArray *)selected {
    self.selectionVC.selected = selected;
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

#pragma mark - Autorotate and Orientation Methods
// Currently here to disable landscape orientations and rotation on iOS 7. When support is dropped, these can be deleted.

- (BOOL)shouldAutorotate {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return YES;
    }
    else{
        return NO;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
