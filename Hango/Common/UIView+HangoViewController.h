#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (HangoViewController)
- (nullable UIViewController *)hango_nearestViewController;
/// Returns YES when the action may proceed. Guests are sent to Welcome.
- (BOOL)hango_requireLoginForAction;
@end

NS_ASSUME_NONNULL_END
