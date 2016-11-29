//
//  UIViewController+AutomaticEvents.m
//  B2B_iOS
//
//  Created by 史衡 on 2016/11/18.
//  Copyright © 2016年 KQC. All rights reserved.
//

#import "UIViewController+AutomaticEvents.h"
#import "NSObject+KQCSwizzle.h"
#import "UIView+KQCST_View.h"
#import "KQCStatistic.h"

@implementation UIViewController (AutomaticEvents)

+ (void)load {
    [self swizzleOriginalSelector:@selector(viewDidAppear:) swizzledSelector:@selector(swiz_viewDidAppear:)];
    [self swizzleOriginalSelector:@selector(viewDidDisappear:) swizzledSelector:@selector(swiz_viewDidDisappear:)];
}

- (void)swiz_viewDidAppear:(BOOL)animated {
    NSString *eventName = @"Entry page";
    NSDictionary *properties = @{@"path":[NSString stringWithFormat:@"%@",self.class], @"text":[NSString stringWithFormat:@"%@",self.title?:@""]};
    [[KQCStatistic sharedInstance] statisticsOfEvent:eventName properties:properties];
    
    [self swiz_viewDidAppear:animated];
}

- (void)swiz_viewDidDisappear:(BOOL)animated {
    NSString *eventName = @"Exit page";
    NSDictionary *properties = @{@"path":[NSString stringWithFormat:@"%@",self.class], @"text":[NSString stringWithFormat:@"%@",self.title?:@""]};
    [[KQCStatistic sharedInstance] statisticsOfEvent:eventName properties:properties];
    
    [self swiz_viewDidAppear:animated];
}


@end
