//
//  ULNetworkHelper.h
//  KilaAudio
//
//  Created by 郭朝顺 on 2022/1/21.
//  Copyright © 2022 UXIN CO. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ULNetworkHelperComplete)(BOOL isSuccess, NSTimeInterval latency);

@interface ULNetworkHelper : NSObject

@property (nonatomic, copy) NSString *host;

//  Default is 2 seconds
@property (nonatomic, assign) NSTimeInterval timeout;


/// 进行一次网络检测
/// @param completion isSuccess:是否成功; latency:如果成功,延迟时间,单位毫秒
- (void)pingWithBlock:(ULNetworkHelperComplete)completion;


@end

NS_ASSUME_NONNULL_END
