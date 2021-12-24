//
//  TKActionRegister.m
//  testtest
//
//  Created by liboxiang on 2019/2/24.
//  Copyright © 2019 liboxiang. All rights reserved.
//

#import "TKActionRegister.h"

@interface ActionWrapper : NSObject
@property (copy, nonatomic) ActionBlock block;
@property (copy, nonatomic) NSString *actionSEL;
@property (copy, nonatomic) NSString *key;
@end

@implementation ActionWrapper

+ (instancetype)wrapperWithActiongBlock:(ActionBlock)actionBlock key:(NSString *)key {
    ActionWrapper *wrapper = [ActionWrapper new];
    wrapper.block = actionBlock;
    wrapper.key = key;
    return wrapper;
}

+ (instancetype)wrapperWithSEL:(NSString *)sel key:(NSString *)key {
    ActionWrapper *wrapper = [ActionWrapper new];
    wrapper.actionSEL = sel;
    wrapper.key = key;
    return wrapper;
}

@end

@interface TKActionRegister()

@property (strong, nonatomic) NSMapTable *keyAndTargetTable;
@property (strong, nonatomic) NSMapTable *targetAndActionTable;

@end

@implementation TKActionRegister
static TKActionRegister *shareRegister;
static dispatch_once_t onceToken;
+ (instancetype)shareInstance {
    dispatch_once(&onceToken, ^{
        shareRegister = [TKActionRegister new];
        shareRegister.keyAndTargetTable = [NSMapTable strongToWeakObjectsMapTable];
        shareRegister.targetAndActionTable = [NSMapTable weakToStrongObjectsMapTable];
    });
    return shareRegister;
}

+ (void)registerBlock:(ActionBlock)block forKey:(NSString *)key target:(NSObject *)obj {
    TKActionRegister *shareObj = [TKActionRegister shareInstance];
    [shareObj.keyAndTargetTable setObject:obj forKey:key];
    
    ActionWrapper *wrapper = [ActionWrapper wrapperWithActiongBlock:block key:key];
    NSMutableDictionary *dic = [shareObj.targetAndActionTable objectForKey:obj];
    if (dic) {
        [dic setObject:wrapper forKey:key];
    }
    else {
        NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:0];
        [mDic setObject:wrapper forKey:key];
        [shareObj.targetAndActionTable setObject:mDic forKey:obj];
    }
}

+ (void)registerSelector:(NSString *)sel forKey:(NSString *)key target:(NSObject *)obj {
    TKActionRegister *shareObj = [TKActionRegister shareInstance];
    [shareObj.keyAndTargetTable setObject:obj forKey:key];
    ActionWrapper *wrapper = [ActionWrapper wrapperWithSEL:sel key:key];
    NSMutableDictionary *dic = [shareObj.targetAndActionTable objectForKey:obj];
    if (dic) {
        [dic setObject:wrapper forKey:key];
    }
    else {
        NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:0];
        [mDic setObject:wrapper forKey:key];
        [shareObj.targetAndActionTable setObject:mDic forKey:obj];
    }
}

+ (void)runActionForKey:(NSString *)key params:(nullable id)params {
    if (shareRegister) {
        [shareRegister runActionForKey:key params:params];
    }
}

- (void)runActionForKey:(NSString *)key params:(nullable id)params {
    NSObject *weakObj = [_keyAndTargetTable objectForKey:key];
    if (weakObj && weakObj != NULL) {
        NSMutableDictionary *mDic = [_targetAndActionTable objectForKey:weakObj];
        if (mDic && [mDic.allKeys containsObject:key]) {
            ActionWrapper *wrapper = mDic[key];
            if (wrapper.block) {
                wrapper.block(params);
            }
            SEL selector = wrapper.actionSEL.length ? NSSelectorFromString(wrapper.actionSEL) : nil;
            if (selector && [weakObj respondsToSelector:selector]) {
                NSMethodSignature *methodSig = [weakObj methodSignatureForSelector:selector];
                if (methodSig) {
                    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
                    if (params) {
                        [invocation setArgument:&params atIndex:2];
                    }
                    [invocation setSelector:selector];
                    [invocation setTarget:weakObj];
                    [invocation invoke];
                }
            }
        }
    }
}

@end
