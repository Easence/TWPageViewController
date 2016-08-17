//
//  PageContainerViewController.m
//  TWPageViewController
//
//  Created by zhiyun.huang on 7/13/16.
//  Copyright © 2016 EAH. All rights reserved.
//

#import "PageContainerViewController.h"
#import "TWPageViewController.h"
#import "TWPageTitleViewController.h"
#import "TableViewController.h"
#import "SampleTitleCell.h"
#import "SamplePageViewController.h"

@interface PageContainerViewController ()<TWPageViewControllerDelegate,TWPageViewControllerDataSource,TWPageTitleViewControllerDelegate,TWPageTitleViewControllerDataSource>

@property (weak, nonatomic) IBOutlet UIView *titleView;

@property (weak, nonatomic) IBOutlet UIView *contentView;


@property (weak ,nonatomic) TWPageViewController *pageViewController;
@property (weak ,nonatomic) TWPageTitleViewController *pageTitleViewController;

@end

@implementation PageContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    for(UIViewController *ctrl in self.childViewControllers) {
        if([ctrl isKindOfClass:[TWPageViewController class]]) {
            self.pageViewController = (TWPageViewController *)ctrl;
        }
        else if([ctrl isKindOfClass:[TWPageTitleViewController class]]) {
            self.pageTitleViewController = (TWPageTitleViewController *)ctrl;
        }
    }
    
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    
    self.pageTitleViewController.dataSource = self;
    self.pageTitleViewController.delegate = self;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (NSInteger) numberOfControllersInPageViewController:( TWPageViewController * _Nonnull)pageViewController {
    return 10;
}

- (UIViewController *)pageViewController:( TWPageViewController * _Nonnull)pageViewController viewControllerForIndex:(NSInteger)index {
    
    TableViewController *ctrl = [pageViewController dequeueReusableControllerWithClassName:@"TableViewController" atIndex:index];
    
    if(!ctrl) {
        
        ctrl = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TableViewController"];
    }
    
    ctrl.text = [NSString stringWithFormat:@"index:%ld",(long)index];
    
    ctrl.view.backgroundColor = [UIColor colorWithRed:(float)(random() %  10)/10.f green:(float)(random() %  10)/10.f blue:(float)(random() %  10)/10.f alpha:1.0];
    return ctrl;
}

- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController willAppearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index {
    
//    NSLog(@"willShowController at index:%ld",(long)index);
    [self.pageTitleViewController gotoItemWithIndex:index animated:YES];
    
}

#pragma mark TWPageTitleViewControllerDataSource
- (NSInteger)numberOfItemsInPageTitleViewController:(TWPageTitleViewController *)controller {
    return 10;
}

- (CGSize)pageTitleViewController:(TWPageTitleViewController *)controller sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(100, self.pageTitleViewController.view.bounds.size.height);
}

- (UICollectionViewCell *)pageTitleViewController:(TWPageTitleViewController *)controller cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
     SampleTitleCell*cell = [controller.collectionView dequeueReusableCellWithReuseIdentifier:@"SampleTitleCell" forIndexPath:indexPath];
    cell.titleLabel.text = [NSString stringWithFormat:@"title:%ld",(long)indexPath.row];
    cell.titleLabel.textColor = [UIColor grayColor];
    
    cell.backgroundColor = [UIColor clearColor];//[UIColor colorWithRed:(float)(random() %  10)/10.f green:(float)(random() %  10)/10.f blue:(float)(random() %  10)/10.f alpha:1.0];
    
    return cell;
}

- (void)pageTitleViewController:(TWPageTitleViewController *)controller didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.pageViewController gotoPageWithIndex:indexPath.row animated:YES];
}

- (void)pageTitleViewController:(TWPageTitleViewController *)controller willHilightItemAtIndexPath:(NSIndexPath *)indexPath {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        SampleTitleCell*cell = (SampleTitleCell *)[controller.collectionView cellForItemAtIndexPath:indexPath];
        
//        NSLog(@"willHilightItemAtIndexPath : %ld --- %@",indexPath.row,cell);

        [[controller.collectionView visibleCells] enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(![obj isEqual:cell]) {
                ((SampleTitleCell*)obj).titleLabel.textColor = [UIColor grayColor];
            }
        }];
        
        cell.titleLabel.textColor = [UIColor greenColor];

    });
}

- (IBAction)segChanged:(id)sender {
    
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    switch (seg.selectedSegmentIndex) {
        case 0: {
         
            UIView *indicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.pageTitleViewController.view.bounds) - 4, 0, 4)];
            indicatorView.backgroundColor = [UIColor greenColor];
            
            [self.pageTitleViewController setCustomIndicatorView:indicatorView toFront:NO];
        }
            break;
        case 1: {
            
            UIView *indicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 5, 0, CGRectGetHeight(self.pageTitleViewController.view.bounds) - 10)];
            indicatorView.backgroundColor = [UIColor colorWithRed:0.8362 green:1.0 blue:0.9041 alpha:1.0];
            indicatorView.alpha = 0.3;
            indicatorView.layer.cornerRadius = CGRectGetHeight(indicatorView.bounds) / 2;
            indicatorView.layer.masksToBounds = YES;
            indicatorView.layer.borderWidth = 1;
            indicatorView.layer.borderColor = [UIColor greenColor].CGColor;
            
            [self.pageTitleViewController setCustomIndicatorView:indicatorView toFront:NO];
        }
            break;
        default:
            break;
    }
}


@end
