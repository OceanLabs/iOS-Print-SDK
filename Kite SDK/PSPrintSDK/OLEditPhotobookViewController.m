//
//  OLEditPhotobookViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 16/6/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLEditPhotobookViewController.h"
#import "OLPhotobookViewController.h"

@interface OLEditPhotobookViewController () <UICollectionViewDelegateFlowLayout>

@end

@implementation OLEditPhotobookViewController


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"bookPreviewCell" forIndexPath:indexPath];
    
    UIView *view = [cell viewWithTag:10];
    if (!view){
        OLPhotobookViewController *photoBook = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotobookViewController"];
        photoBook.assets = self.assets;
        
        NSInteger leftIndex = (indexPath.item * 2) % self.userSelectedPhotos.count;
        NSInteger rightIndex = ((indexPath.item * 2) + 1) % self.userSelectedPhotos.count;
        photoBook.userSelectedPhotos = [@[self.userSelectedPhotos[leftIndex], self.userSelectedPhotos[rightIndex]] mutableCopy];
        
        photoBook.product = self.product;
        photoBook.delegate = self.delegate;
        photoBook.editMode = YES;
        [self addChildViewController:photoBook];
        [cell addSubview:photoBook.view];
        CGSize size = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
        photoBook.view.frame = CGRectMake(0, 0, size.width, size.height);
        photoBook.view.tag = 10;
    }
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.product.quantityToFulfillOrder / 2.0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(self.view.frame.size.width, 302);
}

@end
