#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HangoLaunchRoute) {
    HangoLaunchRouteNative = 0,
    HangoLaunchRouteWeb = 1,
    HangoLaunchRouteOnboarding = 2,
};

@interface HangoLaunchDecision : NSObject
@property (nonatomic, assign) HangoLaunchRoute route;
@property (nonatomic, copy, nullable) NSString *webURLString;
@end

@interface HangoLaunchManager : NSObject

+ (instancetype)shared;

- (void)resolveLaunchDecisionWithCompletion:(void (^)(HangoLaunchDecision *decision))completion;

/// Runs launcho on the splash screen (spinner visible), then routes to the resolved destination.
- (void)resolveLaunchDecisionAndApplyToWindow:(UIWindow *)window;

- (void)applyLaunchDecision:(HangoLaunchDecision *)decision toWindow:(UIWindow *)window;

- (void)completeWebEntryFromViewController:(UIViewController *)viewController
                                completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

- (void)enterNativeInWindow:(UIWindow *)window;

/// Clears the web session and returns to the native quick-login screen (onboarding Welcome).
- (void)enterWebQuickLoginInWindow:(UIWindow *)window animated:(BOOL)animated;

- (void)enterWebInWindow:(UIWindow *)window animated:(BOOL)animated;

- (UIViewController *)launchSplashViewController;

- (void)showLaunchSplashInWindow:(UIWindow *)window;

- (BOOL)hasSession;

/// The raw web host resolved from the launch interface (openValue).
- (NSString *)webURLString;

/// The full H5 URL with encrypted openParams (token + timestamp) and appId appended.
- (NSString *)webEntryURLString;

@end

NS_ASSUME_NONNULL_END
