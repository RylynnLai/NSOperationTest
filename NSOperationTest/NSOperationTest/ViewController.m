//
//  ViewController.m
//  NSOperationTest
//
//  Created by LLZ on 2018/2/24.
//  Copyright © 2018年 LLZ. All rights reserved.
//

#import "ViewController.h"
#import "RLOperation.h"
#define ROW_COUNT 5

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray <UIImageView *>*imageViews;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    self.imageViews = [NSMutableArray arrayWithCapacity:ROW_COUNT];
    for (int i = 0; i < ROW_COUNT; i ++) {
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 110 * i, width, 100)];
        [self.view addSubview:imgView];
        [self.imageViews addObject:imgView];
    }
    
    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeSystem];
    btn1.frame = CGRectMake(20, height - 50, 100, 30);
    [btn1 setTitle:@"NSOperation" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(btn1Action) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
    
    UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeSystem];
    btn2.frame = CGRectMake(120, height - 50, 100, 30);
    [btn2 setTitle:@"NSOperationQueue" forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(btn2Action) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn2];
    
    UIButton *btn3 = [UIButton buttonWithType:UIButtonTypeSystem];
    btn3.frame = CGRectMake(220, height - 50, 100, 30);
    [btn3 setTitle:@"Dependency" forState:UIControlStateNormal];
    [btn3 addTarget:self action:@selector(btn3Action) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn3];
}
/*
 1. 创建任务：先将需要执行的操作封装到NSOperation对象中。
 2. 创建队列：创建NSOperationQueue。
 3. 将任务加入到队列中：将NSOperation对象添加到NSOperationQueue中。
 
 NSOperation的多线程需要配合队列NSOperationQueue
 */

- (void)btn1Action
{
    //NSInvocationOperation
    NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(invocationOperation) object:nil];
    [invocationOperation start];
    
    //NSBlockOperation
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self imageDataWithIndex:1];
        NSLog(@"NSBlockOperation包含的任务========%@", [NSThread currentThread]);
    }];
    
    [blockOperation addExecutionBlock:^{//通过addExecutionBlock添加的任务，开辟线程执行
        [self imageDataWithIndex:1];
        NSLog(@"NSBlockOperation包含的任务，多线程========%@", [NSThread currentThread]);
    }];
    [blockOperation start];
    
    //RLOperation
    RLOperation *operation = [RLOperation new];
    [operation start];
}

- (void)btn2Action
{
    [self test1];
}

- (void)btn3Action
{
    [self test2];
}

- (void)invocationOperation {
    [self imageDataWithIndex:1];
    NSLog(@"NSInvocationOperation包含的任务========%@", [NSThread currentThread]);
}

/*
 NSOperationQueue只有两种队列：
 主队列:[NSOperationQueue mainQueue]
 其他队列（包含并发和串行）:[[NSOperationQueue alloc] init]
 */
- (void)test1
{
//    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    NSOperationQueue *queue = [NSOperationQueue new];//其他队列都会在非主线程执行
    
    //maxConcurrentOperationCount默认是-1，也就是开线程，并发处理
    //maxConcurrentOperationCount设置为1，就是串行，这里是串行并发，不一定都在一个线程上顺序执行任务，可能是多个线程顺序执行
    //maxConcurrentOperationCount即时设置为一个很大的值，系统也会做控制，所以设置太大没有意义
    queue.maxConcurrentOperationCount = 1;
    
    //NSInvocationOperation
    NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(invocationOperation) object:nil];
    [queue addOperation:invocationOperation];//会自动调用任务start方法
    
    //NSBlockOperation
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self imageDataWithIndex:1];
        NSLog(@"NSBlockOperation包含的任务========%@", [NSThread currentThread]);
    }];
    [queue addOperation:blockOperation];//开启线程，不受maxConcurrentOperationCount影响

    //RLOperation
    RLOperation *operation = [RLOperation new];
    [queue addOperation:operation];
    
    [queue addOperationWithBlock:^{//开启线程，不受maxConcurrentOperationCount影响
        [self imageDataWithIndex:1];
        NSLog(@"addOperationWithBlock------%@", [NSThread currentThread]);
    }];
}

- (void)test2
{
    NSOperationQueue *queue = [NSOperationQueue new];
    
    NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(invocationOperation) object:nil];

    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self imageDataWithIndex:1];
        NSLog(@"NSBlockOperation包含的任务========%@", [NSThread currentThread]);
    }];
    
    
    RLOperation *operation = [RLOperation new];
    
    //添加依赖，不要相互依赖，会造成死锁
    //可以在不同队列间相互依赖
    [blockOperation addDependency:operation];
    [operation addDependency:invocationOperation];
    [queue addOperations:@[blockOperation, operation, invocationOperation] waitUntilFinished:NO];//设置为YES时，当前线程会阻塞，直至全部任务完成
}

- (NSData *)imageDataWithIndex:(int)index
{
    NSURL *url = [NSURL URLWithString:@"http://www.ucsmy.com/images/banner.jpg"];
    return [NSData dataWithContentsOfURL:url];//下载jpg，耗时操作
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
