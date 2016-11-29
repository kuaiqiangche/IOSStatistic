//
//  KQCSTNetwork.m
//  Pods
//
//  Created by 史衡 on 2016/11/18.
//
//

#import "KQCSTNetwork.h"

@implementation KQCSTNetwork

- (void)requestEvents:(NSArray*)events
         commonParams:(NSDictionary*)params
              success:(void(^)(NSArray *batchEvents))successBlock
              failure:(void(^)(NSArray *batchEvents,NSError * _Nullable error))failureBlock {
    NSMutableArray *mutEvents = [events mutableCopy];
    while (mutEvents.count > 0) {
        //一次传50条
        NSUInteger batchSize = MIN(mutEvents.count, 10);
        NSArray *batchEvents = [mutEvents subarrayWithRange:NSMakeRange(0, batchSize)];
        NSArray *finalData = [batchEvents arrayByAddingObject:@{@"common":params}];
        NSError *jsonEventError;
        NSData *eventsData = [NSJSONSerialization dataWithJSONObject:finalData
                                               options:(NSJSONWritingOptions)0
                                                 error:&jsonEventError];
        
        if (jsonEventError) {
            failureBlock(batchEvents,jsonEventError);
            return;
        }
        NSString *dataStr = [[NSString alloc] initWithData:eventsData encoding:NSUTF8StringEncoding];
        NSString *query = [NSString stringWithFormat:@"content=%@",dataStr];
        //http://139.196.7.112/kqc/postTest.php
        //http://ai.kuaiqiangche.com/api/mpimport
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://ai.kuaiqiangche.com/api/mpimport"]];
        request.HTTPMethod = @"POST";
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        NSString *accept = [NSString stringWithFormat:@"Accept: application/vnd.cyb.v%@+json", @"2.0.1"];
        [request setValue:accept forHTTPHeaderField:@"accept"];
        NSData *bodyData = [query dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPBody = bodyData;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSession *session = [NSURLSession sharedSession];
        
        __block BOOL isFailed = NO;
        [[session dataTaskWithRequest:request completionHandler:^(NSData *responseData,
                                                                  NSURLResponse *urlResponse,
                                                                  NSError *error) {
            if (error) {
                failureBlock(batchEvents,error);
                isFailed = YES;
            } else {
                NSError *jsonError = nil;
                NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
                if (jsonError) {
                    isFailed = YES;
                    failureBlock(batchEvents,jsonError);
                } else {
                    if ([response[@"code"] integerValue] == 0) {
                        successBlock(batchEvents);
                    } else {
                        isFailed = YES;
                        failureBlock(batchEvents,nil);
                    }
                    
                }
            }
            dispatch_semaphore_signal(semaphore);
        }] resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
//        if (isFailed) {
//            break;
//        }
        
        [mutEvents removeObjectsInArray:batchEvents];
    }
    
}

@end
