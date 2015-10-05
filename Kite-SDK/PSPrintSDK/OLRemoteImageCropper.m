//
//  OLRemoteImageCropper.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 9/8/15.
//  Copyright © 2015 Deon Botha. All rights reserved.
//

#import "OLRemoteImageCropper.h"
#import "OLRemoteImageView.h"

@interface OLRemoteImageCropper ()

@property (strong, nonatomic) OLRemoteImageView *remoteImageView;

@end

@implementation OLRemoteImageCropper

- (void)initializeViews{
    self.remoteImageView = [[OLRemoteImageView alloc] init];
    [self addSubview:self.remoteImageView];
    
    UIView *view = self.remoteImageView;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
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
    [self.remoteImageView setProgress:progress];
}

@end
