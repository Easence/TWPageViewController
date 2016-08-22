//
//  TWPageViewController.m
//  TWPageViewController
//
//  Created by zhiyun.huang on 7/12/16.
//  Copyright © 2016 EAH. All rights reserved.
//

#import "TWPageViewController.h"

@import ObjectiveC.runtime;


const void * pageIndexKey = &pageIndexKey;
const void * appearanceStatusKey = &appearanceStatusKey;

//controller状态
typedef NS_ENUM(NSUInteger, AppearanceStatus) {
    appearanceDefault,
    appearanceWillAppear,
    appearanceDidAppear,
    appearanceWillDisappear,
    appearanceDidDisappear,
};

@interface UIViewController (TWPageIndex)

@property (nonatomic, assign) NSInteger pageIndex;

@property (nonatomic, assign) AppearanceStatus appearanceStatus;

@end


@implementation UIViewController (TWPageIndex)

- (void)setAppearanceStatus:(AppearanceStatus)appearanceStatus {
    objc_setAssociatedObject(self, appearanceStatusKey, @(appearanceStatus), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AppearanceStatus)appearanceStatus {
    NSNumber *num = objc_getAssociatedObject(self, appearanceStatusKey);
    return num ? [num integerValue] : 0;
}

- (void)setPageIndex:(NSInteger)pageIndex {
    objc_setAssociatedObject(self, pageIndexKey, @(pageIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)pageIndex {
    
    NSNumber *num = objc_getAssociatedObject(self, pageIndexKey);
    
    return num ? [num integerValue] : 0;
}

- (void) notifyWillAppear:(BOOL)animated {
    self.appearanceStatus = appearanceWillAppear;
    [self beginAppearanceTransition:YES animated:animated];
}

- (void) notifyDidAppear:(BOOL)animated {
    self.appearanceStatus = appearanceDidAppear;
    [self endAppearanceTransition];
}

- (void) notifyWillDisappear:(BOOL)animated {
    self.appearanceStatus = appearanceWillDisappear;
    [self beginAppearanceTransition:NO animated:animated];
}

- (void) notifyDidDisappear:(BOOL)animated {
    self.appearanceStatus = appearanceDidDisappear;
    [self endAppearanceTransition];
}

@end

@interface TWPageViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *containerView;
//controller的数目
@property (nonatomic, assign) NSInteger numberOfControllers;


//前一个pageIndex
@property (nonatomic, assign) NSInteger preIndex;

//有潜力的下一个index
@property (nonatomic, assign) NSInteger potentialNextIndex;

//复用的controller
@property (nonatomic, strong) NSMutableDictionary *cacheControllers;

//之前的ContentOffset，用来处理子controller的forwardAppearance
@property (nonatomic, assign) CGPoint preContentOffset;
//是否已经处理过了forwardAppearance
@property (nonatomic, assign) BOOL hasProcessForwardAppearance;
//是否在拖动中
@property (nonatomic, assign) BOOL isDragging;

@property (nonatomic, assign) BOOL hasLayouted;
@end

@implementation TWPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cacheControllers = [NSMutableDictionary dictionary];
    _currentIndex = -1;
    
    [self initContainerView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self controllerWillAppearAtIndex:self.currentIndex];
    self.potentialNextIndex = -1;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self controllerDidAppearAtIndex:self.currentIndex];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self controllerWillDisappearAtIndex:self.currentIndex];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self controllerDidDisappearAtIndex:self.currentIndex];
}

//初始化容器View
- (void)initContainerView {
    
    if(!self.containerView) {
        self.containerView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        self.containerView.showsVerticalScrollIndicator = NO;
        self.containerView.showsHorizontalScrollIndicator = NO;
        self.containerView.pagingEnabled = YES;
        self.containerView.delegate = self;
        self.containerView.scrollsToTop = NO;
        [self.view addSubview:self.containerView];
    }
}

- (void)setAllowScrollsToTop:(BOOL)allowScrollsToTop {
    _allowScrollsToTop = allowScrollsToTop;
    self.containerView.scrollsToTop = allowScrollsToTop;
}

- (nullable __kindof UIViewController *)dequeueReusableControllerWithClassName:(NSString * _Nonnull)className atIndex:(NSInteger)index{
    if(!className)
        return nil;
    //如果childController中的相同位置有相同类型的cotroller则返回
    UIViewController *ctrl = [self childControllerForIndex:index];
    if(ctrl && [NSStringFromClass([ctrl class]) isEqualToString:className]) {
        return ctrl;
    }
    
    if(self.cacheControllers[className]) {
        return self.cacheControllers[className];
    }
    
    return nil;
}

- (void)gotoPageWithIndex:(NSInteger)index animated:(BOOL)animated {
    if(index < self.numberOfControllers && index >= 0 && self.currentIndex != index) {
        
        self.preIndex = self.currentIndex;
        _currentIndex = index;
        
        [self controllerWillDisappearAtIndex:self.preIndex];
        [self controllerDidDisappearAtIndex:self.preIndex];
        
        [self relayoutCurrentControllerIfNeed];
        
        
        [self controllerWillAppearAtIndex:self.currentIndex];
        if(!animated) {
            [self controllerDidAppearAtIndex:self.currentIndex];
        }
        
        [self relayoutPreControllerIfNeed];
        [self relayoutNextControllerIfNeed];
        
        [self removeOtherControllers];
        
        [self.containerView scrollRectToVisible:CGRectMake(CGRectGetWidth(self.containerView.bounds) * index , 0 , CGRectGetWidth(self.containerView.bounds), CGRectGetHeight(self.containerView.bounds)) animated:animated];
        
    }
}

- (void)reloadData {
    [self relayout];
}

- (void)setDataSource:(id<TWPageViewControllerDataSource>)dataSource {
    _dataSource = dataSource;
    [self relayout];
}

/**
 *   重新计算容器的contentSize
 */
- (void)resetSubViewSize {
    
    if(self.dataSource) {
        if([self.dataSource respondsToSelector:@selector(numberOfControllersInPageViewController:)]) {
            self.numberOfControllers = [self.dataSource numberOfControllersInPageViewController:self];
        }
    }
    else {
        NSAssert((self.dataSource != nil), @"TWPageViewController必须先设置数据源");
    }
    
    if(self.numberOfControllers > 0) {
        self.containerView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds) * self.numberOfControllers, CGRectGetHeight(self.view.bounds));
    }
    
//    if([self.view superview].constraints.count > 0) {
//        [self.view removeConstraints:self.view.constraints];
//        [self.view mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.edges.equalTo([self.view superview]).with.insets(UIEdgeInsetsMake(0, 0, 0, 0));
//        }];
//    } else
    {
        self.containerView.frame = self.view.bounds;
        //重新设置子controller的位置
        for (UIViewController *controller in self.childViewControllers) {
            
            CGRect frame = controller.view.frame;
            if(index > 0) {
                frame.origin.x = controller.pageIndex * CGRectGetWidth(self.view.bounds);
            } else {
                frame.origin.x = 0;
            }
            frame.size.width = self.view.bounds.size.width;
            frame.size.height = self.view.bounds.size.height;
            controller.view.frame = frame;
        }
    }
}

/**
 *  重新布局子controller的位置
 */

- (void)relayout {
    
    //移除所有子controller
//    for(UIViewController *childController in self.childViewControllers) {
//        [self removeChildController:childController];
//    }
//    
    [self resetSubViewSize];
    
    if(self.dataSource) {
        
        if([self.dataSource respondsToSelector:@selector(numberOfControllersInPageViewController:)]) {
            self.numberOfControllers = [self.dataSource numberOfControllersInPageViewController:self];
        }
        
        _currentIndex = [self caculateCurrentIndex];
        
        if([self.dataSource respondsToSelector:@selector(pageViewController:viewControllerForIndex:)]) {
            
            [self relayoutCurrentController];
            
            [self controllerWillAppearAtIndex:self.currentIndex];
            [self controllerDidAppearAtIndex:self.currentIndex];
            
            [self relayoutPreController];
            [self relayoutNextController];
        }
    }
}

//重新布局currentIndex - 1位置的controller
- (void)relayoutPreController {
    
    NSInteger preIndex = self.currentIndex - 1;
    if(preIndex >= 0) {
        [self replaceWithController:[self.dataSource pageViewController:self viewControllerForIndex:preIndex]  atIndex:preIndex];
    }
}

//如果currentIndex - 1的位置没有controller则重新布局
- (void)relayoutPreControllerIfNeed {
    
    NSInteger preIndex = self.currentIndex - 1;
    if(preIndex >= 0) {
        if(![self hasLayoutControllerAtIndex:preIndex]) {
            [self replaceWithController:[self.dataSource pageViewController:self viewControllerForIndex:preIndex]  atIndex:preIndex];
        }
    }
}

//如果有前一个controller则布局前一个controller
- (void)relayoutCurrentController {
    
    
    NSInteger index = self.currentIndex;
    [self replaceWithController:[self.dataSource pageViewController:self viewControllerForIndex:index]  atIndex:index];
}

//如果有前一个controller则布局前一个controller
- (void)relayoutCurrentControllerIfNeed {
    
    NSInteger index = self.currentIndex;
    if(index >= 0) {
        if(![self hasLayoutControllerAtIndex:index]) {
            [self replaceWithController:[self.dataSource pageViewController:self viewControllerForIndex:index]  atIndex:index];
        }
    }
    
}

//重新布局currentIndex + 1位置的controller
- (void)relayoutNextController {
    
    NSInteger nextIndex = self.currentIndex + 1;
    if(nextIndex < self.numberOfControllers) {
        [self replaceWithController:[self.dataSource pageViewController:self viewControllerForIndex:nextIndex]  atIndex:nextIndex];
    }
}

//如果currentIndex + 1的位置没有controller则重新布局
- (void)relayoutNextControllerIfNeed {
    
    NSInteger nextIndex = self.currentIndex + 1;
    if(nextIndex < self.numberOfControllers) {
        if(![self hasLayoutControllerAtIndex:nextIndex]) {
            [self replaceWithController:[self.dataSource pageViewController:self viewControllerForIndex:nextIndex]  atIndex:nextIndex];
        }
    }
}


/**
 *  是否是子Controller
 *
 *  @param controller
 *
 *  @return 是：YES，否：NO
 */
- (BOOL)isChildController:(UIViewController*)controller {
    
    if([self.childViewControllers containsObject:controller]) {
        return YES;
    }
    
    return NO;
}

/**
 *  拖拽即将停止的时候通知各个controller回调各个Appearance相关的方法
 */
- (void)updateControllersAppearanceStautsWhenEndCelerating {
   
    [self controllerWillAppearAtIndex:self.currentIndex];
    [self controllerDidAppearAtIndex:self.currentIndex];
    
    [self controllerWillDisappearAtIndex:self.currentIndex - 1];
    [self controllerDidDisappearAtIndex:self.currentIndex -1];
    
    [self controllerWillDisappearAtIndex:self.currentIndex + 1];
    [self controllerDidDisappearAtIndex:self.currentIndex + 1];
    
    //如果滑动前的controller滚出了左、右范围，需要通知其disappear
    if(self.preIndex < self.currentIndex - 1 || self.preIndex > self.currentIndex + 1) {
        [self controllerWillDisappearAtIndex:self.preIndex];
        [self controllerDidDisappearAtIndex:self.preIndex];
    }
}

/**
 *  拖拽过程中通知各个controller回调各个Appearance相关的方法
 */
- (void)updateControllersAppearanceStautsWhenDraging {
    if(!self.isDragging) {
        return;
    }
    
    NSLog(@"updateControllersAppearanceStautsWhenDraging");

    //向右边滑动
    if(self.potentialNextIndex == self.currentIndex - 1 && self.potentialNextIndex >= 0) {
        
        [self controllerWillAppearAtIndex:self.potentialNextIndex];
        [self controllerWillDisappearAtIndex:self.currentIndex];
        
        [self controllerWillDisappearAtIndex:self.currentIndex + 1];
        [self controllerDidDisappearAtIndex:self.currentIndex + 1];
    }
    //向左边滑动
    else if(self.potentialNextIndex == self.currentIndex + 1 && self.potentialNextIndex < self.numberOfControllers) {
        
        [self controllerWillAppearAtIndex:self.potentialNextIndex];
        [self controllerWillDisappearAtIndex:self.currentIndex];
        
        [self controllerWillDisappearAtIndex:self.currentIndex - 1];
        [self controllerDidDisappearAtIndex:self.currentIndex - 1];
    }
    
}


/**
 *  将要展现index位置的controller
 *
 *  @param index 索引
 */
- (void)controllerWillAppearAtIndex:(NSInteger)index{
    
    UIViewController *controller = [self childControllerForIndex:index];
    
    if(!controller) return;
    
    if(controller.appearanceStatus == appearanceWillAppear || controller.appearanceStatus == appearanceDidAppear) {
        return;
    }
    
    if([self.delegate respondsToSelector:@selector(pageViewController:willAppearController:atIndex:)]) {
        [self.delegate pageViewController:self willAppearController:controller atIndex:index];
    }
    
    [controller notifyWillAppear:YES];

}

/**
 *  已经展现index位置的controller
 *
 *  @param index 索引
 */
- (void)controllerDidAppearAtIndex:(NSInteger)index {
    
    UIViewController *controller = [self childControllerForIndex:index];

    if(!controller) return;
    
    if(controller.appearanceStatus == appearanceDidAppear) {
        return;
    }
    
    if([self.delegate respondsToSelector:@selector(pageViewController:didAppearController:atIndex:)]) {
        [self.delegate pageViewController:self didAppearController:controller atIndex:index];
    }
    
    [controller notifyDidAppear:YES];
}

/**
 *  index位置的controller将要消失
 *
 *  @param index 索引
 */
- (void)controllerWillDisappearAtIndex:(NSInteger)index {
    UIViewController *controller = [self childControllerForIndex:index];
    
    if(!controller) return;
    
    if(controller.appearanceStatus == appearanceWillDisappear || controller.appearanceStatus == appearanceDidDisappear) {
        return;
    }
    
    if([self.delegate respondsToSelector:@selector(pageViewController:willDisappearController:atIndex:)]) {
        [self.delegate pageViewController:self willDisappearController:controller atIndex:index];
    }
    
    [controller notifyWillDisappear:YES];
}

/**
 *  index位置的controller已经消失
 *
 *  @param index 索引
 */
- (void)controllerDidDisappearAtIndex:(NSInteger)index {
    UIViewController *controller = [self childControllerForIndex:index];
    
    if(!controller) return;
    
    if(controller.appearanceStatus == appearanceDidDisappear) {
        return;
    }
    
    if([self.delegate respondsToSelector:@selector(pageViewController:didDisappearController:atIndex:)]) {
        [self.delegate pageViewController:self didDisappearController:controller atIndex:index];
    }
    
    [controller notifyDidDisappear:YES];
}

/**
 *  如果self.childViewControllers不包含在controller，则在指定的index插入一个controller
 *
 *  @param controller 需要插入的子controller
 *  @param index 位置
 */
- (void)replaceWithController:(UIViewController *)controller atIndex:(NSInteger) index {
    
    if(!controller || index < 0 || index >= self.numberOfControllers)
        return;
    
    //如果是同一个controller就通知外面刷新
    if([self childControllerForIndex:index] == controller) {
        if([self.delegate respondsToSelector:@selector(pageViewController:needrefreshController:atIndex:)]) {
            [self.delegate pageViewController:self needrefreshController:controller atIndex:index];
        }
        return;
    }
    
    //先从缓存中移除
    [self removeFromCacheIfNeedWithController:controller];
    
    //设置controller的pageIndex
    controller.pageIndex = index;
    
    //如果childControllers里面包含有同样的pageIndex的Controller，先将其移除
    for(UIViewController *childController in self.childViewControllers) {
        
        if(childController.pageIndex == index) {
            [self removeChildController:childController];
        }
    }
    
    //将controller加入childControllers，同时更新view的frame
    [self addChildViewController:controller];
    //    [controller beginAppearanceTransition:YES animated:NO];
    [controller didMoveToParentViewController:self];
    
    
    CGRect frame = controller.view.frame;
    if(index > 0) {
        frame.origin.x = index * CGRectGetWidth(self.view.bounds);
    } else {
        frame.origin.x = 0;
    }
    frame.size.width = self.view.bounds.size.width;
    frame.size.height = self.view.bounds.size.height;
    
    controller.view.frame = frame;
    
    [self.containerView addSubview:controller.view];
    
//    if([self.view superview].constraints.count > 0) {
//        [controller.view removeConstraints:self.view.constraints];
//        [controller.view mas_updateConstraints:^(MASConstraintMaker *make) {
//            make.leading.equalTo(controller.view.superview.mas_leading).with.offset(frame.origin.x);
//            make.top.equalTo(controller.view.superview.mas_top);
//            make.bottom.equalTo(controller.view.superview.mas_bottom);
//            make.width.equalTo(@(frame.size.width));
//        }];
//    } else {
//        
//    }
    
}


/**
 *  移除一个子controller
 *
 *  @param childController 子controller
 */
- (void)removeChildController:(UIViewController *)childController {
    
    //如果缓存中没有该类型的controller，则加入到缓存中
    NSString* className = NSStringFromClass([childController class]);
    if(!self.cacheControllers[className]) {
        
        //进入复用前回调@selector(pageViewController:prepareReuseController:)
        if([self.delegate respondsToSelector:@selector(pageViewController:prepareReuseController:)]) {
            [self.delegate pageViewController:self prepareReuseController:childController];
        }
        childController.pageIndex = -1;
        childController.appearanceStatus = appearanceDefault;
        
        self.cacheControllers[className] = childController;
    }
    
    [childController willMoveToParentViewController:nil];
    //    [childController beginAppearanceTransition:NO animated:NO];
    [childController.view removeFromSuperview];
    [childController removeFromParentViewController];
    //    [childController endAppearanceTransition];
}


/**
 *  移除除去当前位置、前一个、后一个controller之外的所有controller
 *
 */
- (void)removeOtherControllers{
    
    NSInteger index = self.currentIndex;
    
    for(UIViewController *childController in self.childViewControllers) {
        
        if(childController.pageIndex < index - 1 || childController.pageIndex > index + 1) {
            [self removeChildController:childController];
        }
    }
}

/**
 *  如果controller被缓存，则从缓存中移除，否则，不做任何操作
 *
 *  @param controller
 */
- (void)removeFromCacheIfNeedWithController:(UIViewController *)controller {
    NSArray *keys = [self.cacheControllers allKeys];
    
    for (id key in keys) {
        if([controller isEqual: self.cacheControllers[key]]) {
            [self.cacheControllers removeObjectForKey:key];
            break;
        }
    }
}

/**
 *  返回在index位置的controller
 */
- (UIViewController *)childControllerForIndex:(NSInteger)index {
    
    for(UIViewController *childController in self.childViewControllers) {
        
        if(childController.pageIndex == index) {
            return childController;
        }
    }
    
    return nil;
}

/**
 *  在index位置是否已经有controller占用了
 */
- (BOOL)hasLayoutControllerAtIndex:(NSInteger)index {
    
    for(UIViewController *childController in self.childViewControllers) {
        
        if(childController.pageIndex == index) {
            return YES;
        }
    }
    
    return NO;
}

/**
 *  计算当前位置索引
 */
- (NSInteger)caculateCurrentIndex {
    
    return self.numberOfControllers > 0 ?  (NSInteger)(self.containerView.contentOffset.x / (self.containerView.contentSize.width / self.numberOfControllers)) : 0;
}

#pragma mark UIScrollView delegate

// called on start of dragging (may require some time and or distance to move)
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.preIndex = self.currentIndex;
        self.preContentOffset = self.containerView.contentOffset;
        self.isDragging = YES;
    });
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isDragging = NO;
    });
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
//        NSLog(@"contentOffset :%f",scrollView.contentOffset.x);
        const CGFloat offsetX = 4;
        //如果是向左边滑动
        if(self.containerView.contentOffset.x - self.preContentOffset.x > offsetX) {
            
            if((self.potentialNextIndex < self.currentIndex) || !self.hasProcessForwardAppearance) {
                
                self.potentialNextIndex = self.currentIndex + 1;
                [self updateControllersAppearanceStautsWhenDraging];
                self.hasProcessForwardAppearance = YES;
            }
            
        }
        //如果是向右边滑动
        else if(self.containerView.contentOffset.x - self.preContentOffset.x < -offsetX) {
            
            if((self.potentialNextIndex > self.currentIndex) || !self.hasProcessForwardAppearance) {
            
                self.potentialNextIndex = self.currentIndex - 1;
                [self updateControllersAppearanceStautsWhenDraging];
                self.hasProcessForwardAppearance = YES;
            }
        }
    });
    
}

// called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.hasProcessForwardAppearance = NO;
        
        _currentIndex = [self caculateCurrentIndex];
        
        if([self.dataSource respondsToSelector:@selector(pageViewController:viewControllerForIndex:)]) {
            if(self.preIndex != self.currentIndex) {
                
                
                [self relayoutCurrentControllerIfNeed];

                [self updateControllersAppearanceStautsWhenEndCelerating];
                
                [self relayoutPreControllerIfNeed];
                [self relayoutNextControllerIfNeed];
                
                [self removeOtherControllers];
            } else {
                //如果存在有潜力的下一个页面
                [self updateControllersAppearanceStautsWhenEndCelerating];
            }
        }
    });
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    //当- (void)gotoPageWithIndex:(NSInteger)index animated:(BOOL)animated，animated是YES的时候，需要在这里调用一次didAppear
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self controllerDidAppearAtIndex:self.currentIndex];
    });
    
}

- (void)viewDidLayoutSubviews {
    [self resetSubViewSize];
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}

@end
