//
//  CameraSelectionButton.m
//  Print Studio
//
//  Created by Elliott Minns on 13/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import "OLPhotoSelectionButton.h"

@interface OLPhotoSelectionButton()
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *imageViewHeight;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIColor *textColor;
@end

@implementation OLPhotoSelectionButton

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupView];
        self.mainColor = self.tintColor;
    }
    return self;
}

- (void)setMainColor:(UIColor *)mainColor {
    self.tintColor = [UIColor whiteColor];
    _mainColor = mainColor;
    self.highlighted = NO;
}

- (void)setupView {
    self.contentView =  [[NSBundle mainBundle] loadNibNamed:@"OLPhotoSelectionButton" owner:self options:nil][0];
    self.contentView.backgroundColor = [UIColor whiteColor];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_contentView);
    [self addSubview:_contentView];

    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_contentView]-0-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_contentView]-0-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
    self.imageViewHeight.constant = roundf(self.frame.size.height / 2);
    self.textColor = self.titleLabel.textColor;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setHighlighted:YES];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setHighlighted:NO];
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setHighlighted:NO];
    [super touchesCancelled:touches withEvent:event];
}

- (void)setImage:(UIImage *)image {
    UIImage *tintImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.imageView setImage:tintImage];
}

- (UIImage *)image {
    return self.image;
}

- (void)setTitle:(NSString *)title {
    title = [title uppercaseString];
    NSMutableAttributedString *titleText = [[NSMutableAttributedString alloc] initWithString:title];
    self.titleLabel.attributedText = titleText;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (NSString *)title {
    return self.titleLabel.attributedText.string;
}

- (void)setHighlighted:(BOOL)highlighted {
    if (highlighted) {
        self.tintColor = self.mainColor;
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.titleLabel.textColor = self.textColor;
    } else {
        self.contentView.backgroundColor = self.mainColor;
        self.tintColor = [UIColor whiteColor];
        self.titleLabel.textColor = [UIColor whiteColor];
    }

    [super setHighlighted:highlighted];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"state"]) {
        if (self.state == UIControlStateHighlighted) {
            
        }
    }
}

@end
