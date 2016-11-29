//
//  UITableView+AutomaticEvents.m
//  B2B_iOS
//
//  Created by 史衡 on 2016/11/5.
//  Copyright © 2016年 KQC. All rights reserved.
//

#import "UITableView+AutomaticEvents.h"
#import "NSObject+KQCSwizzle.h"
#import <objc/message.h>
#import "UIView+KQCST_View.h"
#import "KQCStatistic.h"

@implementation UITableView (AutomaticEvents)

+ (void)load {
    [self swizzleOriginalSelector:@selector(setDelegate:) swizzledSelector:@selector(swizzle_setDelegate:)];
}

- (void)swizzle_setDelegate:(id)delegate {
    
    [self swizzle_setDelegate:delegate];
    SEL selectSel = NSSelectorFromString(@"swizzle_didSelectRowAtIndexPath");
    if (class_addMethod([delegate class], selectSel, (IMP)swizzle_didSelectRowAtIndexPath, "v@:@@")) {
        [[delegate class] swizzleOriginalSelector:@selector(tableView:didSelectRowAtIndexPath:) swizzledSelector:selectSel];
    }
}

void swizzle_didSelectRowAtIndexPath(id self, SEL _cmd, UITableView *tableView, NSIndexPath * indexpath)
{
    SEL selector = NSSelectorFromString(@"swizzle_didSelectRowAtIndexPath");
    ((void(*)(id, SEL,id, id))objc_msgSend)(self, selector, tableView, indexpath);
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexpath];
    NSString *eventName = @"点击";
    NSDictionary *properties = @{@"path":[cell viewPath], @"text":[cell fetchViewText],@"idx":[NSString stringWithFormat:@"%@,%@",@(indexpath.section),@(indexpath.row)],@"img":[cell fetchViewURLs],@"id":@""};
    [[KQCStatistic sharedInstance] statisticsOfEvent:eventName properties:properties];
}

@end
