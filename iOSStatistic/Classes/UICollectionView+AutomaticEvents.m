//
//  UICollectionView+AutomaticEvents.m
//  B2B_iOS
//
//  Created by 史衡 on 2016/11/5.
//  Copyright © 2016年 KQC. All rights reserved.
//

#import "UICollectionView+AutomaticEvents.h"
#import "NSObject+KQCSwizzle.h"
#import <objc/message.h>
#import "UIView+KQCST_View.h"
#import "KQCStatistic.h"

@implementation UICollectionView (AutomaticEvents)

+ (void)load {
    [self swizzleOriginalSelector:@selector(setDelegate:) swizzledSelector:@selector(swizzle_setDelegate:)];
}

- (void)swizzle_setDelegate:(id)delegate {
    
    [self swizzle_setDelegate:delegate];
    SEL selectSel = NSSelectorFromString(@"swizzle_didSelectItemAtIndexPath");
    if (class_addMethod([delegate class], selectSel, (IMP)swizzle_didSelectItemAtIndexPath, "v@:@@")) {
        [[delegate class] swizzleOriginalSelector:@selector(collectionView:didSelectItemAtIndexPath:) swizzledSelector:selectSel];
    }
}

void swizzle_didSelectItemAtIndexPath(id self, SEL _cmd, UICollectionView * collectionView, NSIndexPath * indexpath)
{
    SEL selector = NSSelectorFromString(@"swizzle_didSelectItemAtIndexPath");
    ((void(*)(id, SEL,id, id))objc_msgSend)(self, selector, collectionView, indexpath);
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexpath];
    NSString *eventName = @"点击";
    NSDictionary *properties = @{@"path":[cell viewPath], @"text":[cell fetchViewText],@"idx":[NSString stringWithFormat:@"%@,%@",@(indexpath.section),@(indexpath.item)],@"img":[cell fetchViewURLs],@"id":@""};
    [[KQCStatistic sharedInstance] statisticsOfEvent:eventName properties:properties]; 
}
@end
