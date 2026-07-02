#import <UIKit/UIKit.h>
#import "HangoPersona.h"

NS_ASSUME_NONNULL_BEGIN

@interface HangoSessionManager : NSObject

@property (nonatomic, assign, readonly) BOOL isLoggedIn;
@property (nonatomic, assign, readonly) BOOL isGuest;
@property (nonatomic, strong, readonly) HangoPersona *currentPersona;

+ (instancetype)shared;

- (void)enterGuestMode;
- (void)exitGuestMode;
+ (BOOL)requireAuthenticationFromViewController:(UIViewController *)viewController;

- (BOOL)loginWithEmail:(NSString *)email password:(NSString *)password error:(NSError * _Nullable * _Nullable)error;
- (BOOL)registerWithEmail:(NSString *)email password:(NSString *)password error:(NSError * _Nullable * _Nullable)error;
- (void)loginWithAppleCredentialIdentifier:(NSString *)personaIdentifier
                               email:(nullable NSString *)email
                         displayName:(nullable NSString *)displayName;
- (void)updateProfileWithName:(NSString *)name avatarName:(NSString *)avatarName bio:(NSString *)bio;
- (void)updateProfileWithName:(NSString *)name avatarImage:(nullable UIImage *)avatarImage;
- (void)logout;
- (void)deleteAccount;

@end

NS_ASSUME_NONNULL_END
