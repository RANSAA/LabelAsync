//
//  NSString+Label.h
//  table
//
//  Created by PC on 2021/12/24.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface NSString (Label)

/** 设置获取文本行数时固定的高度，默认100000 */
+ (void)setTextRowsRangeMaxHeight:(CGFloat)height;

/**
 功能：获取文本中每一行文字的Range数组，注意：这儿的行数特指文本渲染的行数。
 参数：
     text：支持NSString，NSAttributedString
     font：text为NSString时需要设置的字体
     width：文本需要显示的宽
 返回值：使用NSValue包装的NSRange数组，数组的长度表示文字渲染行数。
 */
+ (nullable NSArray<NSValue *> *)getTextAllRowsRangeWith:(id)text font:(nullable UIFont *)font width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
