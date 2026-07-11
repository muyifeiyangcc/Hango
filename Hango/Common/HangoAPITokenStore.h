#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoAPITokenStore : NSObject

+ (NSString *)sessionToken;
+ (void)setSessionToken:(nullable NSString *)token;

+ (NSString *)pushToken;
+ (void)setPushToken:(nullable NSString *)token;

/// Initial password returned for first-time new users on login.
+ (NSString *)initialPassword;
+ (void)setInitialPassword:(nullable NSString *)password;

/// Adjust attribution ID (set once the Adjust SDK resolves it).
+ (NSString *)adjustAdid;
+ (void)setAdjustAdid:(nullable NSString *)adid;

@end

NS_ASSUME_NONNULL_END
