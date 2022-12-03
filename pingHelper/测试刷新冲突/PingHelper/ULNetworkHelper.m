//
//  ULNetworkHelper.m
//  KilaAudio
//
//  Created by 郭朝顺 on 2022/1/21.
//  Copyright © 2022 UXIN CO. All rights reserved.
//

#import "ULNetworkHelper.h"

@interface ULNetworkHelper ()

@property (nonatomic, strong) NSMutableArray *completionBlocks;
@property (nonatomic, assign) BOOL isRequesting;
@property (nonatomic, assign) CFAbsoluteTime startTime;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation ULNetworkHelper

- (id)init {
    if (self = [super init]) {
        self.isRequesting = NO;
        self.timeout = 2;
        self.completionBlocks = [NSMutableArray array];
        self.semaphore = dispatch_semaphore_create(1);
        self.host = @"http://api.m.taobao.com/rest/api3.do?api=mtop.common.getTimestamp";
    }
    return self;
}

#pragma mark - actions

- (void)pingWithBlock:(ULNetworkHelperComplete)completion {
    //NSLog(@"pingWithBlock");
    if (completion) {
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        [self.completionBlocks addObject:[completion copy]];
        dispatch_semaphore_signal(self.semaphore);
    }

    if (!self.isRequesting) {
        self.isRequesting = YES;
        [self p_startRequest];
    }
}

#pragma mark 私有方法

- (void)p_startRequest {

    // 与接口表现一致
    // 接口有失效风险,能换成自己的服务器最好
    NSLog(@"gcs -- 开始");
    NSURL *url = [NSURL URLWithString:self.host];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:self.timeout];
    self.startTime = CFAbsoluteTimeGetCurrent();
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        BOOL isSuccess = NO;
        if (error) {
            NSLog(@"gcs -- 出错");
            isSuccess = NO;
        } else {
            NSLog(@"gcs -- 正常");
            isSuccess = YES;
        }
        [weakSelf endWithFlag:isSuccess];
    }];
    [dataTask resume];
    
}


- (void)endWithFlag:(BOOL)isSuccess {


    if (!self.isRequesting) {
        return;
    }

    self.isRequesting = NO;

    NSTimeInterval latency = 0;
    if (isSuccess) {
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        latency = (end - self.startTime) * 1000;
    }

    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);

    NSArray *copyBlockArray = [self.completionBlocks copy];
    for (ULNetworkHelperComplete completionBlock in copyBlockArray) {
        completionBlock(isSuccess, latency);
    }
    [self.completionBlocks removeAllObjects];

    dispatch_semaphore_signal(self.semaphore);
}

- (void)dealloc {
    NSLog(@"%s",__FUNCTION__);
}

@end
