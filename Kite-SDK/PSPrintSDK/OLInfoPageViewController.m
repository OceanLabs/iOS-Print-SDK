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

#import "OLInfoPageViewController.h"
#import "OLAnalytics.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLAnalytics.h"
#import "OLKiteABTesting.h"
#import "OLImageDownloader.h"

@interface OLInfoPageViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIImage *image;

@end

@implementation OLInfoPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.image = [UIImage imageNamedInKiteBundle:self.imageName];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"logo"]];
    CGRect f = self.navigationItem.titleView.frame;
    self.navigationItem.titleView.frame = CGRectMake(f.origin.x, f.origin.y + 25, f.size.width, f.size.height);
 
    [OLAnalytics trackQualityInfoScreenViewed];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    NSURL *url = [NSURL URLWithString:[OLKiteABTesting sharedInstance].headerLogoURL];
    if (url && ![[OLImageDownloader sharedInstance] cachedDataExistForURL:url]){
        [[OLImageDownloader sharedInstance] downloadImageAtURL:url withCompletionHandler:^(UIImage *image, NSError *error){
            if (error){
                return;
            }
            image = [UIImage imageWithCGImage:image.CGImage scale:2 orientation:image.imageOrientation];
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView *titleImageView = [[UIImageView alloc] initWithImage:image];
                titleImageView.alpha = 0;
                self.navigationItem.titleView = titleImageView;
                titleImageView.alpha = 0;
                [UIView animateWithDuration:0.15 animations:^{
                    titleImageView.alpha = 1;
                }];
            });
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell"];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:10];
    imageView.image = self.image;
    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return self.image.size.height;
}

@end
