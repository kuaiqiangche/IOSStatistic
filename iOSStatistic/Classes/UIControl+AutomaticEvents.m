//
//  UIControl+AutomaticEvents.m
//  ObjcTests
//
//  Created by 史衡 on 2016/11/3.
//  Copyright © 2016年 shiheng. All rights reserved.
//

#import "UIControl+AutomaticEvents.h"
#import "NSObject+KQCSwizzle.h"
#import "KQCStatistic.h"
#import "UIView+KQCST_View.h"

@implementation UIControl (AutomaticEvents)

+ (void)load {
    [self swizzleOriginalSelector:@selector(sendAction:to:forEvent:) swizzledSelector:@selector(swiz_sendAction:to:forEvent:)];
}

- (void)swiz_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    [self swiz_sendAction:action to:target forEvent:event];
    if (![NSStringFromClass([target class]) hasPrefix:@"GrowingUI"]/*[target isKindOfClass:NSClassFromString(@"GrowingUIControlObserver")]*/) {
        NSString *eventName = @"点击";
        NSUInteger idx;
        if (self.superview) {
            idx = [self.superview.subviews indexOfObject:self];
        }
        NSDictionary *properties = @{@"path":[self viewPath], @"text":[self fetchViewText],@"idx":[NSString stringWithFormat:@"%@",@(idx)],@"img":[self fetchViewURLs],@"id":@""};
        [[KQCStatistic sharedInstance] statisticsOfEvent:eventName properties:properties];
    }
}

@end
