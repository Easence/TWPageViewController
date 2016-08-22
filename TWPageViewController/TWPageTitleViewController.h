//
//  TWPageTitleViewController.h
//  TWPageViewController
//
//  Created by zhiyun.huang on 7/13/16.
//  Copyright © 2016 EAH. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TWPageTitleViewControllerDataSource,TWPageTitleViewControllerDelegate;

@interface TWPageTitleViewController : UICollectionViewController

@property (nonatomic, weak) id<TWPageTitleViewControllerDataSource> dataSource;
@property (nonatomic, weak) id<TWPageTitleViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL allowScrollsToTop;

//当前选中了哪个条目
@property (nonatomic, assign, readonly) NSInteger selectedIndex;


/**
 *  跳转到某一个条目
 */
- (void)gotoItemWithIndex:(NSInteger)index animated:(BOOL)animated;

/**
 *  设置自定义的指示器View
 *
 *  @param indicatorView 指示器View
 *  @param toFront       是否将指示器放在最前面
 */
- (void)reloadData;
//设置自定义的指示器View
- (void)setCustomIndicatorView:(UIView *)indicatorView toFront:(BOOL)toFront;


@end


@protocol TWPageTitleViewControllerDataSource <NSObject>

@required
/**
 *  需要展示多少个条目
 */
- (NSInteger)numberOfItemsInPageTitleViewController:(TWPageTitleViewController *)controller;
/**
 *  指定条目的size
 */
- (CGSize)pageTitleViewController:(TWPageTitleViewController *)controller sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
/**
 *  自定义cell
 */
- (UICollectionViewCell *)pageTitleViewController:(TWPageTitleViewController *)controller cellForItemAtIndexPath:(NSIndexPath *)indexPath;


@end

@protocol TWPageTitleViewControllerDelegate <NSObject>

@optional

- (BOOL)pageTitleViewController:(TWPageTitleViewController *)controller shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)pageTitleViewController:(TWPageTitleViewController *)controller shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)pageTitleViewController:(TWPageTitleViewController *)controller didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)pageTitleViewController:(TWPageTitleViewController *)controller didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
//将要高亮某个条目
- (void)pageTitleViewController:(TWPageTitleViewController *)controller willHilightItemAtIndexPath:(NSIndexPath *)indexPath;
@end


