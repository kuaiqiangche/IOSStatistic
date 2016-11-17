//
//  UIControl+AutomaticEvents.m
//  ObjcTests
//
//  Created by 史衡 on 2016/11/3.
//  Copyright © 2016年 shiheng. All rights reserved.
//

#import "UIControl+AutomaticEvents.h"
#import "NSObject+KQCSwizzle.h"

@implementation UIControl (AutomaticEvents)

+ (void)load {
    [self swizzleOriginalSelector:@selector(sendAction:to:forEvent:) swizzledSelector:@selector(swiz_sendAction:to:forEvent:)];
}

- (void)swiz_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    //插入埋点代码
    if (![NSStringFromClass([target class]) hasPrefix:@"GrowingUI"]/*[target isKindOfClass:NSClassFromString(@"GrowingUIControlObserver")]*/) {
        [self performUserStastisticsAction:action to:target forEvent:event];
    }
    [self swiz_sendAction:action to:target forEvent:event];
}

- (void)performUserStastisticsAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    
    NSLog(@"B2Bhook success.n[1]action:%@n[2]target:%@ n[3]event:%ld", NSStringFromSelector(action), target, (long)event);
}

@end
