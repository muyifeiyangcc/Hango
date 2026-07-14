#import "AppDelegate.h"
#import "HangoIAPManager.h"
#import "HangoKeyboardManager.h"
#import "HangoAPITokenStore.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [HangoKeyboardManager install];
    [[HangoIAPManager shared] start];
    return YES;
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
    NSLog(@"Push Token: %@", tokenString);
}

- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
}

@end
