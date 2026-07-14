#import "HangoAPITokenStore.h"
#import "HangoKeychainManager.h"

static NSString * const kHangoSessionTokenKeychainKey = @"hango.session.token";
static NSString * const kHangoInitialPasswordKeychainKey = @"hango.initial.password";

static NSString * const kHangoSessionTokenLegacyKey = @"HangoSessionToken";
static NSString * const kHangoInitialPasswordLegacyKey = @"HangoInitialPassword";

static NSString * const kHangoPushTokenKey = @"HangoPushToken";

@implementation HangoAPITokenStore

+ (NSString *)migratedKeychainStringForKey:(NSString *)keychainKey legacyUserDefaultsKey:(NSString *)legacyKey {
    NSString *stored = [HangoKeychainManager stringForKey:keychainKey];
    if (stored.length > 0) {
        return stored;
    }

    NSString *legacy = [NSUserDefaults.standardUserDefaults stringForKey:legacyKey];
    if (legacy.length == 0) {
        return @"";
    }

    [HangoKeychainManager setString:legacy forKey:keychainKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:legacyKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    return legacy;
}

+ (NSString *)sessionToken {
    return [self migratedKeychainStringForKey:kHangoSessionTokenKeychainKey
                        legacyUserDefaultsKey:kHangoSessionTokenLegacyKey];
}

+ (void)setSessionToken:(NSString *)token {
    if (token.length == 0) {
        [HangoKeychainManager deleteStringForKey:kHangoSessionTokenKeychainKey];
        [NSUserDefaults.standardUserDefaults removeObjectForKey:kHangoSessionTokenLegacyKey];
    } else {
        [HangoKeychainManager setString:token forKey:kHangoSessionTokenKeychainKey];
        [NSUserDefaults.standardUserDefaults removeObjectForKey:kHangoSessionTokenLegacyKey];
    }
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (NSString *)pushToken {
    return [NSUserDefaults.standardUserDefaults stringForKey:kHangoPushTokenKey] ?: @"";
}

+ (void)setPushToken:(NSString *)token {
    if (token.length == 0) {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:kHangoPushTokenKey];
    } else {
        [NSUserDefaults.standardUserDefaults setObject:token forKey:kHangoPushTokenKey];
    }
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (NSString *)initialPassword {
    return [self migratedKeychainStringForKey:kHangoInitialPasswordKeychainKey
                        legacyUserDefaultsKey:kHangoInitialPasswordLegacyKey];
}

+ (void)setInitialPassword:(NSString *)password {
    if (password.length == 0) {
        [HangoKeychainManager deleteStringForKey:kHangoInitialPasswordKeychainKey];
        [NSUserDefaults.standardUserDefaults removeObjectForKey:kHangoInitialPasswordLegacyKey];
    } else {
        [HangoKeychainManager setString:password forKey:kHangoInitialPasswordKeychainKey];
        [NSUserDefaults.standardUserDefaults removeObjectForKey:kHangoInitialPasswordLegacyKey];
    }
    [NSUserDefaults.standardUserDefaults synchronize];
}

@end
