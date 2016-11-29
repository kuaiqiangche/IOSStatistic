//
//  UIView+KQCST_View.m
//  B2B_iOS
//
//  Created by 史衡 on 2016/11/5.
//  Copyright © 2016年 KQC. All rights reserved.
//

#import "UIView+KQCST_View.h"

@implementation UIView (KQCST_View)

- (UIViewController*)KQCST_View_viewController {
    for (UIView* next = self; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

- (NSString*)viewPath {
    NSString *path = @"";
    for (UIView* next = self; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            if (next == self) {
                path = [NSString stringWithFormat:@"%@",nextResponder.class];
            } else {
                path = [NSString stringWithFormat:@"%@/%@",nextResponder.class,path];
            }
            break;
        }
        if (next == self) {
            path = [NSString stringWithFormat:@"%@[%@]",next.class,@([next.superview.subviews indexOfObject:next])];
        } else {
            
            path = [NSString stringWithFormat:@"%@[%@]/%@",next.class,@([next.superview.subviews indexOfObject:next]),path];
        }
        
    }
    return path;
}

- (NSString*)fetchViewText {
    NSString *content = @"";
    if (self.subviews.count < 1) {
        content = [self contentTextWithView:self];
    } else {
        content = [self contentTextWithView:self];
        for (UIView *subview in self.subviews) {
            NSString *pString = [subview fetchViewText];
            if (![pString isEqualToString:@""]) {
                if ([content isEqualToString:@""]) {
                    content = [NSString stringWithFormat:@"%@",[subview fetchViewText]];
                } else {
                    content = [NSString stringWithFormat:@"%@,%@",content,[subview fetchViewText]];
                }
                
            }
        }
    }
    return content;
}

- (NSString*)fetchViewURLs {
    NSString *content = @"";
    if (self.subviews.count < 1) {
        content = [self URLsWithView:self];
    } else {
        content = [self URLsWithView:self];
        for (UIView *subview in self.subviews) {
            NSString *pString = [subview fetchViewURLs];
            if (![pString isEqualToString:@""]) {
                if ([content isEqualToString:@""]) {
                    content = [NSString stringWithFormat:@"%@",[subview fetchViewURLs]];
                } else {
                    content = [NSString stringWithFormat:@"%@,%@",content,[subview fetchViewURLs]];
                }
                
            }
        }
    }
    return content;
}

- (NSString*)contentTextWithView:(UIView*)view {
    NSString *content = @"";
    if ([self isKindOfClass:[UILabel class]]) {
        NSString *labelText = ((UILabel*)self).text;
        NSAttributedString *atText = ((UILabel*)self).attributedText;
        if (atText && ![atText.string isEqualToString:@""]) {
            labelText = atText.string;
        }
        if (labelText && ![labelText isEqualToString:@""]) {
            content = [NSString stringWithFormat:@"%@",labelText];
        }
    }
    if ([self isKindOfClass:[UIButton class]]) {
        if (((UIButton*)self).currentTitle && ![((UIButton*)self).currentTitle isEqualToString:@""]) {
            content = [NSString stringWithFormat:@"%@",((UIButton*)self).currentTitle];
        }
    }
    return content;
}

- (NSString*)URLsWithView:(UIView*)view {
    NSString *urlString = @"";
    if ([self isKindOfClass:[UIImageView class]]) {
        NSString *imageURL = ((UIImageView*)self).sd_imageURL.absoluteString;
        urlString = imageURL ? : @"";
    }
    if ([self isKindOfClass:[UIButton class]]) {
        NSString *buttonURL = ((UIButton*)self).sd_currentImageURL.absoluteString;
        urlString = buttonURL ? : @"";
    }
    return urlString;
}

@end
