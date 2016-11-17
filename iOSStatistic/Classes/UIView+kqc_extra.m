//
//  UIView+kqc_extra.m
//  B2B_iOS
//
//  Created by 史衡 on 2016/11/5.
//  Copyright © 2016年 KQC. All rights reserved.
//

#import "UIView+kqc_extra.h"

@implementation UIView (kqc_extra)
- (UIViewController*)kqc_extra_viewController {
    for (UIView* next = self; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}
@end
