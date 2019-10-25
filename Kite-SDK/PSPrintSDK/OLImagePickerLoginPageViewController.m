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

#import "OLImagePickerLoginPageViewController.h"
#import "UIView+RoundRect.h"
#import "OLImagePickerViewController.h"
#import "OLKitePrintSDK.h"
#import "OLNavigationController.h"
#import "OLKiteUtils.h"
#import "OLKiteABTesting.h"

@interface OLImagePickerLoginPageViewController ()
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *label;
@end



@implementation OLImagePickerLoginPageViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    NSString *providerName;
    if (self.provider.providerType == OLImagePickerProviderTypePhotoLibrary){
        providerName = [UIDevice currentDevice].localizedModel;
        [self.loginButton setTitle:NSLocalizedStringFromTableInBundle(@"Authorise", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    }
    self.label.text = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"We need access to your %@ photos", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Example: We need access to your iPhone photos"), providerName];
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self.loginButton makeRoundRectWithRadius:self.loginButton.frame.size.height / 2.0];
    if ([OLKiteABTesting sharedInstance].lightThemeColor2){
        self.loginButton.backgroundColor = [OLKiteABTesting sharedInstance].lightThemeColor2;
    }
    
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        self.label.font = font;
    }
    
    font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:15];
    if (font){
        [self.loginButton.titleLabel setFont:font];
    }
    
}

- (IBAction)onButtonLoginTapped:(UIButton *)sender {
    if (self.provider.providerType == OLImagePickerProviderTypePhotoLibrary){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:NULL];
    }
}

@end
