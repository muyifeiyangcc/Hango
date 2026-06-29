#import "HangoAppRouter.h"
#import "HangoMainTabBarController.h"
#import "HangoWelcomeViewController.h"
#import "HangoTabBarView.h"

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
    tab.selectedIndex = tabIndex;
    [self setRootViewController:tab animated:YES];
}

+ (void)showWelcome {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[HangoWelcomeViewController alloc] init]];
    nav.navigationBarHidden = YES;
    [self setRootViewController:nav animated:YES];
}

@end
