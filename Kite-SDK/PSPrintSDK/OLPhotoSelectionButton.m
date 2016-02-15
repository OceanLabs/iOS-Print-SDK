//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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
    NSBundle *currentBundle = [NSBundle bundleForClass:[OLPhotoSelectionButton class]];
    self.contentView =  [currentBundle loadNibNamed:@"OLPhotoSelectionButton" owner:self options:nil][0];
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
