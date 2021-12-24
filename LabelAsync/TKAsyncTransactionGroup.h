//
//  TKAsyncTransactionGroup.h
//  learnLabelAsync
//
//  Created by liboxiang on 2019/3/4.
//  Copyright © 2019 liboxiang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKAsyncTransactionGroup : NSObject

- (void)addAsyncBlock:(dispatch_block_t)block withPriority:(NSInteger)priority;

@end

NS_ASSUME_NONNULL_END
