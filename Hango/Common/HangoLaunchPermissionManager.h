#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^HangoNetworkAccessHandler)(BOOL allowed);

@interface HangoLaunchPermissionManager : NSObject

+ (void)requestLaunchPermissionsIfNeededFromViewController:(UIViewController *)viewController;
+ (BOOL)isNetworkAccessAllowed;
+ (void)ensureNetworkAccessFromViewController:(UIViewController *)viewController
                                   completion:(HangoNetworkAccessHandler)completion;

@end

NS_ASSUME_NONNULL_END
