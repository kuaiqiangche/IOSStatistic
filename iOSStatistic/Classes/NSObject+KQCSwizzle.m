//
//  NSObject+KQCSwizzle.m
//  ObjcTests
//
//  Created by 史衡 on 2016/11/4.
//  Copyright © 2016年 shiheng. All rights reserved.
//

#import "NSObject+KQCSwizzle.h"
#import <objc/runtime.h>

@implementation NSObject (KQCSwizzle)

+ (void)swizzleOriginalSelector:(SEL)origSel swizzledSelector:(SEL)swiSel {
    Method origMethod = class_getInstanceMethod(self, origSel);
    Method swizMethod = class_getInstanceMethod(self, swiSel);
    class_addMethod(self,
                    origSel,
                    class_getMethodImplementation(self, origSel),
                    method_getTypeEncoding(origMethod));
    class_addMethod(self,
                    swiSel,
                    class_getMethodImplementation(self, swiSel),
                    method_getTypeEncoding(swizMethod));
    
    method_exchangeImplementations(swizMethod, origMethod);
}

@end
