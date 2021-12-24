//
//  UILabel+Async.m
//  testtest
//
//  Created by liboxiang on 2019/3/2.
//  Copyright © 2019 liboxiang. All rights reserved.
//

#import "UILabel+Async.h"
#import <objc/runtime.h>
#import "TKAsyncForMainThreadManager.h"
#import <CoreText/CoreText.h>


static NSString * AsyncText = @"AsyncText";
static NSString * AsyncAttributedText = @"AsyncAttributedText";
static NSString * CurrentShowAttributedText = @"CurrentShowAttributedText";
static NSString * AsyncAttributedTextUseSystemProperty = @"AsyncAttributedTextUseSystemProperty";



@implementation UILabel (Async)


+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // When swizzling a class method, use the following:
        // Class aClass = object_getClass((id)self);
        
        SEL originalSelector = @selector(drawTextInRect:);
        SEL swizzledSelector = @selector(drawAsyncTextInRect:);
        
        [self swizzleMethods:[self class] originalSelector:originalSelector swizzledSelector:swizzledSelector];
    });
}

+ (void)swizzleMethods:(Class)class originalSelector:(SEL)origSel swizzledSelector:(SEL)swizSel {
    
    Method originalMethod = class_getInstanceMethod(class, origSel);
    Method swizzledMethod = class_getInstanceMethod(class, swizSel);
    //如果实现了viewWillAppear:方法，didAddMethod为NO，否则是YES
    BOOL didAddMethod =
    class_addMethod(class,
                    origSel,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizSel,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)drawAsyncTextInRect:(CGRect)rect {
    if ([self asyncAttributedText].length) {
        self.layer.contentsGravity = kCAGravityResizeAspect;
        NSAttributedString *attributeStr = self.asyncAttributedText;
        UIColor *color = self.backgroundColor;

        NSMutableAttributedString *attributeKey = [[NSMutableAttributedString alloc] initWithAttributedString:[self asyncAttributedText]];
        [attributeKey appendAttributedString:[[NSAttributedString alloc] initWithString:NSStringFromCGSize(rect.size)]];

        __weak typeof(self) weakSelf = self;
        [[TKAsyncForMainThreadManager shareInstance] commitAsyncBlock:^id{
            //UIGraphicsBeginImageContext(rect.size);
            UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
            //背景色
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, [color CGColor]);
            CGContextFillRect(context, rect);

            //文字
            [attributeStr drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine context:nil];

            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            return image;
        } withKey:attributeKey bindingObj:self priority:0 completionBlock:^(id  _Nonnull object) {
            UIImage *image = (UIImage *)object;
            weakSelf.layer.contents = (id)image.CGImage;
        }];
        self.layer.contents = NULL;
    }else {
        [self drawAsyncTextInRect:rect];
    }
}



#pragma mark perporty
- (void)setAsyncAttributedTextUseSystemProperty:(BOOL)asyncAttributedTextUseSystemProperty
{
    objc_setAssociatedObject(self, (__bridge const void*)AsyncAttributedTextUseSystemProperty, @(asyncAttributedTextUseSystemProperty), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)asyncAttributedTextUseSystemProperty
{
    NSNumber *num = objc_getAssociatedObject(self, (__bridge const void*)AsyncAttributedTextUseSystemProperty);
    return num.boolValue;
}

- (nullable NSDictionary *)textAttributes
{
    NSDictionary *par = @{NSFontAttributeName:self.font,
                          NSForegroundColorAttributeName:self.textColor,
                          NSParagraphStyleAttributeName:[self defaultParagraphStyle]
    };
    return par;
}

- (NSMutableParagraphStyle*)defaultParagraphStyle
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = self.textAlignment;
//    paragraphStyle.lineBreakMode = self.lineBreakMode;
    return paragraphStyle;
}

- (void)setAsyncText:(NSString *)asyncText {
    [self setAsyncTextWithSystemProperty:asyncText];
}

- (NSString *)asyncText {
    return [self asyncAttributedText].string;
}

- (void)setAsyncAttributedText:(NSAttributedString *)asyncAttributedText {
    [self setAsyncTextWithSystemProperty:asyncAttributedText];
}

- (NSAttributedString *)asyncAttributedText {
    return objc_getAssociatedObject(self, (__bridge const void*)AsyncAttributedText);
}

- (void)saveAsyncAttributedText:(NSAttributedString *)asyncAttributedText
{
    objc_setAssociatedObject(self, (__bridge const void*)AsyncAttributedText, asyncAttributedText, OBJC_ASSOCIATION_COPY);
    [self setNeedsDisplay];
}

- (void)setAsyncTextWithSystemProperty:(nullable id)asyncText
{
    if ([asyncText length] < 1) {
        self.text = asyncText;
        [self saveAsyncAttributedText:asyncText];
        return;
    }
    if ([asyncText isKindOfClass:NSString.class]) {
        NSAttributedString *attributeStr = [[NSAttributedString alloc] initWithString:asyncText attributes:[self textAttributes]];
        [self saveAsyncAttributedText:attributeStr];
    }else if ([asyncText isKindOfClass:NSAttributedString.class]){
        NSAttributedString *asyncAttributedText = (NSAttributedString *)asyncText;
        if (self.asyncAttributedTextUseSystemProperty) {
            NSRange range = NSMakeRange(0, asyncAttributedText.length);
            NSDictionary *attributes = [asyncAttributedText attributesAtIndex:0 effectiveRange:&range];
            if (!attributes) {
                attributes = [self textAttributes];
                asyncAttributedText = [[NSAttributedString alloc] initWithString:asyncAttributedText.string attributes:attributes];
            }else{
                UIFont *font = attributes[NSFontAttributeName];
                if (!font) {
                    font = self.font;
                }
                UIColor *textColor = attributes[NSForegroundColorAttributeName];
                if (!textColor) {
                    textColor = self.textColor;
                }
                NSMutableParagraphStyle *style = attributes[NSParagraphStyleAttributeName];
                if (!style) {
                    style = [self defaultParagraphStyle];
                }
                NSMutableDictionary *mAttributes = attributes.mutableCopy;
                mAttributes[NSFontAttributeName] = font;
                mAttributes[NSForegroundColorAttributeName] = textColor;
                mAttributes[NSParagraphStyleAttributeName] = style;
                attributes = mAttributes;

                NSMutableAttributedString *mAsyncAttributedText = asyncAttributedText.mutableCopy;
                [mAsyncAttributedText setAttributes:attributes range:range];
                asyncAttributedText = mAsyncAttributedText;
            }
        }
        [self saveAsyncAttributedText:asyncAttributedText];
    }
}

@end
