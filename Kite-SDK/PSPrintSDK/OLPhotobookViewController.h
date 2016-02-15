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

#import <UIKit/UIKit.h>
#import "OLKitePrintSDK.h"

@class OLPhotobookPageContentViewController;
@class OLPhotobookViewController;

@protocol OLPhotobookViewControllerDelegate <NSObject>

- (void)photobook:(OLPhotobookViewController *)photobook userDidTapOnImageWithIndex:(NSInteger)index;
- (void)photobook:(OLPhotobookViewController *)photobook userDidLongPressOnImageWithIndex:(NSInteger)index sender:(UILongPressGestureRecognizer *)sender;

@end

@interface OLPhotobookViewController : UIViewController

@property (strong, nonatomic) OLProduct *product;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (strong, nonatomic) NSMutableArray *photobookPhotos;
@property (strong, nonatomic) NSNumber *editingPageNumber;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;
@property (weak, nonatomic) id<OLPhotobookViewControllerDelegate> photobookDelegate;
@property (strong, nonatomic) UIPageViewController *pageController;

@property (assign, nonatomic) BOOL editMode;
@property (assign, nonatomic) BOOL startOpen;
@property (assign, nonatomic, readonly) BOOL bookClosed;
@property (strong, nonatomic) OLPrintPhoto *coverPhoto;
@property (weak, nonatomic) IBOutlet UILabel *pagesLabel;

@property (strong, nonatomic) id<OLPrintJob> editingPrintJob;

- (void)loadCoverPhoto;

- (void)saveJobWithCompletionHandler:(void(^)())handler;

@end
