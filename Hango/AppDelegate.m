#import "AppDelegate.h"
#import "HangoIAPManager.h"
#import "HangoKeyboardManager.h"
#import "HangoAppConfig.h"
#import "HangoAPITokenStore.h"
#import "HangoDeviceHelper.h"
#import <AdjustSdk/AdjustSdk.h>
@import FBSDKCoreKit;

@interface AppDelegate () <AdjustDelegate>
@property (nonatomic, copy, nullable) NSDictionary *storedLaunchOptions;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.storedLaunchOptions = launchOptions;
    [HangoKeyboardManager install];
    [[HangoIAPManager shared] start];
    return YES;
}

- (void)startDeferredSDKs {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if DEBUG
        NSLog(@"[HangoStartup] starting deferred SDKs");
#endif
        [[FBSDKApplicationDelegate sharedInstance] application:UIApplication.sharedApplication
                                didFinishLaunchingWithOptions:self.storedLaunchOptions];
        [self setupAdjust];
    });
}

- (void)resolveAdjustAdidWithCompletion:(void (^)(NSString *adid))completion {
    [self startDeferredSDKs];

    NSString *cached = [HangoAPITokenStore adjustAdid];
    if (cached.length > 0) {
        NSLog(@"[HangoAdjust] adid from cache: %@", cached);
        if (completion) {
            completion(cached);
        }
        return;
    }

    [Adjust adidWithCompletionHandler:^(NSString * _Nullable adid) {
        NSString *value = adid.length > 0 ? adid : @"";
        if (adid.length > 0) {
            [HangoAPITokenStore setAdjustAdid:adid];
            NSLog(@"[HangoAdjust] adid from SDK: %@", adid);
        } else {
            NSLog(@"[HangoAdjust] adid from SDK: (empty)");
        }
        if (completion) {
            completion(value);
        }
    }];
}

- (void)setupAdjust {
    NSString *environment = HangoAdjustUseSandbox ? ADJEnvironmentSandbox : ADJEnvironmentProduction;
    ADJConfig *config = [[ADJConfig alloc] initWithAppToken:HangoAdjustAppToken
                                                environment:environment];
    config.logLevel = HangoAdjustUseSandbox ? ADJLogLevelVerbose : ADJLogLevelSuppress;
    config.delegate = self;
    [config enableSendingInBackground];

    NSString *deviceId = [HangoDeviceHelper deviceNo];
    if (deviceId.length > 0) {
        [Adjust addGlobalCallbackParameter:deviceId forKey:@"ta_distinct_id"];
    }

    [Adjust initSdk:config];

    [Adjust adidWithCompletionHandler:^(NSString * _Nullable adid) {
        if (adid.length > 0) {
            [HangoAPITokenStore setAdjustAdid:adid];
            NSLog(@"[HangoAdjust] adid cached on init: %@", adid);
        }
    }];
}

#pragma mark - Remote Notifications

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    const unsigned char *bytes = deviceToken.bytes;
    NSMutableString *tokenString = [NSMutableString stringWithCapacity:deviceToken.length * 2];
    for (NSUInteger i = 0; i < deviceToken.length; i++) {
        [tokenString appendFormat:@"%02.2hhx", bytes[i]];
    }
    [HangoAPITokenStore setPushToken:tokenString];
    [FBSDKAppEvents.shared setPushNotificationsDeviceToken:deviceToken];
    NSLog(@"Push Token: %@", tokenString);
}

- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
}

#pragma mark - AdjustDelegate

- (void)adjustAttributionChanged:(nullable ADJAttribution *)attribution {
    ADJEvent *event = [[ADJEvent alloc] initWithEventToken:HangoAdjustEventInstall];
    [Adjust trackEvent:event];
}

@end
