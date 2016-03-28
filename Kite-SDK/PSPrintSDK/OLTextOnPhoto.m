//
//  OLTextOnPhoto.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 10/03/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLTextOnPhoto.h"

static NSString *const kKeyTextOnPhotoText = @"co.oceanlabs.psprintstudio.kKeyTextOnPhotoText";
static NSString *const kKeyTextOnPhotoFrame = @"co.oceanlabs.psprintstudio.kKeyTextOnPhotoFrame";
static NSString *const kKeyTextOnPhotoTransform = @"co.oceanlabs.psprintstudio.kKeyTextOnPhotoTransform";

@implementation OLTextOnPhoto

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.text forKey:kKeyTextOnPhotoText];
    [aCoder encodeCGRect:self.frame forKey:kKeyTextOnPhotoFrame];
    [aCoder encodeCGAffineTransform:self.transform forKey:kKeyTextOnPhotoTransform];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.text = [aDecoder decodeObjectForKey:kKeyTextOnPhotoText];
        self.frame = [aDecoder decodeCGRectForKey:kKeyTextOnPhotoFrame];
        self.transform = [aDecoder decodeCGAffineTransformForKey:kKeyTextOnPhotoTransform];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    OLTextOnPhoto *copy = [[OLTextOnPhoto alloc] init];
    copy.text = [self.text copy];
    copy.frame = self.frame;
    copy.transform = self.transform;
    
    return copy;
}


- (BOOL)isEqual:(id)object{
    BOOL retVal = [object class] == [self class];
    if (retVal) {
        OLTextOnPhoto *other = object;
        retVal &= CGRectEqualToRect(self.frame, other.frame);
        retVal &= [self.text isEqualToString:other.text];
    }
    
    return retVal;
}


@end
