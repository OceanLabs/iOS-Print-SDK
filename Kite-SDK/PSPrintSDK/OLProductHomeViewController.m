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


#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLAsset+Private.h"
#import "OLHPSDKWrapper.h"
#import "OLImageDownloader.h"
#import "OLInfoPageViewController.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLMarkdownParser.h"
#import "OLNavigationController.h"
#import "OLProduct.h"
#import "OLProductGroup.h"
#import "OLProductHomeViewController.h"
#import "OLProductOverviewViewController.h"
#import "OLProductTemplate.h"
#import "OLProductTypeSelectionViewController.h"
#import "OLUserSession.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIImage+OLUtils.h"
#import "UIImageView+FadeIn.h"
#import "UIViewController+OLMethods.h"
#import "OLKiteViewController+Private.h"
#import "UIView+AutoLayoutHelper.h"

@interface OLProductTypeSelectionViewController ()
-(NSMutableArray *) products;
@property (strong, nonatomic) NSMutableDictionary *collections;
@end


@interface OLProductHomeViewController () <UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) NSArray *productGroups;
@property (nonatomic, strong) UIImageView *topSurpriseImageView;
@property (assign, nonatomic) BOOL fromRotation;
@property (strong, nonatomic) UIView *bannerView;
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) NSString *bannerString;
@property (strong, nonatomic) NSDate *countdownDate;
@end

@implementation OLProductHomeViewController

- (NSArray *)productGroups {
    if (!_productGroups){
        _productGroups = [OLProductGroup groupsWithFilters:self.filterProducts];
    }
    
    return _productGroups;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }

    [OLAnalytics trackCategoryListScreenViewed];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    NSURL *url = [NSURL URLWithString:[OLKiteABTesting sharedInstance].headerLogoURL];
    if (!url && [self isMemberOfClass:[OLProductHomeViewController class]]){
        if ([self isPushed]){
            self.parentViewController.title = NSLocalizedStringFromTableInBundle(@"Print Shop", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        }
        else{
            self.title = NSLocalizedStringFromTableInBundle(@"Print Shop", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        }
    }
    
    if ([self isPushed]){
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.collectionView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
    }
    
    [self setupBannerView];
    
    if ([OLKiteABTesting sharedInstance].lightThemeSecretRevealURL){
        [[OLImageDownloader sharedInstance] downloadImageAtURL:[NSURL URLWithString:[OLKiteABTesting sharedInstance].lightThemeSecretRevealURL] withCompletionHandler:^(UIImage *image, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.topSurpriseImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
                self.topSurpriseImageView.image = image;
                CGRect f = self.topSurpriseImageView.frame;
                
                f.size.height = (self.view.frame.size.width / f.size.width) * f.size.height;
                f.size.width = self.view.frame.size.width;
                
                f.origin.y = -f.size.height;
                self.topSurpriseImageView.frame = f;
                self.topSurpriseImageView.contentMode = UIViewContentModeScaleAspectFill;
                self.topSurpriseImageView.clipsToBounds = YES;
                
                [self.collectionView addSubview:self.topSurpriseImageView];
            });
        }];
    }
    
    if ([OLKitePrintSDK isKiosk]){
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc] init]];
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    if (self.topSurpriseImageView){
        CGRect f = self.topSurpriseImageView.frame;
        
        f.size.height = (self.view.frame.size.width / f.size.width) * f.size.height;
        f.size.width = self.view.frame.size.width;
        
        f.origin.y = -f.size.height;
        self.topSurpriseImageView.frame = f;
    }
}

- (void)setupBannerView{
    self.bannerString = [OLKiteABTesting sharedInstance].promoBannerText;
    NSRange countdownDateRange = [self.bannerString rangeOfString:@"\\[\\[.*\\]\\]" options:NSRegularExpressionSearch];
    if (countdownDateRange.location != NSNotFound){
        NSString *countdownString = [self.bannerString substringWithRange:countdownDateRange];
        countdownString = [countdownString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm O"];
        
        self.countdownDate = [dateFormatter dateFromString:countdownString];
        
        if (self.countdownDate){
            [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateCounter:) userInfo:nil repeats:YES];
        }
    }
    
    if ([self promoBannerParaText]){
        self.bannerView = [[UIView alloc] init];
        UIView *bannerView = self.bannerView;
        bannerView.backgroundColor = [UIColor colorWithRed: 0.918 green: 0.11 blue: 0.376 alpha: 1];
        
        bannerView.layer.shadowColor = [[UIColor blackColor] CGColor];
        bannerView.layer.shadowOpacity = .3;
        bannerView.layer.shadowOffset = CGSizeMake(0,-2);
        bannerView.layer.shadowRadius = 2;
        
        UILabel *label = [[UILabel alloc] init];
        [bannerView addSubview:label];
        
        [self.navigationController.view addSubview:bannerView];
        
        bannerView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(bannerView);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[bannerView]-0-|",
                             @"V:[bannerView(40)]"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [bannerView.superview addConstraints:con];
        
        [self.navigationController.view addConstraint:[NSLayoutConstraint constraintWithItem:bannerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.navigationController.view attribute:NSLayoutAttributeBottom multiplier:1 constant:70]];
        
        if ([self promoBannerHeaderText]){
            self.headerView = [[UIView alloc] init];
            [self.bannerView addSubview:self.headerView];
            
            UIView *headerView = self.headerView;
            headerView.translatesAutoresizingMaskIntoConstraints = NO;
            NSDictionary *views = NSDictionaryOfVariableBindings(headerView);
            NSMutableArray *con = [[NSMutableArray alloc] init];
            
            NSArray *visuals = @[@"H:[headerView(125)]",
                                 @"V:|-(-20)-[headerView(30)]"];
            
            
            for (NSString *visual in visuals) {
                [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
            }
            
            [con addObject:[NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:headerView.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
            
            [headerView.superview addConstraints:con];
            
            headerView.layer.shadowColor = [[UIColor blackColor] CGColor];
            headerView.layer.shadowOpacity = .3;
            headerView.layer.shadowOffset = CGSizeMake(0,2);
            headerView.layer.shadowRadius = 2;
            
            UILabel *headerLabel = [[UILabel alloc] init];
            headerLabel.tag = 20;
            headerLabel.backgroundColor = [UIColor colorWithRed: 0.259 green: 0.675 blue: 0.827 alpha: 1];
            headerLabel.adjustsFontSizeToFitWidth = YES;
            headerLabel.minimumScaleFactor = 0.5;
            headerLabel.textAlignment = NSTextAlignmentCenter;
            headerLabel.layer.borderWidth = 5;
            headerLabel.layer.borderColor = headerLabel.backgroundColor.CGColor;
            
            UIBezierPath* bezierPath = [UIBezierPath bezierPath];
            [bezierPath moveToPoint: CGPointMake(0, 0)];
            [bezierPath addLineToPoint: CGPointMake(125, 0)];
            [bezierPath addLineToPoint: CGPointMake(125, 25)];
            [bezierPath addLineToPoint: CGPointMake(62.5, 30)];
            [bezierPath addLineToPoint: CGPointMake(0, 25)];
            [bezierPath closePath];
            
            CAShapeLayer *shape=[CAShapeLayer layer];
            shape.path=bezierPath.CGPath;
            headerLabel.layer.mask = shape;
            
            [headerView addSubview:headerLabel];
            
            headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
            views = NSDictionaryOfVariableBindings(headerLabel);
            con = [[NSMutableArray alloc] init];
            
            visuals = @[@"H:|-0-[headerLabel]-0-|",
                        @"V:|-0-[headerLabel]-0-|"];
            
            
            for (NSString *visual in visuals) {
                [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
            }
            
            [headerLabel.superview addConstraints:con];
        }
        [self setupBannerLabel:label];
    }
}

- (NSString *)promoBannerParaText{
    NSString *originalString = self.bannerString;
    if (!originalString || [originalString isEqualToString:@""]){
        return nil;
    }
    NSRange paraRange = [originalString rangeOfString:@"<para>.*<\\/para>" options:NSRegularExpressionSearch | NSCaseInsensitiveSearch];
    if (paraRange.location != NSNotFound){
        NSString *s = [originalString substringWithRange:paraRange];
        s = [s stringByReplacingOccurrencesOfString:@"<para>" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, s.length)];
        return [s stringByReplacingOccurrencesOfString:@"</para>" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, s.length)];
    }
    
    return originalString;
}

- (NSString *)promoBannerHeaderText{
    NSString *originalString = self.bannerString;
    if (!originalString || [originalString isEqualToString:@""]){
        return nil;
    }
    NSRange headerRange = [originalString rangeOfString:@"<header>.*<\\/header>" options:NSRegularExpressionSearch | NSCaseInsensitiveSearch];
    if (headerRange.location != NSNotFound){
        NSString *s = [originalString substringWithRange:headerRange];
        s = [s stringByReplacingOccurrencesOfString:@"<header>" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, s.length)];
        return [s stringByReplacingOccurrencesOfString:@"</header>" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, s.length)];
    }
    
    return nil;
}

- (void)setupBannerLabel:(UILabel *)label{
    label.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(label);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[label]-0-|",
                         @"V:|-0-[label]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [label.superview addConstraints:con];
    
    label.tag = 10;
    label.minimumScaleFactor = 0.5;
    label.adjustsFontSizeToFitWidth = YES;
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 3;
    
    NSString *s = [self promoBannerParaText];
    if (!s || [s isEqualToString:@""]){
        [self.bannerView removeFromSuperview];
        self.bannerView = nil;
        return;
    }
    
    [self updateBannerString];
}

- (void)updateBannerString{
    NSString *s = [OLKiteABTesting sharedInstance].promoBannerText;
    if (self.countdownDate){
        NSUInteger flags = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay;
        NSDateComponents *components = [[NSCalendar currentCalendar] components:flags fromDate:[NSDate date] toDate:self.countdownDate options:0];
        if ([NSDateComponentsFormatter class]){
            NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
            formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleAbbreviated;
            formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorNone;
            formatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay;
            s = [formatter stringFromDateComponents:components];
        }
        else{
            s = [NSString stringWithFormat:@"%ld days, %ld:%ld:%ld", (long)components.day, (long)components.hour, (long)components.minute, (long)components.second];
        }
        
        NSRange countdownDateRange = [[OLKiteABTesting sharedInstance].promoBannerText rangeOfString:@"\\[\\[.*\\]\\]" options:NSRegularExpressionSearch];
        if (countdownDateRange.location != NSNotFound){
            s = [[OLKiteABTesting sharedInstance].promoBannerText stringByReplacingCharactersInRange:countdownDateRange withString:s];
        }
    }
    self.bannerString = s;
    
    s = [self promoBannerParaText];
    if (s){
        NSMutableAttributedString *attributedString = [[[OLMarkDownParser standardParser] attributedStringFromMarkdown:s] mutableCopy];
        
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attributedString.length)];
        
        
        UILabel *label = (UILabel *)[self.bannerView viewWithTag:10];
        label.attributedText = attributedString;
    }
    
    s = [self promoBannerHeaderText];
    if (s){
        NSMutableAttributedString *headerString = [[[OLMarkDownParser standardParser] attributedStringFromMarkdown:s] mutableCopy];
        
        [headerString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, headerString.length)];
        UILabel *label = (UILabel *)[self.bannerView viewWithTag:20];
        label.attributedText = headerString;
    }
}

- (void)updateCounter:(NSTimer *)theTimer {
    NSDate *now = [NSDate date];
    // has the target time passed?
    if ([self.countdownDate earlierDate:now] == self.countdownDate) {
        [theTimer invalidate];
        [UIView animateWithDuration:0.25 animations:^{
            self.bannerView.transform = CGAffineTransformMakeTranslation(0, 0);
            [self.collectionView setContentInset:UIEdgeInsetsMake(self.collectionView.contentInset.top, 0, 0, 0)];
        }completion:^(BOOL finished){
            [self.bannerView removeFromSuperview];
            self.bannerView = nil;
            self.bannerView.transform = CGAffineTransformIdentity;
        }];
    } else {
        [self updateBannerString];
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isPushed]){
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.collectionView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
    }
    [self addBasketIconToTopRight];
    [(PhotobookNavigationBar *)self.navigationController.navigationBar setBarType:PhotobookNavigationBarTypeWhite];
    
    if ([OLUserSession currentSession].deeplink){
        NSString *deeplink = [[OLUserSession currentSession].deeplink lowercaseString];
        [OLUserSession currentSession].deeplink = nil;
        
        OLProduct *product;
        for (OLProduct *p in [OLProduct products]){
            if ([[p.templateId lowercaseString] isEqualToString:deeplink]){
                product = p;
            }
        }
        if (product){
            UIViewController *vc = [[OLUserSession currentSession].kiteVc productDescriptionViewController];
            [(OLProductOverviewViewController *)vc setProduct:product];
            [self.navigationController pushViewController:vc animated:NO];
        }
        else{
            for (OLProductGroup *group in self.productGroups){
                if ([[group.templateClass lowercaseString] isEqualToString:deeplink]){
                    OLProduct *product = [group.products firstObject];
                    product.uuid = nil;
                    
                    id vc = [[OLUserSession currentSession].kiteVc viewControllerForGroupSelected:group];
                    [vc safePerformSelector:@selector(setProduct:) withObject:product];
                    [vc safePerformSelector:@selector(setTemplateClass:) withObject:product.productTemplate.templateClass];
                    [self.navigationController pushViewController:vc animated:NO];
                    break;
                }
            }
        }
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    NSURL *url = [NSURL URLWithString:[OLKiteABTesting sharedInstance].headerLogoURL];
    if (url && ![[OLImageDownloader sharedInstance] cachedDataExistForURL:url] && !([self.navigationItem.titleView isKindOfClass:[UIImageView class]] || [self.parentViewController.navigationItem.titleView isKindOfClass:[UIImageView class]])){
        [[OLImageDownloader sharedInstance] downloadImageAtURL:url withCompletionHandler:^(UIImage *image, NSError *error){
            if (error){
                return;
            }
            image = [UIImage imageWithCGImage:image.CGImage scale:2 orientation:image.imageOrientation];
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView *titleImageView = [[UIImageView alloc] initWithImage:image];
                titleImageView.alpha = 0;
                if ([self isPushed]){
                    self.parentViewController.navigationItem.titleView = titleImageView;
                }
                else{
                    self.navigationItem.titleView = titleImageView;
                }
                titleImageView.alpha = 0;
                [UIView animateWithDuration:0.5 animations:^{
                    titleImageView.alpha = 1;
                }];
            });
        }];
    }
    
    NSDate *now = [NSDate date];
    // has the target time passed?
    if (self.countdownDate && [self.countdownDate earlierDate:now] == self.countdownDate) {
        [self.bannerView removeFromSuperview];
        self.bannerView = nil;
    }
    
    if (self.bannerView){
        self.bannerView.hidden = NO;
        [UIView animateWithDuration:0.25 animations:^{
            self.bannerView.transform = CGAffineTransformMakeTranslation(0, -70);
            [self.collectionView setContentInset:UIEdgeInsetsMake(self.collectionView.contentInset.top, 0, 40, 0)];
        }completion:NULL];
    }
    
    if ([OLKitePrintSDK isKiosk]){
        self.navigationController.viewControllers = @[self];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    if (self.bannerView){
        [UIView animateWithDuration:0.25 animations:^{
            self.bannerView.transform = CGAffineTransformMakeTranslation(0, 0);
            [self.collectionView setContentInset:UIEdgeInsetsMake(self.collectionView.contentInset.top, 0, 0, 0)];
        }completion:^(BOOL finished){
            self.bannerView.hidden = YES;
            self.bannerView.transform = CGAffineTransformIdentity;
        }];
    }
}
- (IBAction)onInfoButtonTapped:(UIButton *)sender {
    CGPoint buttonPosition = [sender.superview convertPoint:CGPointZero toView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:buttonPosition];
    
    OLProduct *product = [self.productGroups[indexPath.item] products].firstObject;
    
    OLProductOverviewViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
    vc.delegate = self.delegate;
    [vc safePerformSelector:@selector(setProduct:) withObject:product];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    self.fromRotation = YES;
    NSArray *visibleCells = [self.collectionView indexPathsForVisibleItems];
    NSIndexPath *maxIndexPath = [visibleCells firstObject];
    for (NSIndexPath *indexPath in visibleCells){
        if (maxIndexPath.item < indexPath.item){
            maxIndexPath = indexPath;
        }
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        if ([self isPushed]){
            self.automaticallyAdjustsScrollViewInsets = NO;
            self.collectionView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
        }
        
        [self.collectionView.collectionViewLayout invalidateLayout];
        [self addBasketIconToTopRight];
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView reloadData];
    }];
}

- (void)templateSyncDidUpdate{
    self.productGroups = nil;
    
    if (![OLProductTemplate isSyncInProgress] || self.navigationController.topViewController != self || self.presentedViewController){
        [self.collectionView reloadData];
        return;
    }
    
    NSUInteger section = 0;
    if ([self includeBannerSection]){
        section++;
    }
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSInteger i = [self.collectionView numberOfItemsInSection:section]; i < [self collectionView:self.collectionView numberOfItemsInSection:section]; i++){
        [array addObject:[NSIndexPath indexPathForItem:i inSection:section]];
    }
    
    [self.collectionView insertItemsAtIndexPaths:array];
}

#pragma mark Banner Section

- (BOOL)printAtHomeAvailable{
    Class MPPrintItemFactoryClass = NSClassFromString (@"MPPrintItemFactory");
    BOOL printAtHomeAvailable = [MPPrintItemFactoryClass class] && [OLUserSession currentSession].kiteVc.showPrintAtHome;
    return printAtHomeAvailable && [OLUserSession currentSession].appAssets.firstObject;
}

- (BOOL)includeBannerSection{
    return [self printAtHomeAvailable] || ![[OLKiteABTesting sharedInstance].qualityBannerType isEqualToString:@"None"];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView bannerSectionCellForIndexPath:(NSIndexPath *)indexPath{
    if ([self printAtHomeAvailable]){
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PrintAtHomeCell" forIndexPath:indexPath];
        UILabel *ctaLabel = [cell viewWithTag:300];
        ctaLabel.text = NSLocalizedStringFromTableInBundle(@"PRINT AT HOME", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        
        UILabel *orLabel = [cell viewWithTag:400];
        orLabel.text = NSLocalizedStringFromTableInBundle(@"Or print on a product below ▼", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        
        return cell;
    }
    else if ([[OLUserSession currentSession].kiteVc.delegate respondsToSelector:@selector(viewForHeaderWithWidth:)]){
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"qualityBanner" forIndexPath:indexPath];
        UIView *view = [cell viewWithTag:10];
        [view removeFromSuperview];
        
        view = [[OLUserSession currentSession].kiteVc.delegate viewForHeaderWithWidth:self.view.frame.size.width];
        [cell.contentView addSubview:view];
        [view fillSuperView];
        
        view.tag = 10;
        
        return cell;
    }
    else{
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"qualityBanner" forIndexPath:indexPath];
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:10];
        imageView.image = [UIImage imageNamedInKiteBundle:[NSString stringWithFormat:@"quality-banner%@", [OLKiteABTesting sharedInstance].qualityBannerType]];
            imageView.backgroundColor = [imageView.image colorAtPixel:CGPointMake(3, 3)];
        return cell;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView sizeForBannerSectionCellForIndexPath:(NSIndexPath *)indexPath{
    CGSize size = self.view.frame.size;
    
    if ([OLUserSession currentSession].prioritizeMainBundleImages){
        UIImage *image = [UIImage imageNamedInKiteBundle:[NSString stringWithFormat:@"quality-banner%@", [OLKiteABTesting sharedInstance].qualityBannerType]];
        if (image.size.width > self.view.frame.size.width){
            image = [image shrinkToSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.width * (image.size.height / image.size.width)) forScreenScale:[UIScreen mainScreen].scale aspectFit:YES];
        }
        return CGSizeMake(size.width, image.size.height);
    }
    
    CGFloat height = [self printAtHomeAvailable] ? 233 : 110;
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact && size.height > size.width){
        height = (self.view.frame.size.width * height) / 375.0;
    }
    return CGSizeMake(self.view.frame.size.width, height);
}

- (void)collectionView:(UICollectionView *)collectionView actionForBannerSectionForIndexPath:(NSIndexPath *)indexPath{
    if ([self printAtHomeAvailable]){
        [OLAnalytics trackPrintAtHomeTapped];
        OLAsset *asset = [OLUserSession currentSession].appAssets.firstObject;
        [asset dataWithCompletionHandler:^(NSData *data, NSError *error){
            id printItem = [OLHPSDKWrapper printItemWithAsset:[UIImage imageWithData:data scale:1]];
            dispatch_async(dispatch_get_main_queue(), ^{
                UIViewController *vc = [OLHPSDKWrapper printViewControllerWithDelegate:self dataSource:[OLUserSession currentSession].kiteVc.delegate printItem:printItem fromQueue:NO settingsOnly:NO];
                [self.navigationController presentViewController:vc animated:YES completion:NULL];
            });
        }];
    }
    else if ([[OLUserSession currentSession].kiteVc.delegate respondsToSelector:@selector(infoPageViewController)]){
        UIViewController *vc = [[OLUserSession currentSession].kiteVc.delegate infoPageViewController];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
        OLInfoPageViewController *vc = (OLInfoPageViewController *)[OLUserSession currentSession].kiteVc.infoViewController;
        [vc safePerformSelector:@selector(setImageName:) withObject:@"quality"];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInBannerSection:(NSInteger)section{
    return 1;
}

#pragma mark - UICollectionViewDelegate Methods

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize size = self.view.frame.size;
    NSInteger productSection = [self includeBannerSection] ? 1 : 0;
    if (indexPath.section == 0 && [self includeBannerSection]){
        return [self collectionView:collectionView sizeForBannerSectionCellForIndexPath:indexPath];
    }
    else if (indexPath.section == productSection + 1){
        return CGSizeMake(size.width, 40);
    }
    
    NSInteger numberOfCells = [self collectionView:collectionView numberOfItemsInSection:indexPath.section];
    CGFloat halfScreenHeight = (size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - self.navigationController.navigationBar.frame.size.height)/2;
    
    CGFloat height = 233;
    
    if([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"ThemeColor"]){
        height = 200;
    }
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact && size.height > size.width) {
        if (numberOfCells == 2){
            return CGSizeMake(size.width, halfScreenHeight);
        }
        else{
            return CGSizeMake(size.width, height * (size.width / 320.0));
        }
    }
    else if (numberOfCells == 6){
        return CGSizeMake(size.width/2 - 1, MAX(halfScreenHeight * (2.0 / 3.0), height));
    }
    else if (numberOfCells == 4){
        return CGSizeMake(size.width/2 - 1, MAX(halfScreenHeight, height));
    }
    else if (numberOfCells == 3){
        if (size.width < size.height){
            return CGSizeMake(size.width, halfScreenHeight * 0.8);
        }
        else{
            return CGSizeMake(size.width/2 - 1, MAX(halfScreenHeight, height));
        }
    }
    else if (numberOfCells == 2){
        if (size.width < size.height){
            return CGSizeMake(size.width, halfScreenHeight);
        }
        else{
            return CGSizeMake(size.width/2 - 1, halfScreenHeight);
        }
    }
    else{
        return CGSizeMake(size.width/2 - 1, height);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0 && [self includeBannerSection]){
        [self collectionView:collectionView actionForBannerSectionForIndexPath:indexPath];
        return;
    }
    
    UIViewController *vc = [self viewControllerForItemAtIndexPath:indexPath];
    if (vc){
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (UIViewController *)viewControllerForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0 && [self includeBannerSection]){
        return nil;
    }
    if (indexPath.item >= self.productGroups.count){
        return nil;
    }
    
    OLProductGroup *group = self.productGroups[indexPath.row];
    OLProduct *product = [group.products firstObject];
    product.uuid = nil;
    
    id vc = [[OLUserSession currentSession].kiteVc viewControllerForGroupSelected:group];
    [vc safePerformSelector:@selector(setProduct:) withObject:product];
    
    if ([vc isKindOfClass:[OLProductTypeSelectionViewController class]] && product.productTemplate.collectionName && product.productTemplate.collectionId){
        [vc safePerformSelector:@selector(setTemplateClass:) withObject:product.productTemplate.templateClass];
        [vc products];
        NSMutableArray *options = [[NSMutableArray alloc] init];
        for (NSString *templateId in ((OLProductTypeSelectionViewController *)vc).collections[[product.productTemplate.collectionId stringByAppendingString:product.productTemplate.collectionName]]){
            OLProductTemplate *template = [OLProductTemplate templateWithId:templateId];
            if (!template){
                continue;
            }
            OLProduct *otherProduct = [[OLProduct alloc] initWithTemplate:template];
            [options addObject:@{
                                 @"code" : otherProduct.productTemplate.identifier,
                                 @"name" : [NSString stringWithFormat:@"%@", [otherProduct dimensions]],
                                 }];
        }
        
        OLProductTemplateOption *collectionOption =
        [[OLProductTemplateOption alloc] initWithDictionary:@{
                                                              @"code" : product.productTemplate.collectionId,
                                                              @"name" : product.productTemplate.collectionName,
                                                              @"options" : options
                                                              }];
        collectionOption.iconImageName = @"tool-size";
        for (OLProductTemplateOption *option in product.productTemplate.options){
            if ([option.code isEqualToString:collectionOption.code]){
                [(NSMutableArray *)product.productTemplate.options removeObjectIdenticalTo:option];
            }
        }
        [(NSMutableArray *)product.productTemplate.options addObject:collectionOption];
        
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
        [vc safePerformSelector:@selector(setProduct:) withObject:product];
    }
    
    [vc safePerformSelector:@selector(setDelegate:) withObject:self.delegate];
    [vc safePerformSelector:@selector(setFilterProducts:) withObject:self.filterProducts];
    [vc safePerformSelector:@selector(setTemplateClass:) withObject:product.productTemplate.templateClass];
    
    return vc;
}

#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    if (self.isOffScreen){
        return 0;
    }
    
    NSInteger numberOfSections = [self includeBannerSection] ? 2 : 1;
    if ([OLProductTemplate isSyncInProgress]){
        numberOfSections++;
    }
    return numberOfSections;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger productSection = [self includeBannerSection] ? 1 : 0;
    if (section == 0 && [self includeBannerSection]){
        return [self collectionView:collectionView numberOfItemsInBannerSection:section];
    }
    else if (section == productSection + 1){
        return 1;
    }
    
    NSInteger extras = 0;
    NSInteger numberOfProducts = [self.productGroups count];
    
    CGSize size = self.view.frame.size;
    if ([OLProductTemplate isSyncInProgress] || (!numberOfProducts % 2 != 0 && (self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact || size.height < size.width))){
        extras = 1;
    }
    
    return numberOfProducts + extras;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger productSection = [self includeBannerSection] ? 1 : 0;
    if (indexPath.section == 0 && [self includeBannerSection]){
        return [self collectionView:collectionView bannerSectionCellForIndexPath:indexPath];
    }
    else if (indexPath.section == productSection + 1){
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"loadingCell" forIndexPath:indexPath];
        UIActivityIndicatorView *activity = [cell viewWithTag:10];
        [activity startAnimating];
        return cell;
    }
    
    if (indexPath.item >= self.productGroups.count){
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"extraCell" forIndexPath:indexPath];
        UILabel *label = [cell.contentView viewWithTag:50];
        label.text = NSLocalizedStringFromTableInBundle(@"MORE ITEMS\nCOMING SOON!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        return cell;
    }
    
    NSString *identifier = [NSString stringWithFormat:@"ProductCell%@", [OLKiteABTesting sharedInstance].productTileStyle];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *cellImageView = (UIImageView *)[cell.contentView viewWithTag:40];
    cellImageView.image = nil;
    
    OLProductGroup *group = self.productGroups[indexPath.item];
    OLProduct *product = [group.products firstObject];
    
    CGSize size = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
    [cellImageView setAndFadeInImageWithOLAsset:[product classImageAsset] size:size applyEdits:NO placeholder:nil progress:nil completionHandler:NULL];
    
    UILabel *productTypeLabel = (UILabel *)[cell.contentView viewWithTag:300];
    
    productTypeLabel.text = product.productTemplate.templateClass;
    
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        productTypeLabel.font = font;
    }
    
    UIActivityIndicatorView *activityIndicator = (id)[cell.contentView viewWithTag:41];
    [activityIndicator startAnimating];
    
    if ([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"Classic"]){
        productTypeLabel.backgroundColor = [product labelColor];
    }
    else if([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"MinimalWhite"]){
        UILabel *priceLabel = [cell.contentView viewWithTag:301];
        UILabel *detailsLabel = [cell.contentView viewWithTag:302];
        
        priceLabel.text = @"";
        
        UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
        if (font){
            detailsLabel.font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:15];
        }
        
        NSMutableAttributedString *attributedString = [[[OLMarkDownParser standardParser] attributedStringFromMarkdown:product.productTemplate.productDescription] mutableCopy];
        detailsLabel.text = attributedString.string;
        
        if (![OLKiteABTesting sharedInstance].skipProductOverview){
            [[cell.contentView viewWithTag:303] removeFromSuperview];
        }
    }
    else if([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"ThemeColor"]){
        if ([OLKiteABTesting sharedInstance].lightThemeColor1){
            UILabel *detailsLabel = [cell.contentView viewWithTag:302];
            detailsLabel.backgroundColor = [OLKiteABTesting sharedInstance].lightThemeColor1;
        }
    }
    else{
        UIButton *button = (UIButton *)[cell.contentView viewWithTag:390];
        if (button.layer.shadowOpacity == 0){
            button.layer.shadowColor = [[UIColor blackColor] CGColor];
            button.layer.shadowOpacity = .3;
            button.layer.shadowOffset = CGSizeMake(0,2);
            button.layer.shadowRadius = 2;
            
            [button addTarget:self action:@selector(onButtonCallToActionTapped:) forControlEvents:UIControlEventTouchUpInside];
        }
        button.backgroundColor = [product labelColor];
    }
    
    return cell;
}

- (void)onButtonCallToActionTapped:(UIButton *)sender{
    UIView *view = sender.superview;
    while (![view isKindOfClass:[UICollectionViewCell class]]){
        view = view.superview;
    }
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)view];
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}

#pragma mark Print At Home delegate methods

- (void)didCancelPrintFlow:(UIViewController *)printViewController{
    id delegate = [OLUserSession currentSession].kiteVc.delegate;
    if ([delegate respondsToSelector:@selector(didCancelPrintFlow:)]){
        [delegate safePerformSelector:@selector(didCancelPrintFlow:) withObject:printViewController];
    }
    else{
        [printViewController dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)didFinishPrintFlow:(UIViewController *)printViewController{
    id delegate = [OLUserSession currentSession].kiteVc.delegate;
    if ([delegate respondsToSelector:@selector(didFinishPrintFlow:)]){
        [delegate safePerformSelector:@selector(didFinishPrintFlow:) withObject:printViewController];
    }
    else{
        [printViewController dismissViewControllerAnimated:YES completion:NULL];
    }
}


@end
