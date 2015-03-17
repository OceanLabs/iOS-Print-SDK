//
//  PhotoSelectionButton.h
//  Print Studio
//
//  Created by Elliott Minns on 13/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OLPhotoSelectionButton : UIControl

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, weak) NSString *title;
@property (nonatomic, strong) UIColor *mainColor;

@end
