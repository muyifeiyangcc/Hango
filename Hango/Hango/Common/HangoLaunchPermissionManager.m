#import "HangoLaunchPermissionManager.h"
#import <UserNotifications/UserNotifications.h>

static NSString * const kHangoLaunchPermissionsDoneKey = @"HangoLaunchPermissionsDone";

@implementation HangoLaunchPermissionManager

+ (void)requestLaunchPermissionsIfNeededFromViewController:(UIViewController *)viewController {
    if (!viewController) return;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kHangoLaunchPermissionsDoneKey]) return;

    [self showNetworkPermissionAlertFrom:viewController completion:^{
        [self requestAppleNotificationPermissionWithCompletion:^{
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHangoLaunchPermissionsDoneKey];
        }];
    }];
}

+ (UIViewController *)presentingControllerFrom:(UIViewController *)viewController {
    if (viewController.presentedViewController) {
        return viewController.presentedViewController;
    }
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)viewController;
        return nav.topViewController ?: nav;
    }
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)viewController;
        return [self presentingControllerFrom:tab.selectedViewController ?: tab];
    }
    return viewController;
}

+ (void)showNetworkPermissionAlertFrom:(UIViewController *)viewController completion:(dispatch_block_t)completion {
    UIViewController *presenter = [self presentingControllerFrom:viewController];
    if (presenter.presentedViewController) {
        if (completion) completion();
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"\"Hango\" Would Like to Use Wireless Data"
                                                                   message:@"Hango needs network access to sync parties, messages, and your profile."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"WLAN & Cellular" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        if (completion) completion();
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"WLAN Only" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        if (completion) completion();
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Don't Allow" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
        if (completion) completion();
    }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

+ (void)requestAppleNotificationPermissionWithCompletion:(dispatch_block_t)completion {
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound)
                          completionHandler:^(__unused BOOL granted, __unused NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] registerForRemoteNotifications];
            if (completion) completion();
        });
    }];
}

@end
