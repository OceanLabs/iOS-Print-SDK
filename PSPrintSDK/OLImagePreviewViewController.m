//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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

#import "OLImagePreviewViewController.h"
#import "UIView+AutoLayoutHelper.h"
#import "OLAsset+Private.h"
#import "OLKiteUtils.h"

#import <Photos/Photos.h>

@interface OLImagePreviewViewController ()
@property (strong, nonatomic) OLImageView *imageView;
@end

@implementation OLImagePreviewViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    OLImageView *imageView = [[OLImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView = imageView;
    [self.view addSubview:self.imageView];
    
    [imageView centerInSuperview];
    [imageView leadingFromSuperview:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [imageView trailingToSuperview:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [imageView topFromSuperview:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [imageView bottomToSuperview:0 relation:NSLayoutRelationGreaterThanOrEqual];
    
    __weak OLImagePreviewViewController *weakVc = self;
    [self.asset imageWithSize:self.view.frame.size applyEdits:YES progress:^(float progress){
        [weakVc.imageView setProgress:progress];
    } completion:^(UIImage *image, NSError *error){
        self.imageView.image = image;
    }];
    
}

- (NSArray *)previewActionItems{
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    
    if ([self.asset isEdited]){
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized){
            UIPreviewAction *saveAction = [UIPreviewAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Save as Copy", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIPreviewActionStyleDefault handler:^(UIPreviewAction *action, id context){
                [self.asset imageWithSize:OLAssetMaximumSize applyEdits:YES progress:NULL completion:^(UIImage *image, NSError *error){
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        PHAssetChangeRequest *changeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                        changeRequest.creationDate = [NSDate date];
                    } completionHandler:NULL];
                }];
            }];
            [actions addObject:saveAction];
        }
        
        UIPreviewAction *discardAction = [UIPreviewAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Discard Edits", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction *action, id context){
            self.asset.edits = nil;
        }];
        [actions addObject:discardAction];
    }
    
    return actions;
}

@end
