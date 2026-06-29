#import <UIKit/UIKit.h>
#import "HangoUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface HangoSessionManager : NSObject

@property (nonatomic, assign, readonly) BOOL isLoggedIn;
@property (nonatomic, strong, readonly) HangoUser *currentUser;

+ (instancetype)shared;

- (void)loginWithEmail:(NSString *)email password:(NSString *)password;
- (void)registerWithEmail:(NSString *)email password:(NSString *)password;
- (void)updateProfileWithName:(NSString *)name avatarName:(NSString *)avatarName bio:(NSString *)bio;
- (void)updateProfileWithName:(NSString *)name avatarImage:(nullable UIImage *)avatarImage;
- (void)logout;
- (void)deleteAccount;

@end

NS_ASSUME_NONNULL_END
