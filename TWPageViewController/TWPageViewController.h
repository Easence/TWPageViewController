//
//  TWPageViewController.h
//  TWPageViewController
//
//  Created by zhiyun.huang on 7/12/16.
//  Copyright © 2016 EAH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol TWPageViewControllerDelegate,TWPageViewControllerDataSource;

@interface TWPageViewController : UIViewController

@property (nullable, nonatomic, weak) id <TWPageViewControllerDelegate> delegate;
@property (nullable, nonatomic, weak) id <TWPageViewControllerDataSource> dataSource;

@property (nonatomic, assign) BOOL allowScrollsToTop;

//出现在屏幕的当前位置
@property (nonatomic, assign ,readonly) NSInteger currentIndex;

- (nullable __kindof UIViewController *)dequeueReusableControllerWithClassName:(NSString * _Nonnull)className atIndex:(NSInteger)index;

//跳转到某一页
- (void)gotoPageWithIndex:(NSInteger)index animated:(BOOL)animated;

- (void)reloadData;

@end



@protocol TWPageViewControllerDelegate <NSObject>

@optional

/**
 *  进入复用前会回调这个方法
 *
 *  @param pageViewController
 *  @param controller         即将进入的复用controller
 */

- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController prepareReuseController:(UIViewController * _Nonnull) controller;

- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController willAppearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;

- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController didAppearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;

- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController willDisappearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;

- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController didDisappearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;

/**
 *  当reloadData的时候，如果当前controller在childController中会回调这个方法
 *
 *  @param pageViewController
 *  @param controller
 *  @param index
 */
- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController needrefreshController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;
@end

@protocol TWPageViewControllerDataSource <NSObject>

@required

/**
 *  Controller的数目
 *
 *  @param pageViewController
 *
 *  @return Controller的数目
 */
- (NSInteger) numberOfControllersInPageViewController:( TWPageViewController * _Nonnull)pageViewController;


/**
 *  当更新UI的时候会回调这个方法
 *
 *  @param pageViewController
 *  @param index              位置
 *
 *  @return 处于index位置的Controller
 */
- (nullable UIViewController *)pageViewController:( TWPageViewController * _Nonnull)pageViewController viewControllerForIndex:(NSInteger)index;

@end