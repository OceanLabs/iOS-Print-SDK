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

#import "AssetDataSource.h"
#import "OLImageDownloader.h"

@implementation AssetDataSource

- (void)thumbnailImageWithCompletionHandler:(void (^)(UIImage *))handler{
    [self imageWithSize:CGSizeMake(100, 100) applyEdits:YES progress:NULL completion:^(UIImage *image, NSError *error){
        if (image){
            handler(image);
        }
    }];
}

- (CGFloat)pixelWidth{
    return 100;
}
- (CGFloat)pixelHeight{
    return 100;
}

- (CGSize)size {
    return CGSizeMake(self.pixelWidth, self.pixelHeight);
}

- (BOOL)isEqual:(id)object{
    if (![object respondsToSelector:@selector(imageURL)]){
        return NO;
    }
    OLAsset *selfAsset = [OLAsset assetWithURL:self.imageURL size:self.size];
    OLAsset *objectAsset = [OLAsset assetWithURL:[object imageURL] size:self.size];
    return [selfAsset isEqual:objectAsset];
}

+ (AssetDataSource *)assetWithURL:(NSURL *)url {
    NSAssert([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"], @"bad url scheme (%@), only http & https are supported", url.scheme);
    
    NSString *urlStr = url.absoluteString;
    if ([urlStr hasSuffix:@"jpg"] || [urlStr hasSuffix:@"jpeg"]) {
        return [[AssetDataSource alloc] initWithImageURL:url mimeType:kOLMimeTypeJPEG size:CGSizeZero];
    } else if ([urlStr hasSuffix:@"png"]) {
        return [[AssetDataSource alloc] initWithImageURL:url mimeType:kOLMimeTypePNG size:CGSizeZero];
    }
//    else if ([urlStr hasSuffix:@"tiff"] || [urlStr hasSuffix:@"tif"]) {
//        return [[AssetDataSource alloc] initWithImageURL:url mimeType:kOLMimeTypeTIFF];
//    }
//    else if ([urlStr hasSuffix:@"pdf"]){
//        return [[AssetDataSource alloc] initWithImageURL:url mimeType:kOLMimeTypePDF];
//    }
    else {
        // Worst case scenario just assume it's a JPEG.
        return [[AssetDataSource alloc] initWithImageURL:url mimeType:kOLMimeTypeJPEG size:CGSizeZero];
    }
    
    return nil;
}

@end
