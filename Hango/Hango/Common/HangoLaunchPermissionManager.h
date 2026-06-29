#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoLaunchPermissionManager : NSObject

+ (void)requestLaunchPermissionsIfNeededFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
