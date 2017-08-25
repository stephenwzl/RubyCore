//
//  RBViewController.m
//  RubyCore
//
//  Created by summerbabybiu on 08/25/2017.
//  Copyright (c) 2017 summerbabybiu. All rights reserved.
//

#import "RBViewController.h"
#import <RubyCore/RubyCore.h>

@interface RBViewController ()

@end

@implementation RBViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  RubyContext *context = [RubyContext new];
  [context executeByteCodeSource:[[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mrb"]];
}

@end
