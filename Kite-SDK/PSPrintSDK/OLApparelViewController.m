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

#import "OLApparelViewController.h"
#import "OLUserSession.h"
#import "OLKiteUtils.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLImageDownloader.h"
#import "UIImage+OLUtils.h"
#import "OLAsset+Private.h"

@interface OLImageEditViewController ()
- (void)setupButton4;
- (void)onButtonClicked:(UIButton *)sender;
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)cropIsInImageEditingTools;
- (void)updateProductRepresentationForChoice:(OLProductTemplateOptionChoice *)choice;
- (void)renderImageWithCompletionHandler:(void (^)(void))handler;
@end

@interface OLCaseViewController ()
- (NSURL *)productBackgroundURL;
- (NSURL *)productHighlightsURL;
- (void)onButtonDoneTapped:(id)sender;
@property (strong, nonatomic) OLAsset *backAsset;
@end

@interface OLApparelViewController ()

@end

@interface OLProduct ()
- (NSString *)currencyCode;
@end

@implementation OLApparelViewController

- (BOOL)shouldEnableGestures{
    return NO;
}

- (BOOL)isUsingMultiplyBlend{
    return YES;
}

- (BOOL)cropIsInImageEditingTools{
    return self.product.productTemplate.options.count > 1;
}

- (void)onButtonDoneTapped:(id)sender{
    if ([OLAsset userSelectedAssets].nonPlaceholderAssets.count != 0 && self.product.productTemplate.templateUI == OLTemplateUIApparel && !self.product.selectedOptions[@"garment_size"]) {
        [self showHintViewForView:self.editingTools.button2 header:NSLocalizedStringFromTableInBundle(@"Select Size", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Example: Shirt size") body:NSLocalizedStringFromTableInBundle(@"Tap on this button", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")delay:NO];
        return;
    }
    
    [super onButtonDoneTapped:sender];
}

- (void)saveJobNowWithCompletionHandler:(void(^)(void))handler {
    if (self.product.productTemplate.collectionName && self.product.productTemplate.collectionId){
        NSString *templateId = self.product.selectedOptions[self.product.productTemplate.collectionId];
        if (templateId){
            OLProduct *product = [OLProduct productWithTemplateId:templateId];
            product.selectedOptions = self.product.selectedOptions;
            product.uuid = self.product.uuid;
            self.product = product;
        }
    }
    
    OLAsset *asset = [[OLAsset userSelectedAssets].nonPlaceholderAssets.firstObject copy];
    
    id<OLPrintJob> job;
    if (self.product.productTemplate.fulfilmentItems.count > 0){
        NSMutableDictionary *assetDict = [[NSMutableDictionary alloc] init];
        for (OLFulfilmentItem *item in self.product.productTemplate.fulfilmentItems){
            if (([item.identifier isEqualToString:@"center_chest"] || [item.identifier isEqualToString:@"front_image"]) && asset){
                [assetDict setObject:asset forKey:item.identifier];
            }
            else if (([item.identifier isEqualToString:@"center_back"] || [item.identifier isEqualToString:@"back_image"]) && self.backAsset){
                [assetDict setObject:[self.backAsset copy] forKey:item.identifier];
            }
        }
        job = [OLPrintJob apparelWithTemplateId:self.product.templateId OLAssets:assetDict];
        
    }
    else{
        job = [OLPrintJob apparelWithTemplateId:self.product.templateId OLAssets:@{
                                                                                   @"center_chest": asset,
                                                                                   }];
    }
    for (NSString *option in self.product.selectedOptions.allKeys){
        [job setValue:self.product.selectedOptions[option] forOption:option];
    }
    
    [[PhotobookSDK shared] addProductToBasket:(id<Product>)job];
    
    if (handler){
        handler();
    }    
}

- (void)setupButton4{
    if (self.product.productTemplate.options.count > 1){
        self.editingTools.button4.tag = kOLEditTagProductOptionsTab;
        [self.editingTools.button4 addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.product.productTemplate.options[1] iconWithCompletionHandler:^(UIImage *icon){
            [self.editingTools.button4 setImage:icon forState:UIControlStateNormal];
        }];
    }
    else{
        [super setupButton4];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.product.productTemplate.templateUI == OLTemplateUIApparel && collectionView.tag == 0){
        return CGSizeMake(self.editingTools.collectionView.frame.size.height, self.editingTools.collectionView.frame.size.height);
    }
    else{
        return [super collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
    }
}

- (void)applyProductImageLayers{
    if (!self.deviceView.image){
        self.deviceView.alpha = 0;
    }
    [[OLImageDownloader sharedInstance] downloadImageAtURL:[self productBackgroundURL] priority:1.0 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.deviceView.image = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
            [UIView animateWithDuration:0.1 animations:^{
                if (self.product.productTemplate.templateUI == OLTemplateUIApparel){
                    for (OLProductTemplateOption *option in self.product.productTemplate.options){
                        if ([option.code isEqualToString:@"garment_color"]){
                            for (OLProductTemplateOptionChoice *choice in option.choices){
                                if ([choice.code isEqualToString:self.product.selectedOptions[option.code]]){
                                    [self updateProductRepresentationForChoice:choice];
                                }
                            }
                        }
                    }
                }
                self.deviceView.alpha = 1;
            } completion:^(BOOL finished){
                [self renderImageWithCompletionHandler:NULL];
            }];
        });
    }];
    if (!self.highlightsView.image){
        self.highlightsView.alpha = 0;
    }
    [[OLImageDownloader sharedInstance] downloadImageAtURL:[self productHighlightsURL] priority:0.9 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.highlightsView.image = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
            [UIView animateWithDuration:0.1 animations:^{
                self.highlightsView.alpha = 1;
            }];
        });
    }];
}

@end
