//
//  UIGestureRecognizer+AutomaticEvents.m
//  ObjcTests
//
//  Created by 史衡 on 2016/11/3.
//  Copyright © 2016年 shiheng. All rights reserved.
//

#import "UIGestureRecognizer+AutomaticEvents.h"
#import "NSObject+KQCSwizzle.h"
#import <objc/runtime.h>
#import "NSObject+KQCSwizzle.h"

@implementation UIGestureRecognizer (AutomaticEvents)

+ (void)load {
    [self swizzleOriginalSelector:@selector(addTarget:action:) swizzledSelector:@selector(swizzle_addTarget:action:)];
    [self swizzleOriginalSelector:@selector(initWithTarget:action:) swizzledSelector:@selector(swizzle_initWithTarget:action:)];
}

- (void)swizzle_addTarget:(id)target action:(SEL)action {
    if ([NSStringFromClass([target class]) hasPrefix:@"GrowingUI"] ||
        ![self isKindOfClass:[UITapGestureRecognizer class]] ||
        [target isKindOfClass:NSClassFromString(@"UIWebBrowserView")] ||
        [target isKindOfClass:NSClassFromString(@"UIWebSelectionAssistant")] ||
        [target isKindOfClass:NSClassFromString(@"UITextInteractionAssistant")] ||
        [target isKindOfClass:NSClassFromString(@"_UINavigationInteractiveTransition")] ||
        [target isKindOfClass:NSClassFromString(@"UITableViewCell")] ||
        [target isKindOfClass:NSClassFromString(@"UISwitchModernVisualElement")] ||
        !target ||
        !action) {
        [self swizzle_addTarget:target action:action];
        return;
    }
    if (class_addMethod([target class], @selector(swizzle_tap:), [self methodForSelector:@selector(swizzle_tap:)], "v@:@")) {
        [[target class] swizzleOriginalSelector:action swizzledSelector:@selector(swizzle_tap:)];
    }
    [self swizzle_addTarget:target action:action];
}

- (instancetype)swizzle_initWithTarget:(nullable id)target action:(nullable SEL)action {
    if ([NSStringFromClass([target class]) hasPrefix:@"GrowingUI"] ||
        ![self isKindOfClass:[UITapGestureRecognizer class]] ||
        [target isKindOfClass:NSClassFromString(@"UIWebBrowserView")] ||
        [target isKindOfClass:NSClassFromString(@"UIWebSelectionAssistant")] ||
        [target isKindOfClass:NSClassFromString(@"UITextInteractionAssistant")] ||
        [target isKindOfClass:NSClassFromString(@"_UINavigationInteractiveTransition")] ||
        [target isKindOfClass:NSClassFromString(@"UITableViewCell")] ||
        [target isKindOfClass:NSClassFromString(@"UISwitchModernVisualElement")] ||
        !target ||
        !action) {
        return [self swizzle_initWithTarget:target action:action];
    }
    if (class_addMethod([target class], @selector(swizzle_tap:), [self methodForSelector:@selector(swizzle_tap:)], "v@:@")) {
        [[target class] swizzleOriginalSelector:action swizzledSelector:@selector(swizzle_tap:)];
    }
    return [self swizzle_initWithTarget:target action:action];
}

- (void)swizzle_tap:(UIGestureRecognizer*)gr {
    NSLog(@"UIGestureRecognizer %@ ", gr);
    [self swizzle_tap:gr];
}

@end
