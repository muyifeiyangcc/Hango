#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^HangoAppleSignInCompletion)(BOOL success, NSString * _Nullable displayName, NSError * _Nullable error);

@interface HangoAppleSignInManager : NSObject

+ (instancetype)shared;

- (void)signInFromViewController:(UIViewController *)viewController
                      completion:(HangoAppleSignInCompletion)completion;

+ (nullable UIImage *)avatarImageForDisplayName:(NSString *)displayName;

@end

NS_ASSUME_NONNULL_END
