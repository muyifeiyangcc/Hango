#import "SceneDelegate.h"
#import "HangoWelcomeViewController.h"
#import "HangoProfileSetupViewController.h"
#import "HangoSessionManager.h"
#import "HangoDataStore.h"
#import "HangoMainTabBarController.h"
#import "HangoTheme.h"
#import "HangoLaunchPermissionManager.h"
#import "HangoTabBarView.h"
#import "AppDelegate.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.backgroundColor = [HangoTheme backgroundTopColor];
    ((AppDelegate *)UIApplication.sharedApplication.delegate).window = self.window;

    if ([HangoSessionManager shared].isLoggedIn) {
        if ([[HangoDataStore shared] hasCompletedProfile]) {
            HangoMainTabBarController *tab = [HangoMainTabBarController mainTabBarController];
            tab.selectedIndex = HangoTabIndexHome;
            self.window.rootViewController = tab;
        } else {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[HangoProfileSetupViewController alloc] init]];
            nav.navigationBarHidden = YES;
            self.window.rootViewController = nav;
        }
    } else {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[HangoWelcomeViewController alloc] init]];
        nav.navigationBarHidden = YES;
        self.window.rootViewController = nav;
    }

    [self.window makeKeyAndVisible];

    dispatch_async(dispatch_get_main_queue(), ^{
        [HangoLaunchPermissionManager requestLaunchPermissionsIfNeededFromViewController:self.window.rootViewController];
    });
}

@end
