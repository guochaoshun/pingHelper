//
//  ULPingHelper.m
//  ULCommon
//
//  Created by 郭朝顺 on 2022/8/16.
//

#import "ULPingHelper.h"
#import "PingFoundation.h"

@interface ULPingHelper ()<PingFoundationDelegate>

@property (nonatomic, strong) NSMutableArray *completionBlocks;
@property (nonatomic, assign) BOOL isInPing;
@property (nonatomic, assign) CFAbsoluteTime startTime;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, copy) NSString *ipString;
@property(nonatomic, strong) PingFoundation *pingFoundation;

@end


@implementation ULPingHelper

- (instancetype)init {
    if (self = [super init]) {
        self.isInPing = NO;
        self.timeout = 2;
        self.completionBlocks = [NSMutableArray array];
        self.semaphore = dispatch_semaphore_create(1);
    }
    return self;
}


#pragma mark - actions
- (void)pingWithBlock:(ULPingHelperComplete)completion {
    if (completion) {
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        [self.completionBlocks addObject:[completion copy]];
        dispatch_semaphore_signal(self.semaphore);
    }

    if (!self.isInPing) {
        self.isInPing = YES;
        [self p_startRequest];
    }
}

#pragma mark 私有方法
- (void)p_startRequest {

    // 子线程没有runloop开启, 调用startPing会无响应
    // MUST make sure pingFoundation in mainThread
    __weak __typeof(self)weakSelf = self;
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf startPing];
        });
    } else {
        [self startPing];
    }
}

- (void)startPing {
    [self clearPingFoundation];

    self.startTime = CFAbsoluteTimeGetCurrent();
    self.pingFoundation = [[PingFoundation alloc] initWithHostName:self.host];
    self.pingFoundation.delegate = self;
    [self.pingFoundation start];

    [self performSelector:@selector(pingTimeOut) withObject:nil afterDelay:self.timeout];
}

- (void)endWithFlag:(BOOL)isSuccess {

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pingTimeOut) object:nil];
    if (!self.isInPing) {
        return;
    }

    self.isInPing = NO;

    NSTimeInterval latency = 0;
    if (isSuccess) {
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        latency = (end - self.startTime) * 1000;
    }

    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);

    NSArray *copyBlockArray = [self.completionBlocks copy];
    for (ULPingHelperComplete completionBlock in copyBlockArray) {
        completionBlock(isSuccess, self.pingFoundation.IPAddress, latency);
    }
    [self.completionBlocks removeAllObjects];

    dispatch_semaphore_signal(self.semaphore);

    [self clearPingFoundation];

}

- (void)clearPingFoundation {
    if (self.pingFoundation) {
        [self.pingFoundation stop];
        self.pingFoundation.delegate = nil;
        self.pingFoundation = nil;
    }
}


#pragma mark - PingFoundation delegate

// When the pinger starts, send the ping immediately
- (void)pingFoundation:(PingFoundation *)pinger didStartWithAddress:(NSData *)address {
    //NSLog(@"didStartWithAddress");
    [self.pingFoundation sendPingWithData:nil];
}

- (void)pingFoundation:(PingFoundation *)pinger didFailWithError:(NSError *)error {
    //NSLog(@"didFailWithError, error=%@", error);
    [self endWithFlag:NO];
}

- (void)pingFoundation:(PingFoundation *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
    //NSLog(@"didFailToSendPacket, sequenceNumber = %@, error=%@", @(sequenceNumber), error);
    [self endWithFlag:NO];
}

- (void)pingFoundation:(PingFoundation *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber
{
//    NSLog(@"didReceivePingResponsePacket,IP : %@ data:%@字节 sequenceNumber = %@",pinger.IPAddress, @(packet.length), @(sequenceNumber));
    [self endWithFlag:YES];
}

#pragma mark - TimeOut handler

- (void)pingTimeOut {
    if (self.isInPing) {
        self.isInPing = NO;
        [self endWithFlag:NO];
    }
}

- (void)dealloc {
    NSLog(@"%s",__FUNCTION__);
    [self clearPingFoundation];
}



@end
