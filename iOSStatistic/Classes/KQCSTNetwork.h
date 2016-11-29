//
//  KQCSTNetwork.h
//  Pods
//
//  Created by 史衡 on 2016/11/18.
//
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface KQCSTNetwork : NSObject

- (void)requestEvents:(NSArray*)events
         commonParams:(NSDictionary*)params
              success:(void(^)(NSArray *batchEvents))successBlock
              failure:(void(^)(NSArray *batchEvents,NSError * _Nullable error))failureBlock;

@end
NS_ASSUME_NONNULL_END
