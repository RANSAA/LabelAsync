//
//  TKActionRegister.h
//  testtest
//
//  Created by liboxiang on 2019/2/24.
//  Copyright © 2019 liboxiang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ActionBlock)(_Nullable id value);

@interface TKActionRegister : NSObject

+ (void)registerBlock:(ActionBlock)block forKey:(NSString *)key target:(NSObject *)obj;
+ (void)registerSelector:(NSString *)sel forKey:(NSString *)key target:(NSObject *)obj;
+ (void)runActionForKey:(NSString *)key params:(nullable id)params;

@end

NS_ASSUME_NONNULL_END
