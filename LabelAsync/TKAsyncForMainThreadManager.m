//
//  TKAsyncForMainThreadManager.m
//  learnLabelAsync
//
//  Created by liboxiang on 2019/3/4.
//  Copyright © 2019 liboxiang. All rights reserved.
//

#import "TKAsyncForMainThreadManager.h"
#import "TKAsyncTransactionGroup.h"
#import <UIKit/UIKit.h>

@interface TKAsyncForMainTransition : NSObject

@property (copy, nonatomic) NSAttributedString *key;
@property (weak, nonatomic) id weakBindingObj;
@property (copy, nonatomic) TKMainThreadBlock completionBlock;
@property (assign, nonatomic) BOOL isCanceled;
@property (assign, nonatomic) TKAsyncActionPriority priority;
@property (strong, nonatomic) id<NSObject> value;

@end

@implementation TKAsyncForMainTransition

@end

@interface TKAsyncForMainThreadManager()

@property (strong, nonatomic) TKAsyncTransactionGroup *group;
@property (strong, nonatomic) NSMapTable *transactionMapTable;
@property (strong, nonatomic, nullable) dispatch_queue_t serialQueue;
@property (strong, nonatomic)  NSCache *valueCache;

@end

@implementation TKAsyncForMainThreadManager

+ (instancetype)shareInstance {
    static TKAsyncForMainThreadManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TKAsyncForMainThreadManager alloc] init];
        
    });
    return manager;
}

- (instancetype)init {
    _transactionMapTable = [NSMapTable weakToStrongObjectsMapTable];
    _group = [TKAsyncTransactionGroup new];
    _serialQueue = dispatch_queue_create("TKAsyncForMainThreadManagerSERIAL", DISPATCH_QUEUE_SERIAL);
    _valueCache = [NSCache new];
    _valueCache.totalCostLimit = 50 * 1024 * 1024;//50M
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearMemory)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    return [super init];
}

- (void)clearMemory {
    [_valueCache removeAllObjects];
}

- (void)commitAsyncBlock:(TKAsyncBlock)asyncBlock withKey:(NSAttributedString *)key bindingObj:(nonnull NSObject *)bindingObj priority:(TKAsyncActionPriority)priority completionBlock:(nonnull TKMainThreadBlock)completionBlock {
    __weak typeof(self) weakSelf = self;
    dispatch_async(weakSelf.serialQueue, ^{
        TKAsyncForMainTransition *oldTransition = [weakSelf.transactionMapTable objectForKey:bindingObj];
        if (oldTransition) {
            if ([oldTransition.key isEqualToAttributedString:key]) {
                return;
            }else {
                oldTransition.isCanceled = YES;
                [weakSelf.transactionMapTable removeObjectForKey:bindingObj];
            }
        }
        //查找缓存看是否已经存在对应key的value
        id cacheValue = [weakSelf.valueCache objectForKey:key];
        if (cacheValue) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(cacheValue);
            });
            return;
        }
        
        
        //重绘img
        TKAsyncForMainTransition *transition = [TKAsyncForMainTransition new];
        transition.completionBlock = completionBlock;
        transition.priority = priority;
        transition.key = key;
        transition.isCanceled = NO;
        transition.weakBindingObj = bindingObj;
        [weakSelf.transactionMapTable setObject:transition forKey:bindingObj];
        [weakSelf.group addAsyncBlock:^{
            id value = asyncBlock();
            if ([value isKindOfClass:[UIImage class]]) {
                UIImage *image = (UIImage *)value;
                dispatch_async(weakSelf.serialQueue, ^{
                    if (transition.isCanceled) {
                        //该事务已经被删除了
                    }else {
                        __block TKMainThreadBlock block = transition.completionBlock;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.valueCache setObject:value forKey:key cost:image.size.width * image.size.height * image.scale];
                            block(value);
                        });
                        [weakSelf.transactionMapTable removeObjectForKey:transition.weakBindingObj];
                    }
                });
            }
        } withPriority:priority];

        
    });
}

@end
