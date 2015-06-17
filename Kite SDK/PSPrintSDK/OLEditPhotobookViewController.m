//
//  OLEditPhotobookViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 16/6/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLEditPhotobookViewController.h"
#import "OLPhotobookViewController.h"
#import "OLPhotobookPageContentViewController.h"

@interface OLEditPhotobookViewController () <UICollectionViewDelegateFlowLayout, OLPhotobookViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray *photobookPhotos;
@property (assign, nonatomic) NSNumber *selectedIndexNumber;

@end

@implementation OLEditPhotobookViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.photobookPhotos = [[NSMutableArray alloc] initWithCapacity:self.product.quantityToFulfillOrder];
    [self.photobookPhotos addObjectsFromArray:self.userSelectedPhotos];
    for (NSInteger i = self.userSelectedPhotos.count; i < self.product.quantityToFulfillOrder; i++){
        [self.photobookPhotos addObject:[NSNull null]];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"bookPreviewCell" forIndexPath:indexPath];
    
    UIView *view = [cell viewWithTag:10];
    if (!view){
        OLPhotobookViewController *photobook = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotobookViewController"];
        photobook.assets = self.assets;
        
        photobook.userSelectedPhotos = self.photobookPhotos;
        photobook.editingPageNumber = [NSNumber numberWithInteger:indexPath.item * 2];
        
        photobook.product = self.product;
        photobook.delegate = self.delegate;
        photobook.editMode = YES;
        [self addChildViewController:photobook];
        [cell addSubview:photobook.view];
        CGSize size = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
        photobook.view.frame = CGRectMake(0, 0, size.width, size.height);
        photobook.view.tag = 10;
        
        photobook.photobookDelegate = self;
    }
    else{
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if (photobook.view == view){
                photobook.editingPageNumber = [NSNumber numberWithInteger:indexPath.item * 2];
                if (self.selectedIndexNumber){
                    [[self findPageForImageIndex:[self.selectedIndexNumber integerValue]] highlightImageAtIndex:[self.selectedIndexNumber integerValue]];
                }
            }
        }
    }
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.product.quantityToFulfillOrder / 2.0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(self.view.frame.size.width, 302);
}

- (void)swapImageAtIndex:(NSInteger)index1 withImageAtIndex:(NSInteger)index2{
    [self.photobookPhotos exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (OLPhotobookPageContentViewController *)findPageForImageIndex:(NSInteger)index{
    for (OLPhotobookViewController *photobook in self.childViewControllers){
        for (OLPhotobookPageContentViewController *page in photobook.pageController.viewControllers){
            if (page.pageIndex == index){
                return page;
            }
        }
    }
    return nil;
}

- (void)photobook:(OLPhotobookViewController *)photobook userDidTapOnImageWithIndex:(NSInteger)index{
    OLPhotobookPageContentViewController *page = [self findPageForImageIndex:index];
    if ([self.photobookPhotos objectAtIndex:index] != (id)[NSNull null]){ //user tapped on non-blank image
        if (self.selectedIndexNumber && [self.selectedIndexNumber integerValue] == index){ //deselect
            [[self findPageForImageIndex:[self.selectedIndexNumber integerValue]] unhighlightImageAtIndex:index];
            self.selectedIndexNumber = nil;
        }
        else if (self.selectedIndexNumber){ //swap
            [page unhighlightImageAtIndex:index];
            [self swapImageAtIndex:[self.selectedIndexNumber integerValue] withImageAtIndex:page.pageIndex];
            photobook.userSelectedPhotos = self.photobookPhotos;
            OLPhotobookPageContentViewController *selectedPage = [self findPageForImageIndex:[self.selectedIndexNumber integerValue]];
            [(OLPhotobookViewController *)selectedPage.parentViewController.parentViewController setUserSelectedPhotos:self.photobookPhotos];
            [selectedPage unhighlightImageAtIndex:[self.selectedIndexNumber integerValue]];
            self.selectedIndexNumber = nil;
        }
        else{ //select
            self.selectedIndexNumber = [NSNumber numberWithInteger:index];
            [page highlightImageAtIndex:index];
        }
    }
    else{ //pick new photos
        
    }
}

@end
