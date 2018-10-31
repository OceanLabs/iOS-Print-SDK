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

#import "OLInstagramLoginWebViewController.h"
#import "OLInstagramImagePickerConstants.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"

@import NXOAuth2Client;

@interface OLKitePrintSDK ()
+ (NSString *)instagramRedirectURI;
@end

@interface OLInstagramLoginWebViewController () <UIWebViewDelegate>
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSURL *authURL;
@end

@implementation OLInstagramLoginWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self addInstagramLoginObservers];
    self.title = NSLocalizedStringFromTableInBundle(@"Log In", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    
    self.webView = [[UIWebView alloc] init];
    self.webView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.webView];
    UIView *webView = self.webView;
    self.webView.delegate = self;
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(webView);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    CGFloat topMargin = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height;
    
    NSArray *visuals = @[@"H:|-0-[webView]-0-|",
                         [NSString stringWithFormat:@"V:|-%f-[webView]-0-|", topMargin]];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [webView.superview addConstraints:con];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] init];
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.activityIndicator.color = [UIColor lightGrayColor];
    self.activityIndicator.hidesWhenStopped = YES;
    [self.activityIndicator startAnimating];
    [self.view addSubview:self.activityIndicator];
    
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.activityIndicator attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.activityIndicator attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonCancelClicked)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startAuthenticatingUser];
}

- (void)addInstagramLoginObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onInstagramOAuthAuthenticateFail:) name:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onInstagramOAuthAccountStoreDidChange:) name:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore]];
}

- (void)startAuthenticatingUser {
    self.activityIndicator.hidden = NO;
    [self.webView loadHTMLString:@"" baseURL:nil]; // clear WebView as we may be coming back to it for a second time and don't want any content to be on display.
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"instagram"
                                   withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                       self.authURL = preparedURL;
                                       [self.webView loadRequest:[NSURLRequest requestWithURL:self.authURL]];
                                   }];
}

- (void)onButtonCancelClicked {
    [self.webView stopLoading];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (NSString *)url:(NSURL *)url queryValueForName:(NSString *)name {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *param in [[url query] componentsSeparatedByString:@"&"]) {
        NSArray *parts = [param componentsSeparatedByString:@"="];
        if([parts count] < 2) {
            continue;
        }
        
        [params setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
    }
    
    return params[name];
}

#pragma mark - Instagram Oauth notification callbacks

- (void)onInstagramOAuthAuthenticateFail:(NSNotification *)notification {
    NSString *localizedErrorMessage = NSLocalizedStringFromTableInBundle(@"Failed to log in to Instagram. Please check your internet connectivity and try again", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:localizedErrorMessage preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [self dismissViewControllerAnimated:YES completion:NULL];
    }]];
    [self presentViewController:ac animated:YES completion:NULL];
}

- (void)onInstagramOAuthAccountStoreDidChange:(NSNotification *)notification {
    NXOAuth2Account *account = [notification.userInfo objectForKey:NXOAuth2AccountStoreNewAccountUserInfoKey];
    if (account) {
        // a new account has been created
        [self.imagePicker reloadPageController];
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

#pragma mark - UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([request.URL.absoluteString hasPrefix:[OLKitePrintSDK instagramRedirectURI]]) {
        [self.webView stopLoading];
        BOOL handled = [[NXOAuth2AccountStore sharedStore] handleRedirectURL:request.URL];
        if (!handled) {
            // Show the user a error message.
            NSString *errorReason = [self url:request.URL queryValueForName:@"error_reason"];
            NSString *errorCode = [self url:request.URL queryValueForName:@"error"];
            NSString *errorDescription = [self url:request.URL queryValueForName:@"error_description"];
            
            if ([errorCode isEqualToString:@"access_denied"] && [errorReason isEqualToString:@"user_denied"]) {
                errorDescription = NSLocalizedStringFromTableInBundle(@"You need to authorize the app to access your Instagram account if you want to import photos from there.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
            } else {
                errorDescription = [errorDescription stringByReplacingOccurrencesOfString:@"+" withString:@" "];
                errorDescription = [errorDescription stringByRemovingPercentEncoding];
            }
            
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:errorReason message:errorDescription preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.")  style:UIAlertActionStyleDefault handler:NULL]];
            [self.imagePicker presentViewController:ac animated:YES completion:NULL];
            [self dismissViewControllerAnimated:YES completion:NULL];
        }
        
        return NO;
    }
    self.activityIndicator.hidden = NO;
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.activityIndicator.hidden = YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore]];
}

@end
