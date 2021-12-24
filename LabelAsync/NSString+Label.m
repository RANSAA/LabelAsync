//
//  NSString+Label.m
//  table
//
//  Created by PC on 2021/12/24.
//

#import "NSString+Label.h"
#import <CoreText/CoreText.h>

static CGFloat textRowsRangeMaxHeight = 100000;

@implementation NSString (Label)


/** 设置获取文本行数时固定的高度，默认100000 */
+ (void)setTextRowsRangeMaxHeight:(CGFloat)height
{
    textRowsRangeMaxHeight = height;
}

/**
 功能：获取文本中每一行文字的Range数组，注意：这儿的行数特指文本渲染的行数。
 参数：
     text：支持NSString，NSAttributedString
     font：text为NSString时需要设置的字体
     width：文本需要显示的宽
 返回值：使用NSValue包装的NSRange数组，数组的长度表示文字渲染行数。
 */
+ (nullable NSArray<NSValue *> *)getTextAllRowsRangeWith:(id)text font:(nullable UIFont *)font width:(CGFloat)width
{
    if ([text length] < 1) {
        return nil;
    }
    NSAttributedString *attStr = nil;
    if ([text isKindOfClass:NSString.class]) {
        CTFontRef myFont = CTFontCreateWithName(( CFStringRef)([font fontName]), [font pointSize], NULL);
        NSMutableAttributedString *mAttStr = [[NSMutableAttributedString alloc] initWithString:text];
        NSDictionary *par = @{(NSString *)kCTFontAttributeName:(__bridge  id)myFont,
                              (NSString *)kCTKernAttributeName:[NSNumber numberWithFloat:0.0],
        };
        [mAttStr addAttributes:par range:NSMakeRange(0, mAttStr.length)];
        CFRelease(myFont);
        attStr = mAttStr;
    }else if ([text isKindOfClass:NSAttributedString.class]){
        attStr = (NSAttributedString *)text;
    }else{
        return nil;
    }

    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attStr);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0,0,width,textRowsRangeMaxHeight));
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, NULL);

//    CGContextSetTextMatrix (context, CGAffineTransformIdentity);
//    CGContextTranslateCTM(context, 0.0f, rect.size.height);
//    CGContextScaleCTM(context, 1.0f, -1.0f);
//    CTFrameDraw(frame, context);


    NSArray *lines = (NSArray *)CTFrameGetLines(frame);
    NSMutableArray *linesArray = [[NSMutableArray alloc]init];
    for (id line in lines) {
        CTLineRef lineRef = (__bridge  CTLineRef)line;
        CFRange lineRange = CTLineGetStringRange(lineRef);
        NSRange range = NSMakeRange(lineRange.location, lineRange.length);
        NSValue* value = [NSValue valueWithRange:range];
        [linesArray addObject:value];
    }

    CGPathRelease(path);
    CFRelease(frame);
    CFRelease(frameSetter);

//    NSLog(@"ranges:%@",linesArray);
    return linesArray;
}


@end
