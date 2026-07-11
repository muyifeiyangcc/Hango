#import "HangoLaunchPermissionManager.h"

@implementation HangoLaunchPermissionManager

+ (void)ensureNetworkAccessFromViewController:(UIViewController *)viewController
                                   completion:(HangoNetworkAccessHandler)completion {
    (void)viewController;
    if (completion) {
        completion(YES);
    }
}

@end
