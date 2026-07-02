#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const HangoAccountErrorDomain;

typedef NS_ENUM(NSInteger, HangoAccountErrorCode) {
    HangoAccountErrorCodeNotRegistered = 1,
    HangoAccountErrorCodeIncorrectPassword = 2,
    HangoAccountErrorCodeAlreadyRegistered = 3,
    HangoAccountErrorCodeInvalidEmail = 4,
    HangoAccountErrorCodePasswordRequired = 5,
};

@interface HangoAccountStore : NSObject

+ (instancetype)shared;

- (NSString *)normalizedEmail:(NSString *)email;
- (BOOL)isRegisteredEmail:(NSString *)email;
- (BOOL)isSeedTestAccountEmail:(NSString *)email;
- (BOOL)registerEmail:(NSString *)email password:(NSString *)password error:(NSError * _Nullable * _Nullable)error;
- (BOOL)validateLoginWithEmail:(NSString *)email password:(NSString *)password error:(NSError * _Nullable * _Nullable)error;
- (BOOL)updatePasswordForEmail:(NSString *)email password:(NSString *)password error:(NSError * _Nullable * _Nullable)error;
- (void)removeAccountWithEmail:(NSString *)email;

@end

NS_ASSUME_NONNULL_END
