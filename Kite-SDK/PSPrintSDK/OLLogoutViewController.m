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

#import "OLLogoutViewController.h"
#import <UIView+RoundRect.h>
#import "OLUserSession.h"
#import "OLKiteViewController.h"

@interface OLKiteViewController ()
- (void)kioskLogout;
- (void)setLastTouchDate:(NSDate *)date forViewController:(UIViewController *)vc;
- (void)startTimer;
@end

@interface OLLogoutViewController ()

@property (weak, nonatomic) IBOutlet UILabel *secondsLabel;
@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

static const NSInteger startTime = 60;

@implementation OLLogoutViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self.logoutButton makeRoundRectWithRadius:2];
    [self.cancelButton makeRoundRectWithRadius:2];
    
    self.logoutButton.layer.masksToBounds = NO;
    self.logoutButton.layer.shadowOffset = CGSizeMake(0, 1.5);
    self.logoutButton.layer.shadowRadius = 3.5;
    self.logoutButton.layer.shadowOpacity = 0.2;
    
    self.cancelButton.layer.masksToBounds = NO;
    self.cancelButton.layer.shadowOffset = CGSizeMake(0, 1.5);
    self.cancelButton.layer.shadowRadius = 3.5;
    self.cancelButton.layer.shadowOpacity = 0.2;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.secondsLabel.text = [NSString stringWithFormat:@"%ld", (long)startTime];
    
    self.startDate = [NSDate date];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateCounter:) userInfo:nil repeats:YES];
}

- (void)updateCounter:(NSTimer *)theTimer {
    // has the target time passed?
    if ([self.startDate timeIntervalSinceNow] <= -startTime) {
        [theTimer invalidate];
        [self onButtonLogoutNowTapped:nil];
    }
    else{
        self.secondsLabel.text = [NSString stringWithFormat:@"%d", (int)(startTime+[self.startDate timeIntervalSinceNow]+1)];
    }
}

- (IBAction)onButtonLogoutNowTapped:(UIButton *)sender {
    [[OLUserSession currentSession].kiteVc kioskLogout];
}

- (IBAction)cancelLogout:(id)sender {
    UIViewController *vc = self.presentingViewController;
    [self.timer invalidate];
    [self dismissViewControllerAnimated:YES completion:^{
        [[OLUserSession currentSession].kiteVc setLastTouchDate:[NSDate date] forViewController:vc];
        [[OLUserSession currentSession].kiteVc startTimer];
    }];
}

@end
