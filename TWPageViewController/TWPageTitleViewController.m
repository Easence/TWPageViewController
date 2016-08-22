//
//  TWPageTitleViewController.m
//  TWPageViewController
//
//  Created by zhiyun.huang on 7/13/16.
//  Copyright © 2016 EAH. All rights reserved.
//

#import "TWPageTitleViewController.h"

@interface TWPageTitleViewController ()

//条目的总数
@property (nonatomic, assign) NSInteger numberOfItems;

//指示器
@property (nonatomic, strong) UIView *indicatorView;

@end

@implementation TWPageTitleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(!self.indicatorView) {
        self.indicatorView = [[UIView alloc] init];
        self.indicatorView.backgroundColor = [UIColor greenColor];
    }
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self.view addSubview:self.indicatorView];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    self.collectionView.scrollsToTop = NO;
    
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.scrollEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateIndicatorPositionForIndex:self.selectedIndex animated:NO];
    [self willHilightItem];
    
}

- (void)setAllowScrollsToTop:(BOOL)allowScrollsToTop {
    _allowScrollsToTop = allowScrollsToTop;
    self.collectionView.scrollsToTop = allowScrollsToTop;
}

- (void)gotoItemWithIndex:(NSInteger)index animated:(BOOL)animated {
    if(index < self.numberOfItems && index >= 0 && index != self.selectedIndex)  {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
            
            _selectedIndex = index;
            
            [self updateIndicatorPositionForIndex:self.selectedIndex animated:animated];
            
            [self willHilightItem];
        });

    }
}

- (void)reloadData {
    [self.collectionView reloadData];
    //等collectionView的cell加载出来了，再更新高亮块
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
       [self updateIndicatorPositionForIndex:self.selectedIndex animated:NO];
        [self willHilightItem];
    });
}

- (void)setCustomIndicatorView:(UIView *)indicatorView toFront:(BOOL)toFront {
    [self.indicatorView removeFromSuperview];
    self.indicatorView = indicatorView;
    [self.view addSubview:indicatorView];
    if(toFront) {
        [self.view bringSubviewToFront:indicatorView];
    }
    else {
        [self.view sendSubviewToBack:indicatorView];
        
    }
    
    [self updateIndicatorPositionForIndex:self.selectedIndex animated:NO];
}

- (void)updateIndicatorPositionForIndex:(NSInteger)index animated:(BOOL)animated {
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
    if(cell) {
        CGRect cellFrame = [cell convertRect:cell.bounds toView:self.view];
        CGRect frame = self.indicatorView.frame;
        
        if(CGRectGetHeight(self.indicatorView.frame) == 0 && CGRectGetWidth(self.indicatorView.frame) == 0) {
            frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - 4, 0, 4);
        }
        
        frame.origin.x = cellFrame.origin.x;
        frame.size.width = cellFrame.size.width;
        
        if(animated) {
            [UIView animateWithDuration:0.3f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.indicatorView.frame = frame;
            } completion:nil];
            
        } else {
            self.indicatorView.frame = frame;
        }
    }
    
}

- (void)willHilightItem {
    if([self.delegate respondsToSelector:@selector(pageTitleViewController:willHilightItemAtIndexPath:)]) {
        [self.delegate pageTitleViewController:self willHilightItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]];
    }
}

#pragma mark <UICollectionViewDataSource>
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(self.dataSource, @"必须实现TWPageTitleViewControllerDataSource协议");
    return  [self.dataSource pageTitleViewController:self sizeForItemAtIndexPath:indexPath];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSAssert(self.dataSource, @"必须实现TWPageTitleViewControllerDataSource协议");
    
    self.numberOfItems = [self.dataSource numberOfItemsInPageTitleViewController:self];
    return  self.numberOfItems;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [self.dataSource pageTitleViewController:self cellForItemAtIndexPath:indexPath];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if([self.delegate respondsToSelector:@selector(pageTitleViewController:shouldSelectItemAtIndexPath:)]) {
        return [self.delegate pageTitleViewController:self shouldSelectItemAtIndexPath:indexPath];
    }
    
    return YES;
    
}
- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if([self.delegate respondsToSelector:@selector(pageTitleViewController:shouldDeselectItemAtIndexPath:)]) {
        return [self.delegate pageTitleViewController:self shouldDeselectItemAtIndexPath:indexPath];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    });
    
    _selectedIndex = indexPath.row;
    
    [self updateIndicatorPositionForIndex:self.selectedIndex animated:YES];
    [self willHilightItem];

    if([self.delegate respondsToSelector:@selector(pageTitleViewController:didSelectItemAtIndexPath:)]) {
        [self.delegate pageTitleViewController:self didSelectItemAtIndexPath:indexPath];
    }
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if([self.delegate respondsToSelector:@selector(pageTitleViewController:didDeselectItemAtIndexPath:)]) {
        [self.delegate pageTitleViewController:self didDeselectItemAtIndexPath:indexPath];
    }
}

#pragma UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateIndicatorPositionForIndex:self.selectedIndex animated:NO];
}

//- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
//    //    NSLog(@"scrollViewDidEndScrollingAnimation");
//    [self updateIndicatorPositionForIndex:self.currentItemIndex];
//}

#pragma mark overwirte super view method

@end
