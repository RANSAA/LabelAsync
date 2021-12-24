//
//  UILabel+Async.h
//  testtest
//
//  Created by liboxiang on 2019/3/2.
//  Copyright © 2019 liboxiang. All rights reserved.
//
// https://gitee.com/liboxiang/interface_optimization

/**
 功能：扩展UILabel实现异步绘制效果
 缺点：
    1.这两个异步绘制没有实现自适应效果，绘制的前提是必须获取UILabel的大小。
    2.异步绘制NSAttributedString时，需要设置相应属性；默认不能读取UILabel的一些配置信息(如颜色，文字对齐方式)，
    只有将asyncAttributedTextUseSystemProperty=YES时才会读取UILabel的部分属性（读取UILabel设置的属性再对NSAttributedString进行属性覆盖，一般不推荐使用该属性）

关于size问题：
    1.绘制的图片的大小size依赖UILabel的frame。
    2.如果size不能完全绘制文本时，使用...表示。
    3.如果要绘制指定行数的文字时，需要先计算出指定行数时文字的高度，然后再修改UILabel的size，最后再绘制。提示：cell中需要在返回cell高度的位置计算指定行数文本的高度
    4.注意当前扩展不支持自适应，需要明确size大小

 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface UILabel (Async)

@property (copy,nonatomic) NSString *asyncText;
@property (copy,nonatomic) NSAttributedString *asyncAttributedText;
@property (assign,nonatomic) BOOL asyncAttributedTextUseSystemProperty;//使用asyncAttributedText时是否使用UILabel中已经配置过的一些默认属性， Default NO.

@end

NS_ASSUME_NONNULL_END
