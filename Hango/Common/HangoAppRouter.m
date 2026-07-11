#import "HangoAppRouter.h"
#import "HangoMainTabBarController.h"
#import "HangoWelcomeViewController.h"
#import "HangoEULAViewController.h"
#import "HangoEULAAcceptance.h"
#import "HangoTabBarView.h"
#import "HangoWebShellViewController.h"
#import "HangoLaunchManager.h"

@implementation HangoAppRouter

+ (UIWindow *)keyWindow {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) return window;
        }
    }
    return UIApplication.sharedApplication.windows.firstObject;
}

+ (UIViewController *)topViewController {
    return [self topViewControllerFrom:[self keyWindow].rootViewController];
}

+ (UIViewController *)topViewControllerFrom:(UIViewController *)viewController {
    if (!viewController) {
        return nil;
    }
    if (viewController.presentedViewController) {
        return [self topViewControllerFrom:viewController.presentedViewController];
    }
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        return [self topViewControllerFrom:[(UINavigationController *)viewController topViewController]];
    }
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        return [self topViewControllerFrom:[(UITabBarController *)viewController selectedViewController]];
    }
    return viewController;
}

+ (void)setRootViewController:(UIViewController *)viewController animated:(BOOL)animated {
    UIWindow *window = [self keyWindow];
    if (!window) return;
    if (!animated) {
        window.rootViewController = viewController;
        [window makeKeyAndVisible];
        return;
    }
    UIViewController *fromVC = window.rootViewController;
    window.rootViewController = viewController;
    [window makeKeyAndVisible];
    if (fromVC.view.window) {
        [UIView transitionFromView:fromVC.view
                            toView:viewController.view
                          duration:0.35
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        completion:nil];
    }
}

+ (void)showMainTabBar {
    [self showMainTabBarSelectingTab:HangoTabIndexHome];
}

+ (void)showMainTabBarSelectingProfileTab {
    [self showMainTabBarSelectingTab:HangoTabIndexProfile];
}

+ (void)showMainTabBarSelectingTab:(HangoTabIndex)tabIndex {
    HangoMainTabBarController *tab = [HangoMainTabBarController mainTabBarController];
    [self setRootViewController:tab animated:YES];
    tab.selectedIndex = tabIndex;
    if (tabIndex < tab.viewControllers.count) {
        UINavigationController *nav = tab.viewControllers[tabIndex];
        [nav popToRootViewControllerAnimated:NO];
    }
}

+ (UINavigationController *)welcomeNavigationController {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[HangoWelcomeViewController alloc] init]];
    nav.navigationBarHidden = YES;
    return nav;
}

+ (UINavigationController *)launchEULANavigationController {
    HangoEULAViewController *eula = [[HangoEULAViewController alloc] init];
    eula.isLaunchGate = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:eula];
    nav.navigationBarHidden = YES;
    return nav;
}

+ (UIViewController *)authEntryViewController {
    if ([HangoEULAAcceptance hasAcceptedLaunchEULA]) {
        return [self welcomeNavigationController];
    }
    return [self launchEULANavigationController];
}

+ (void)showAuthEntry {
    UIWindow *window = [self keyWindow];
    if (!window) {
        return;
    }
    UIViewController *root = window.rootViewController;
    if (root.presentedViewController) {
        [root dismissViewControllerAnimated:NO completion:nil];
    }
    [self setRootViewController:[self authEntryViewController] animated:YES];
}

+ (void)showWelcome {
    UIWindow *window = [self keyWindow];
    if (!window) {
        return;
    }
    UIViewController *root = window.rootViewController;
    if (root.presentedViewController) {
        [root dismissViewControllerAnimated:NO completion:nil];
    }
    [self setRootViewController:[self welcomeNavigationController] animated:YES];
}

+ (void)showWebShellAnimated:(BOOL)animated {
    [[HangoLaunchManager shared] enterWebInWindow:[self keyWindow] animated:animated];
}

@end
