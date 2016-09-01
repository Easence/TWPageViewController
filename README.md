## TWPageViewController
相信大家都知道iOS原生的UIPageViewController，用它可以实现横向翻页的效果，TWPageViewController同样也是用来实现横向翻页的效果，配合TWPageTitleViewController使用，可以实现类似于腾讯新闻、今日头条这样的app的效果。如下图所示：

![效果图1](https://github.com/Easence/TWPageViewController/blob/master/TWPageViewControllerDemo/screenShot.gif?raw=true)

### 为什么要写这么一个PageViewController
在新功能开发中，其实也考虑过使用系统的UIPageViewController，但是UIPageViewController有如下的缺点：

- UIPageViewController不支持懒加载模式，即当用手快速横向滑动的时候，会按顺序一个个加载到内存中，当每个子Controller都有网络请求的时候，就会多出一些无用的网络请求，并且滑动过程中可能会卡顿，会影响用户体验。
- UIPageViewController不支持复用的机制（或许根本不需要复用机制）。

主要还是因为UIPageViewController不支持懒加载，所以才打算自己动手写一个类似UIPageViewController的控件。


### TWPageViewController的实现
其实实现起来，原理是很简单的，基于UIScrollView去开发就行了，只不过需要细心的处理好子Controller的生命周期，比如：什么时候调用viewWillAppear：，什么时候调用viewWillDisappear:等。

TWPageViewController实现了以下几个特性：

#### 支持UI部分的复用
以子Controller的class做key，放入复用池，下回加载同类型的viewcontroller则从复用池里面取去来，每种类型的viewcontroller会缓存一个。这样省去了开辟viewcontroller的内存以及cpu的消耗。如果复用池没有相应类型的viewcontroller则会创建一个。在实际应用中可以将UI部分以及数据部分剥离开来，UI部分复用，而数据部分缓存起来，一遍下回直接加载。

#### 实现了懒加载
在滚动停止以后（其实就是在scrollViewDidEndDecelerating:中去调用加载子Controller的回调函数）才会去加载ViewController。以保证快速滑动过程的流畅，同时可以免去过程中的其他操作的资源消耗（比如途中的子Controller的网络请求）。
#### 控制了内存的增长
如果子Controller的数目大于3，则内存中只会保存3+N个viewController，3表示前一个、当前、后一个子Controller，N等于viewController类型的数目。小于等于3就等于实际的子Controller的数目。
#### 跟iOS原生的UIPageViewController一样的时刻回调子Controller的生命周期函数
比如向左拖拽不放的情况下，当前子Controller的viewWillDisappear：会被回调，同时会回调下一个子Controller的viewWillAppear:，停下后，如果是停留在下一个子Controller，那么它的viewDidAppear：会被回调，同时上一个的viewDidDisappear：会被回调。
#### 提供了子viewController各个生命周期的回调，可以用来做统一的数据的缓存、读取缓存等操作
这些回调有：

```
- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController prepareReuseController:(UIViewController * _Nonnull) controller;

- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController willAppearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;

- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController didAppearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;

- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController willDisappearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;

- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController didDisappearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;
```

## TWPageTitleViewController
- TWPageTitleViewController则只是简单容器，继承自UICollectionViewController，它只是一个横向滚动的容器，具体的每个条目的样式可以像现实自定义的UICollectionViewCell样式一样使用。
- 支持自定义高亮条
调用`- (void)setCustomIndicatorView:(UIView *)indicatorView toFront:(BOOL)toFront;`设置即可，如Demo中的：

```
UIView *indicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 5, 0, CGRectGetHeight(self.pageTitleViewController.view.bounds) - 10)];
indicatorView.backgroundColor = [UIColor colorWithRed:0.8362 green:1.0 blue:0.9041 alpha:1.0];
indicatorView.alpha = 0.3;
indicatorView.layer.cornerRadius = CGRectGetHeight(indicatorView.bounds) / 2;
indicatorView.layer.masksToBounds = YES;
indicatorView.layer.borderWidth = 1;
indicatorView.layer.borderColor = [UIColor greenColor].CGColor;

[self.pageTitleViewController setCustomIndicatorView:indicatorView toFront:NO];

```

## 计划优化的地方
- TWPageTitleViewController高亮条的移动可以根据TWPageViewController的滑动平滑的过度过去。
