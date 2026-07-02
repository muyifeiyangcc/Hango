#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Central gate for guest / unauthenticated users.
/// Call before any action that requires a logged-in account.
@interface HangoGuestGuard : NSObject

/// YES when the user is a guest or not logged in.
+ (BOOL)needsLogin;

/// If login is required, navigates to `HangoWelcomeViewController` and returns NO.
/// Returns YES when the action may continue.
+ (BOOL)requireLogin;

@end

NS_ASSUME_NONNULL_END
