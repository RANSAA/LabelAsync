//
//  TKAsyncForMainThreadManager.h
//  learnLabelAsync
//
//  Created by liboxiang on 2019/3/4.
//  Copyright © 2019 liboxiang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef id _Nullable (^TKAsyncBlock)(void);
typedef void(^TKMainThreadBlock)(id object);

typedef NS_ENUM(NSInteger,TKAsyncActionPriority) {
    TKAsyncActionPriorityLow       = -1,
    TKAsyncActionPriorityDefault   = 0,
    TKAsyncActionPriorityHight     = 1,
};

@interface TKAsyncForMainThreadManager : NSObject

+ (instancetype)shareInstance;

- (void)commitAsyncBlock:(TKAsyncBlock)asyncBlock withKey:(NSAttributedString *)key bindingObj:(NSObject *)bindingObj  priority:(TKAsyncActionPriority)priority completionBlock:(TKMainThreadBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
