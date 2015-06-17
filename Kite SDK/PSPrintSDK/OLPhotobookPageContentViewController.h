//
//  OLPhotobookPageViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/17/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OLPhotobookPageContentViewController : UIViewController

@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (assign, nonatomic) NSInteger pageIndex;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (assign, nonatomic) BOOL editMode;
@property (weak, nonatomic) UIView *selectedView;

- (void)loadImage;
- (void)userDidTapOnViewWithPoint:(CGPoint)p;
- (void)deselectSelected;

@end
