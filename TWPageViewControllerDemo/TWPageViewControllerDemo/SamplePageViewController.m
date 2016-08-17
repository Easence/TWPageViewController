//
//  SamplePageViewController.m
//  TWPageViewController
//
//  Created by zhiyun.huang on 7/18/16.
//  Copyright © 2016 EAH. All rights reserved.
//

#import "SamplePageViewController.h"
#import "TableViewController.h"

@interface SamplePageViewController  () <TWPageViewControllerDelegate,TWPageViewControllerDataSource>

@end

@implementation SamplePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = self;
    self.delegate = self;
}

- (NSInteger) numberOfControllersInPageViewController:( TWPageViewController * _Nonnull)pageViewController {
    return 10;
}

- (UIViewController *)pageViewController:( TWPageViewController * _Nonnull)pageViewController viewControllerForIndex:(NSInteger)index {
    
    
    TableViewController *ctrl = [pageViewController dequeueReusableControllerWithClassName:@"TableViewController" atIndex:index];
    
    if(!ctrl) {
        
        ctrl = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TableViewController"];
    }
    
    ctrl.text = [NSString stringWithFormat:@"inner index:%ld",(long)index];

    ctrl.view.backgroundColor = [UIColor colorWithRed:(float)(random() %  10)/10.f green:(float)(random() %  10)/10.f blue:(float)(random() %  10)/10.f alpha:1.0];
    
    return ctrl;
}

- (void)pageViewController:(TWPageViewController * _Nonnull)pageViewController willShowController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index {
    
    NSLog(@"willShowController at index:%ld",(long)index);
    
}

@end
