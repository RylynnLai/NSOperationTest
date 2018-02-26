//
//  RLOperation.m
//  NSOperationTest
//
//  Created by LLZ on 2018/2/24.
//  Copyright © 2018年 LLZ. All rights reserved.
//

#import "RLOperation.h"

@implementation RLOperation
//重写main方法，实现具体的任务
- (void)main
{
    for (int i = 0; i < 2; i++) {
        NSLog(@"NSOperation的子类RLOperation======%@", [NSThread currentThread]);
    }
}
@end
