#import "HangoKeychainManager.h"
#import <Security/Security.h>

static NSString * const kHangoKeychainService = @"com.hango.hty.keychain";

@implementation HangoKeychainManager

+ (NSMutableDictionary *)queryForKey:(NSString *)key {
    return [@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kHangoKeychainService,
        (__bridge id)kSecAttrAccount: key,
    } mutableCopy];
}

+ (NSString *)stringForKey:(NSString *)key {
    if (key.length == 0) {
        return @"";
    }

    NSMutableDictionary *query = [self queryForKey:key];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess || result == NULL) {
        return @"";
    }

    NSData *data = (__bridge_transfer NSData *)result;
    if (data.length == 0) {
        return @"";
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
}

+ (BOOL)deleteStringForKey:(NSString *)key {
    if (key.length == 0) {
        return NO;
    }
    NSMutableDictionary *query = [self queryForKey:key];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    return status == errSecSuccess || status == errSecItemNotFound;
}

+ (BOOL)setString:(NSString *)value forKey:(NSString *)key {
    if (key.length == 0) {
        return [self deleteStringForKey:key];
    }

    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return NO;
    }

    NSMutableDictionary *query = [self queryForKey:key];
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
    if (status == errSecSuccess) {
        NSDictionary *attributes = @{(__bridge id)kSecValueData: data};
        status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributes);
        return status == errSecSuccess;
    }

    query[(__bridge id)kSecValueData] = data;
    query[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
    status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    return status == errSecSuccess;
}

@end
