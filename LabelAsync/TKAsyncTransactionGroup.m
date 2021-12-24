//
//  TKAsyncTransactionGroup.m
//  learnLabelAsync
//
//  Created by liboxiang on 2019/3/4.
//  Copyright © 2019 liboxiang. All rights reserved.
//

#import "TKAsyncTransactionGroup.h"

@interface TKAsyncBlockQueueNode : NSObject
@property(copy, nonatomic) dispatch_block_t block; ///< The object associated with this node in the list.
@property(assign, nonatomic) NSInteger priority;
@property(strong, nonatomic) TKAsyncBlockQueueNode *next; ///< The next node in the list.
@end;
@implementation TKAsyncBlockQueueNode

@end
@interface TKAsyncBlockQueue : NSObject {
    TKAsyncBlockQueueNode *_head;//不存数据，next指向第一个数据
    TKAsyncBlockQueueNode *_tail;
    NSUInteger _count;
}
- (TKAsyncBlockQueueNode *)popFirstObject;
- (void)pushObject:(TKAsyncBlockQueueNode *)node;
- (void)insertObject:(TKAsyncBlockQueueNode *)node;
- (BOOL)isEmpty;

@end

@implementation TKAsyncBlockQueue

- (instancetype)init {
    if (self = [super init]) {
        _count = 0;
        _head = [TKAsyncBlockQueueNode new];
        _head.next = nil;
        _tail = _head;
    }
    return self;
}

- (TKAsyncBlockQueueNode *)popFirstObject {
    if (_count && _head.next) {
        //非空
        TKAsyncBlockQueueNode *first = _head.next;
        
        if (_count == 1) {
            //此时_head = _tail
            _tail = _head; 
        }
        else {
            _head.next = first.next;
        }
        
        first.next = nil;
        _count--;
        return first;
    }
    else {
        return nil;
    }
}

- (void)pushObject:(TKAsyncBlockQueueNode *)node {
    TKAsyncBlockQueueNode *lastNode = [TKAsyncBlockQueueNode new];
    lastNode.block = node.block;
    lastNode.priority = node.priority;
    lastNode.next = nil;
    
    _tail.next = lastNode;
    _tail = lastNode;
    
    _count++;
}

- (void)insertObject:(TKAsyncBlockQueueNode *)node {
    TKAsyncBlockQueueNode *newNode = [TKAsyncBlockQueueNode new];
    newNode.block = node.block;
    newNode.priority = node.priority;
    newNode.next = nil;
    
    TKAsyncBlockQueueNode *p = _head;
    while (p) {
        if (p.next == nil) {
            p.next = newNode;
            p = nil;
        }
        else {
            if (p.next.priority < newNode.priority) {
                newNode.next = p.next;
                p.next = newNode;
                p = nil;
            }
            else {
                p = p.next;
            }
        }
    }
    _count++;
}

- (BOOL)isEmpty {
    return _count==0;
}

@end


@interface TKAsyncTransactionGroup()

@property (strong, nonatomic) TKAsyncBlockQueue *nodeQueue;
@property (strong, nonatomic, nullable) dispatch_queue_t concurrentQueue;
@property (strong, nonatomic, nullable) dispatch_queue_t barrierQueue;
@property (assign, nonatomic) NSUInteger pendingOperations;
@property (assign, nonatomic, readonly) NSUInteger maxThreads;

@end

@implementation TKAsyncTransactionGroup

- (instancetype)init {
    if (self = [super init]) {
        _nodeQueue = [TKAsyncBlockQueue new];
        _concurrentQueue = dispatch_queue_create("TKAsyncTransactionGroupConcurrentQueue", DISPATCH_QUEUE_CONCURRENT);
        _barrierQueue = dispatch_queue_create("TKAsyncTransactionGroupBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        _pendingOperations = 0;
        _maxThreads = [NSProcessInfo processInfo].activeProcessorCount * 2;
    }
    return self;
}

- (void)addAsyncBlock:(dispatch_block_t)block withPriority:(NSInteger)priority {
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_barrierQueue, ^{
        TKAsyncBlockQueueNode *node = [TKAsyncBlockQueueNode new];
        node.block = block;
        node.priority = priority;
        node.next = nil;
        [weakSelf.nodeQueue pushObject:node];
        [weakSelf startAsyncAction];
    });
}

- (void)startAsyncAction {
    //当前激活的CPU总数
    __weak typeof(self) weakSelf = self;
    if (_pendingOperations < _maxThreads) {
        _pendingOperations++;
        dispatch_async(_concurrentQueue, ^{
            __block BOOL isEmpty = NO;
            while (!isEmpty) {
                //非空，还有异步任务需要执行，继续在该异步线程中执行
                __block TKAsyncBlockQueueNode *node;
                dispatch_barrier_sync(weakSelf.barrierQueue, ^{
                    node = [weakSelf.nodeQueue popFirstObject];
                });
                if (node && node != NULL) {
                    node.block();
                }
                dispatch_barrier_sync(weakSelf.barrierQueue, ^{
                    isEmpty = weakSelf.nodeQueue.isEmpty;
                });
            }
            dispatch_barrier_async(weakSelf.barrierQueue, ^{
                weakSelf.pendingOperations--;
            });
        });
    }
}

@end
