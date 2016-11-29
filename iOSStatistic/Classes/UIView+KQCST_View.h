//
//  UIView+KQCST_View.h
//  B2B_iOS
//
//  Created by 史衡 on 2016/11/5.
//  Copyright © 2016年 KQC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (KQCST_View)

//通过view获取当前viewController
- (UIViewController*)KQCST_View_viewController;

//获取view路径
- (NSString*)viewPath;

//获取view内部所有文本信息
- (NSString*)fetchViewText;

//获取使用SDWebImage存储的url
- (NSString*)fetchViewURLs;

@end
