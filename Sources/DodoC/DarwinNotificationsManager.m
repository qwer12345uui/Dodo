//
//  DarwinNotificationsManager.m
//
//
//  Created by Noah Little on 8/1/2023.
//

#import <Foundation/Foundation.h>
#import "include/DarwinNotificationsManager.h"

@implementation DarwinNotificationsManager {
    NSMutableDictionary *handlers;
}

+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        handlers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)unregisterForNotificationName:(NSString *)name {
    @synchronized (handlers) {
        handlers[name] = nil;
    }
    CFNotificationCenterRemoveObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge const void *)(self),
        (__bridge CFStringRef)name,
        NULL
    );
}

- (void)registerForNotificationName:(NSString *)name callback:(void (^)(void))callback {
    if (name.length == 0 || callback == nil) return;
    @synchronized (handlers) {
        handlers[name] = [callback copy];
    }
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge const void *)(self),
        defaultNotificationCallback,
        (__bridge CFStringRef)name,
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}

- (void)postNotificationWithName:(NSString *)name {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge CFStringRef)name,
        NULL,
        NULL,
        YES
    );
}

- (void)notificationCallbackReceivedWithName:(NSString *)name {
    __block void (^callback)(void) = nil;
    @synchronized (handlers) {
        callback = handlers[name];
    }
    if (callback) callback();
}

void defaultNotificationCallback(
    CFNotificationCenterRef center,
    void *observer,
    CFStringRef name,
    const void *object,
    CFDictionaryRef userInfo
) {
    if (name == NULL) return;
    NSString *identifier = (__bridge NSString *)name;
    [[DarwinNotificationsManager sharedInstance] notificationCallbackReceivedWithName:identifier];
}

- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge const void *)(self)
    );
}

@end
