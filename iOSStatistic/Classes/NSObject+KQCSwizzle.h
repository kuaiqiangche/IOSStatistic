//
//  NSObject+KQCSwizzle.h
//  ObjcTests
//
//  Created by 史衡 on 2016/11/4.
//  Copyright © 2016年 shiheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSObject (KQCSwizzle)
/**
 利用runtime对方法进行混淆
 
 @param origSel 原始的方法
 @param swiSel 混淆的方法
 */
+ (void)swizzleOriginalSelector:(SEL)origSel swizzledSelector:(SEL)swiSel;
@end
