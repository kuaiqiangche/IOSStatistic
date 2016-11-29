//
//  KQCStatistic.h
//  Pods
//
//  Created by 史衡 on 2016/11/18.
//
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface KQCStatistic : NSObject
//生成单例
+ (instancetype)sharedInstance;

/**
 对复杂的事件统计

 @param event 事件的名称
 
 @param event 事件的属性信息
 */
- (void)statisticsOfEvent:(NSString*)name properties:(NSDictionary  * _Nullable )properties;

/**
 对简单事件进行统计

 @param name 事件的名字
 */
- (void)statisticsOfEvent:(NSString*)name;


/**
 设置唯一标识，如果不设置会使用内部产生的默认唯一标识。

 @param uuid 标识
 */
- (void)uniqueIdentifier:(NSString*)uuid;

/**
 添加超级属性，超级属性会在每个事件中出现

 @param superProperties 超级属性
 */
- (void)superPropertiesAddItem:(NSDictionary*)superProperties;
@end
NS_ASSUME_NONNULL_END
