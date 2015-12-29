//
//  OLRemoteImageView.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 9/4/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#ifdef COCOAPODS
#import <DACircularProgress/DACircularProgressView.h>
#else
#import "DACircularProgressView.h"
#endif

#import "OLRemoteImageView.h"

@interface OLRemoteImageView ()

@property (strong, nonatomic) DACircularProgressView *loadingView;

@end

@implementation OLRemoteImageView

- (void)initializeViews{
    self.loadingView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    self.loadingView.innerTintColor = [UIColor lightGrayColor];
    self.loadingView.trackTintColor = [UIColor lightGrayColor];
    self.loadingView.progressTintColor = [UIColor whiteColor];
    self.loadingView.thicknessRatio = 1;
    self.loadingView.hidden = YES;
    
    [self addSubview:self.loadingView];
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [self initializeViews];
}

- (instancetype)init{
    self = [super init];
    if (self){
        [self initializeViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self){
        [self initializeViews];
    }
    return self;
}

- (void)setProgress:(float)progress{
    if (progress == 1 && self.loadingView.progress < 0.1){
        self.loadingView.hidden = YES;
        return;
    }
    
    if (progress == 0){
        progress = 0.05;
    }
    
    self.loadingView.hidden = NO;
    [self.loadingView setProgress:progress animated:YES];
    
    if (progress == 1){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.loadingView.hidden = YES;
        });
    }
}

@end
