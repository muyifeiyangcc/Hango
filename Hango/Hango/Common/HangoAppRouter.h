#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoAppRouter : NSObject

+ (UIWindow * _Nullable)keyWindow;
+ (void)setRootViewController:(UIViewController *)viewController animated:(BOOL)animated;
+ (void)showMainTabBar;
+ (void)showMainTabBarSelectingProfileTab;
+ (void)showWelcome;

@end

NS_ASSUME_NONNULL_END
