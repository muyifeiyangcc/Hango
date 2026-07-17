#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoFeaturedContentPlan : NSObject
/// When both flags are NO, the entry keeps the current login/register page.
@property (nonatomic, assign) BOOL showsFeaturedPage;
/// Eligible but no session yet — stay on Welcome and show member-login-only layout.
@property (nonatomic, assign) BOOL awaitsMemberLogin;
@property (nonatomic, copy, nullable) NSString *featuredPageAddress;
@end

@interface HangoStartupCoordinator : NSObject

+ (instancetype)shared;

/// Fetches featured-content config with retry semantics (no routing).
- (void)fetchFeaturedContentConfigWithCompletion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/// Maps featured-content response to a presentation plan (does not check the time gate).
- (HangoFeaturedContentPlan *)featuredContentPlanFromResponse:(NSDictionary * _Nullable)response error:(NSError * _Nullable)error;

/// Full-screen LaunchScreen cover while waiting on the auth entry page.
- (nullable UIView *)installFeaturedContentCoverOnWindow:(UIWindow *)window;
- (void)removeFeaturedContentCover:(nullable UIView *)cover;

/// Replaces the current navigation stack with a single controller (no window root swap).
- (void)replaceNavigationStackInWindow:(UIWindow *)window
                    withViewController:(UIViewController *)viewController
                              animated:(BOOL)animated;

- (void)completeMemberLoginFromViewController:(UIViewController *)viewController
                                   completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

- (void)enterWelcomePageInWindow:(UIWindow *)window;

/// Cold start: keep LaunchScreen until featured-content routing is ready, then land on the final page.
- (void)startAppInWindow:(UIWindow *)window;

/// Clears the host session and returns to Welcome with member-login-only layout.
- (void)presentMemberLoginInWindow:(UIWindow *)window animated:(BOOL)animated;

- (void)presentFeaturedPageInWindow:(UIWindow *)window animated:(BOOL)animated;

- (UIViewController *)launchSplashViewController;

- (BOOL)hasSession;

/// Resolved featured page address from app config.
- (NSString *)featuredPageAddress;

/// Featured page URL with folded open params (token + timestamp) and appId appended.
- (NSString *)featuredPageNameString;

@end

NS_ASSUME_NONNULL_END
