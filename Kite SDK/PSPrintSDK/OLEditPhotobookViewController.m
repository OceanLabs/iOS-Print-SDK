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
@property (strong, nonatomic) UIView *selectedView;
@property (strong, nonatomic) OLPhotobookPageContentViewController *selectedPage;

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

- (void)photobook:(OLPhotobookViewController *)photobook userDidTapOnPage:(OLPhotobookPageContentViewController *)page{
    UIView *selected = page.selectedView;
    if (!selected){
        self.selectedView = nil;
        self.selectedPage = nil;
    }
    else if (!self.selectedPage){
        self.selectedView = selected;
        self.selectedPage = page;
    }
    else{
        //swap
        [page deselectSelected];
        [self swapImageAtIndex:self.selectedPage.pageIndex withImageAtIndex:page.pageIndex];
        photobook.userSelectedPhotos = self.photobookPhotos;
        [(OLPhotobookViewController *)self.selectedPage.parentViewController.parentViewController setUserSelectedPhotos:self.photobookPhotos];
        [self.selectedPage deselectSelected];
        self.selectedPage = nil;
        self.selectedView = nil;
    }
}

- (void)photobook:(OLPhotobookViewController *)photobook userDidTapOnBlankImageAtIndex:(NSInteger)index{
    if (self.selectedPage){
       //swap
    }
    
}

@end
