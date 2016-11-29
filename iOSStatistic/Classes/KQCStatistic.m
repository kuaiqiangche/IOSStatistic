//
//  KQCStatistic.m
//  Pods
//
//  Created by 史衡 on 2016/11/18.
//
//

#import "KQCStatistic.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>
#include <sys/sysctl.h>
#import "KQCStatisticLogger.h"
#import "KQCSTNetwork.h"

typedef void (^KQCReachabilityContextBlock)(SCNetworkReachabilityFlags flags);

static void KQCStatisticReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    KQCReachabilityContextBlock block = (__bridge KQCReachabilityContextBlock)info;
    if (block) {
        block(flags);
    }
    
}

static const void * KQCStatisticReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void KQCStatisticReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

@interface KQCStatistic ()
@property (strong, nonatomic) dispatch_queue_t st_serial_queue;
@property (strong, nonatomic) NSMutableDictionary *commonParams;
@property (strong, nonatomic) NSMutableDictionary *superProperties;
@property (assign, nonatomic) SCNetworkReachabilityRef reachability;
@property (strong, nonatomic) CTTelephonyNetworkInfo *telephonyInfo;
@property (strong, nonatomic) NSMutableArray *events;
@property (strong, nonatomic) KQCSTNetwork *stNetwork;
@property (copy, nonatomic) NSString *defaultUUID;
@end

@implementation KQCStatistic

#pragma mark - life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        self.st_serial_queue = dispatch_queue_create("com.kqc.statistic.serialQueue", DISPATCH_QUEUE_SERIAL);
        self.telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        self.events = [NSMutableArray array];
        self.stNetwork = [[KQCSTNetwork alloc] init];
        [self setUpCommonParams];
        [self setUpSuperProperties];
        [self setUpObservers];
        dispatch_async(self.st_serial_queue, ^{
            [self unarchiveEvents];
        });
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_reachability != NULL) {
        if (!SCNetworkReachabilitySetCallback(_reachability, NULL, NULL)) {
            KQCStatisticLogger(@"置空'SCNetworkReachabilitySetCallback'失败");
        }
        if (!SCNetworkReachabilitySetDispatchQueue(_reachability, NULL)) {
            KQCStatisticLogger(@"置空'SCNetworkReachabilitySetDispatchQueue'失败");
        }
        CFRelease(_reachability);
        _reachability = NULL;
    }
}

#pragma mark - public methods
+ (instancetype)sharedInstance {
    static KQCStatistic *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[KQCStatistic alloc] init];
    });
    return sharedInstance;
}

- (void)statisticsOfEvent:(NSString*)name properties:(NSDictionary*)properties {
    NSTimeInterval occurredInterval = [[NSDate date] timeIntervalSince1970];
    NSNumber *occurredSeconds = @(round(occurredInterval));
    dispatch_async(self.st_serial_queue, ^{
        NSMutableDictionary *mutDic = [properties mutableCopy] ? : [NSMutableDictionary dictionary];
        mutDic[@"event_type"] = name;
        mutDic[@"occurred_time"] = occurredSeconds;
        [mutDic addEntriesFromDictionary:self.superProperties];
        [self.events addObject:mutDic];
        if (self.events.count >= 10) {
            [self.stNetwork requestEvents:self.events.copy
                             commonParams:self.commonParams
                                  success:^(NSArray *batchEvents) {
                [self.events removeObjectsInArray:batchEvents];
            } failure:^(NSArray *batchEvents,NSError * _Nullable error) {
                if (error == nil) {
                    [self.events removeObjectsInArray:batchEvents];
                }
            }];
            
        }
        
    });
}

- (void)statisticsOfEvent:(NSString*)name {
    [self statisticsOfEvent:name properties:nil];
}

- (void)uniqueIdentifier:(NSString*)uuid {
    self.defaultUUID = uuid;
    [self.commonParams setObject:uuid forKey:@"uuid"];
}

- (void)superPropertiesAddItem:(NSDictionary*)superProperties {
    [self.superProperties addEntriesFromDictionary:superProperties];
}

#pragma mark - UIApplication Events
- (void)setUpObservers {
    // wifi reachability
    KQCReachabilityContextBlock callback = ^(SCNetworkReachabilityFlags flags) {
        BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
        BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
        BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
        BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
        BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));
        
        NSString *status = @"未知";
        if (isNetworkReachable == NO) {
            status = @"无";
        }
#if	TARGET_OS_IPHONE
        else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
            status = [self currentRadio];
        }
#endif
        else {
            status = @"WIFI";
        }
        if (self.superProperties) {
            self.superProperties[@"net"] = status;
        }
    };
    
    if ((_reachability = SCNetworkReachabilityCreateWithName(NULL, "ai.kuaiqiangche.com")) != NULL) {
        SCNetworkReachabilityContext context = {0, (__bridge void *)callback, KQCStatisticReachabilityRetainCallback, KQCStatisticReachabilityReleaseCallback, NULL};
        if (SCNetworkReachabilitySetCallback(_reachability, KQCStatisticReachabilityCallback, &context)) {
            if (!SCNetworkReachabilitySetDispatchQueue(_reachability, self.st_serial_queue)) {
                SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
            }
        }
    }
    
    //radio observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeCurrentRadio:)
                                                 name:CTRadioAccessTechnologyDidChangeNotification
                                               object:nil];
    
    // application life cycyle observer
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(kqc_applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(kqc_applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(kqc_applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(kqc_applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(kqc_applicationWillEnterForeground:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];

}

#pragma mark -notification callback
- (void)changeCurrentRadio:(NSNotification*)notification {
    dispatch_async(self.st_serial_queue, ^{
        if (self.superProperties) {
            self.superProperties[@"net"] = [self currentRadio];
        }
    });
}

- (void)kqc_applicationWillTerminate:(NSNotification*)notification {
    dispatch_async(self.st_serial_queue, ^{
        [self archiveEvents];
    });
}

- (void)kqc_applicationWillResignActive:(NSNotification*)notification {
    
}

- (void)kqc_applicationDidBecomeActive:(NSNotification*)notification {
    dispatch_async(self.st_serial_queue, ^{
        [self.stNetwork requestEvents:self.events
                               commonParams:self.commonParams
                                    success:^(NSArray *batchEvents) {
                                        [self.events removeObjectsInArray:batchEvents];
                                    } failure:^(NSArray *batchEvents,NSError * _Nullable error) {
                                        if (error == nil) {
                                            [self.events removeObjectsInArray:batchEvents];
                                        }
                                    }];
    });
}

- (void)kqc_applicationDidEnterBackground:(NSNotification*)notification {
    dispatch_async(self.st_serial_queue, ^{
        [self.stNetwork requestEvents:self.events
                               commonParams:self.commonParams
                                    success:^(NSArray *batchEvents) {
                                        [self.events removeObjectsInArray:batchEvents];
                                        [self archiveEvents];
                                    } failure:^(NSArray *batchEvents,NSError * _Nullable error) {
                                        if (error == nil) {
                                            [self.events removeObjectsInArray:batchEvents];
                                        }
                                        [self archiveEvents];
                                    }];
    });
}

- (void)kqc_applicationWillEnterForeground:(NSNotification*)notification {
    
}

#pragma mark -private methods
- (void)setUpCommonParams {
    UIDevice *device = [UIDevice currentDevice];
    CGSize size = [UIScreen mainScreen].bounds.size;
    NSString *carrier = _telephonyInfo.subscriberCellularProvider.carrierName;
    NSString *deviceModel = [self deviceModel];
    NSString *deviceName = device.name;
    NSString *systemVersion = device.systemVersion;
    NSString *uuid = self.defaultUUID && ![self.defaultUUID isEqualToString:@""] ? self.defaultUUID : [KQCStatistic getUniqueID];
    self.commonParams = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                        @"carrier":carrier,
                                                                        @"manufacture":@"Apple",
                                                                        @"device_model":deviceModel,
                                                                        @"device_name":deviceName,
                                                                        @"os":@"iOS",
                                                                        @"os_version":systemVersion,
                                                                        @"screen_height":@((NSUInteger)size.height),
                                                                        @"screen_width":@((NSUInteger)size.width),
                                                                        @"uuid":uuid
                                                                        }];
}

- (void)setUpSuperProperties {
    NSString *appVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *appBuild = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    self.superProperties = [NSMutableDictionary dictionaryWithDictionary:@{@"app_build":appBuild,
                                                                           @"app_version":appVersion,
                                                                           @"net":@"未知"
                                                                           }];
}

- (void)archiveEvents {
    NSString *path = [self filePath];
    if (![NSKeyedArchiver archiveRootObject:self.events toFile:path]) {
        KQCStatisticLogger(@"归档失败");
    }
    [self addSkipBackupAttributeToItemAtPath:path];
}

- (void)unarchiveEvents {
    NSString *path = [self filePath];
    self.events = (NSMutableArray*)[NSKeyedUnarchiver unarchiveObjectWithFile:path] ? :[NSMutableArray array];
}

- (NSString*)filePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:@"kqc-statistic-events.plist"];
}

//防止文件被上传到iCloud和itunes
- (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString
{
    NSURL *URL = [NSURL fileURLWithPath: filePathString];
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if (!success) {
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

+ (NSString *)getUniqueID{
    static NSString *key = @"com.kuaiqiangche.statistic.uuid";
    NSString *keyChainUUID = [KQCStatistic osecItemGetWithKey:key];
    if (!keyChainUUID || [keyChainUUID isEqualToString:@""]) {
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorSystemDefault);
        CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorSystemDefault, uuid);
        NSString * result = (__bridge_transfer NSString *)CFStringCreateCopy(kCFAllocatorSystemDefault, uuidString);
        CFRelease(uuid);
        CFRelease(uuidString);
        
        if (!result) return result;
        
        keyChainUUID = result;
        [KQCStatistic osecItemSaveWithKey:key data:keyChainUUID];
    }
    return keyChainUUID;
}

- (NSString *)deviceModel {
    NSString *results = nil;
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    if (size) {
        results = @(answer);
    } else {
        
    }
    return results;
}

- (NSString*)currentRadio {
    NSString *radio = _telephonyInfo.currentRadioAccessTechnology;
    if (!radio) {
        radio = @"None";
    } else if ([radio hasPrefix:@"CTRadioAccessTechnology"]) {
        radio = [radio substringFromIndex:23];
    }
    return radio;
}

//储存uuid
+ (NSMutableDictionary *)secItemQueryWithKey:(NSString *) key{
    NSDictionary *query = @{(__bridge_transfer id)kSecClass: (__bridge_transfer id)kSecClassGenericPassword,
                            (__bridge_transfer id)kSecAttrService: key,
                            (__bridge_transfer id)kSecAttrAccount: key,
                            (__bridge_transfer id)kSecAttrAccessible: (__bridge_transfer id)kSecAttrAccessibleAfterFirstUnlock};
    return [NSMutableDictionary dictionaryWithDictionary:query];
}

+ (void)osecItemSaveWithKey:(NSString *)key data:(id)data{
    NSMutableDictionary *query = [KQCStatistic secItemQueryWithKey:key];
    CFDictionaryRef cfQuery = (__bridge_retained CFDictionaryRef)query;
    SecItemDelete(cfQuery);
    
    [query setObject:[NSKeyedArchiver archivedDataWithRootObject:data]
              forKey:(__bridge_transfer id)kSecValueData];
    SecItemAdd(cfQuery, NULL);
    CFRelease(cfQuery);
}

+ (id)osecItemGetWithKey:(NSString *)key{
    NSMutableDictionary *query = [KQCStatistic secItemQueryWithKey:key];
    [query setObject:(id)kCFBooleanTrue
              forKey:(__bridge_transfer id)kSecReturnData];
    [query setObject:(__bridge_transfer id)kSecMatchLimitOne
              forKey:(__bridge_transfer id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    
    id ret = nil;
    if (SecItemCopyMatching((__bridge_retained CFDictionaryRef)query, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge_transfer NSData *)keyData];
        } @catch (NSException *e) {
        } @finally {
        }
    }
    return ret;
}

@end
