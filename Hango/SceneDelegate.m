#import "SceneDelegate.h"
#import "HangoTheme.h"
#import "HangoStartupCoordinator.h"
#import "AppDelegate.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.backgroundColor = [HangoTheme backgroundTopColor];
    ((AppDelegate *)UIApplication.sharedApplication.delegate).window = self.window;

    HangoStartupCoordinator *startupCoordinator = [HangoStartupCoordinator shared];
    [startupCoordinator startAppInWindow:self.window];
}

@end
