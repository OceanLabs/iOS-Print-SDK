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
#import <Foundation/Foundation.h>

#import "OLAsset.h"
#import "OLPhotoEdits.h"

typedef void (^OLImageEditorImageGetImageCompletionHandler)(UIImage *image);
typedef void (^OLImageEditorImageGetImageProgressHandler)(float progress);

typedef enum {
    kPrintPhotoAssetTypeALAsset,
    kPrintPhotoAssetTypePHAsset,
    kPrintPhotoAssetTypeOLAsset,
    kPrintPhotoAssetTypeInstagramPhoto,
    kPrintPhotoAssetTypeFacebookPhoto,
    kPrintPhotoAssetTypeCorrupt
} PrintPhotoAssetType;

@interface OLPrintPhoto : NSObject <OLAssetDataSource, NSCopying, NSCoding>

- (void)setImageSize:(CGSize)destSize cropped:(BOOL)cropped progress:(OLImageEditorImageGetImageProgressHandler)progressHandler completionHandler:(void(^)(UIImage *image))handler;
- (void)getImageWithProgress:(OLImageEditorImageGetImageProgressHandler)progressHandler completion:(OLImageEditorImageGetImageCompletionHandler)completionHandler;
- (void)unloadImage;
+ (void)calcScreenScaleForTraitCollection:(UITraitCollection *)traitCollection;
- (BOOL)isEdited;

@property (nonatomic, assign, readonly) PrintPhotoAssetType type;
@property (nonatomic, strong) id asset;
@property (assign, nonatomic) NSInteger extraCopies;
@property (strong, nonatomic) OLPhotoEdits *edits;
@property (strong, nonatomic) NSString *uuid;

@end
