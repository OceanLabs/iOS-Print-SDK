//
//  InfoPageViewController.m
//  ZenCam
//
//  Created by Konstadinos Karayannis on 11/24/14.
//  Copyright (c) 2014 oceanlabs.co. All rights reserved.
//

#import "OLInfoPageViewController.h"
#import "OLAnalytics.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLAnalytics.h"

@interface OLInfoPageViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIImage *image;

@end

@implementation OLInfoPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.image = [UIImage imageNamedInKiteBundle:self.imageName];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"logo"]];
    CGRect f = self.navigationItem.titleView.frame;
    self.navigationItem.titleView.frame = CGRectMake(f.origin.x, f.origin.y + 25, f.size.width, f.size.height);
    
    [OLAnalytics trackQualityInfoScreenViewed];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackQualityScreenHitBack];
    }
#endif
}

-(void)viewWillAppear:(BOOL)animated{
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
    CGFloat imageStretchFactor =  self.view.frame.size.width / self.image.size.width;
    return self.image.size.height * imageStretchFactor;
}

@end
