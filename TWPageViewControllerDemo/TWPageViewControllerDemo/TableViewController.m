//
//  TableViewController.m
//  TWPageViewController
//
//  Created by zhiyun.huang on 7/12/16.
//  Copyright © 2016 EAH. All rights reserved.
//

#import "TableViewController.h"

@interface TableViewController ()

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, CGRectGetWidth(self.view.bounds), 200)];
    label.textAlignment = NSTextAlignmentCenter;
    
    self.textLabel = label;
    self.textLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:label];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"%@ viewWillAppear",self.text);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.textLabel.text = self.text;
    NSLog(@"%@ viewDidAppear",self.text);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"%@ viewWillDisappear",self.text);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"%@ viewDidDisappear",self.text);
}

@end
