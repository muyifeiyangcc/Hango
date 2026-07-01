#import "HangoLaunchPermissionManager.h"
#import <UserNotifications/UserNotifications.h>

static NSString * const kHangoLaunchPermissionsDoneKey = @"HangoLaunchPermissionsDone";
static NSString * const kHangoNetworkAccessAllowedKey = @"HangoNetworkAccessAllowed";

@implementation HangoLaunchPermissionManager

+ (BOOL)isNetworkAccessAllowed {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kHangoNetworkAccessAllowedKey]) {
        return NO;
    }
    return [NSUserDefaults.standardUserDefaults boolForKey:kHangoNetworkAccessAllowedKey];
}

+ (void)setNetworkAccessAllowed:(BOOL)allowed {
    [NSUserDefaults.standardUserDefaults setBool:allowed forKey:kHangoNetworkAccessAllowedKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (void)requestLaunchPermissionsIfNeededFromViewController:(UIViewController *)viewController {
    if (!viewController) return;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kHangoLaunchPermissionsDoneKey]) return;

    [self showNetworkPermissionAlertFrom:viewController completion:^{
        [self requestAppleNotificationPermissionWithCompletion:^{
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHangoLaunchPermissionsDoneKey];
        }];
    }];
}

+ (void)ensureNetworkAccessFromViewController:(UIViewController *)viewController
                                   completion:(HangoNetworkAccessHandler)completion {
    if ([self isNetworkAccessAllowed]) {
        if (completion) {
            completion(YES);
        }
        return;
    }

    if ([[NSUserDefaults standardUserDefaults] objectForKey:kHangoNetworkAccessAllowedKey]) {
        [self showNetworkRequiredAlertFrom:viewController completion:completion];
        return;
    }

    [self showNetworkPermissionAlertFrom:viewController completion:^{
        if ([self isNetworkAccessAllowed]) {
            if (completion) {
                completion(YES);
            }
        } else {
            [self showNetworkRequiredAlertFrom:viewController completion:completion];
        }
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
                                                                   message:@"Hango needs network access to sync parties, dialogues, and your profile."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"WLAN & Cellular" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self setNetworkAccessAllowed:YES];
        if (completion) completion();
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"WLAN Only" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self setNetworkAccessAllowed:YES];
        if (completion) completion();
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Don't Allow" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
        [self setNetworkAccessAllowed:NO];
        if (completion) completion();
    }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

+ (void)showNetworkRequiredAlertFrom:(UIViewController *)viewController completion:(HangoNetworkAccessHandler)completion {
    UIViewController *presenter = [self presentingControllerFrom:viewController];
    if (!presenter) {
        if (completion) {
            completion(NO);
        }
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network Access Required"
                                                                   message:@"Please allow network access to sign in or create an account."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
        if (completion) {
            completion(NO);
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Allow Network" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self showNetworkPermissionAlertFrom:viewController completion:^{
            if ([self isNetworkAccessAllowed]) {
                if (completion) {
                    completion(YES);
                }
            } else if (completion) {
                completion(NO);
            }
        }];
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
