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
#import "OLTextOnPhoto.h"

static NSString *const kKeyTextOnPhotoText = @"co.oceanlabs.psprintstudio.kKeyTextOnPhotoText";
static NSString *const kKeyTextOnPhotoFrame = @"co.oceanlabs.psprintstudio.kKeyTextOnPhotoFrame";
static NSString *const kKeyTextOnPhotoTransform = @"co.oceanlabs.psprintstudio.kKeyTextOnPhotoTransform";
static NSString *const kKeyTextOnPhotoColor = @"co.oceanlabs.psprintstudio.kKeyTextOnPhotoColor";
static NSString *const kKeyTextOnPhotoFontName = @"co.oceanlabs.psprintstudio.kKeyTextOnPhotoFontName";
static NSString *const kKeyTextOnPhotoFontSize = @"co.oceanlabs.psprintstudio.kKeyTextOnPhotoFontSize";

@implementation OLTextOnPhoto

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.text forKey:kKeyTextOnPhotoText];
    [aCoder encodeCGRect:self.frame forKey:kKeyTextOnPhotoFrame];
    [aCoder encodeCGAffineTransform:self.transform forKey:kKeyTextOnPhotoTransform];
    [aCoder encodeObject:self.color forKey:kKeyTextOnPhotoColor];
    [aCoder encodeObject:self.fontName forKey:kKeyTextOnPhotoFontName];
    [aCoder encodeDouble:self.fontSize forKey:kKeyTextOnPhotoFontSize];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.text = [aDecoder decodeObjectForKey:kKeyTextOnPhotoText];
        self.frame = [aDecoder decodeCGRectForKey:kKeyTextOnPhotoFrame];
        self.transform = [aDecoder decodeCGAffineTransformForKey:kKeyTextOnPhotoTransform];
        self.color = [aDecoder decodeObjectForKey:kKeyTextOnPhotoColor];
        self.fontSize = [aDecoder decodeDoubleForKey:kKeyTextOnPhotoFontSize];
        self.fontName = [aDecoder decodeObjectForKey:kKeyTextOnPhotoFontName];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    OLTextOnPhoto *copy = [[OLTextOnPhoto alloc] init];
    copy.text = [self.text copy];
    copy.frame = self.frame;
    copy.transform = self.transform;
    copy.color = [self.color copy];
    copy.fontName = [self.fontName copy];
    copy.fontSize = self.fontSize;
    
    return copy;
}


- (BOOL)isEqual:(id)object{
    BOOL retVal = [object class] == [self class];
    if (retVal) {
        OLTextOnPhoto *other = object;
        retVal &= CGRectEqualToRect(self.frame, other.frame);
        retVal &= [self.text isEqualToString:other.text];
        retVal &= [self.color isEqual:other.color];
        retVal &= [self.fontName isEqualToString:other.fontName];
        retVal &= self.fontSize == other.fontSize;
    }
    
    return retVal;
}


@end
