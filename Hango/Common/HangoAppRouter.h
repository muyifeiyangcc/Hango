#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoAppRouter : NSObject

+ (UIWindow * _Nullable)keyWindow;
+ (UIViewController * _Nullable)topViewController;
+ (void)setRootViewController:(UIViewController *)viewController animated:(BOOL)animated;
+ (UIViewController *)authEntryViewController;
+ (void)showMainTabBar;
+ (void)showMainTabBarSelectingProfileTab;
+ (void)showAuthEntry;
+ (void)showWelcome;
+ (void)showWebShellAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
