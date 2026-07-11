#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoKeychainManager : NSObject

+ (NSString *)stringForKey:(NSString *)key;
+ (BOOL)setString:(NSString *)value forKey:(NSString *)key;
+ (BOOL)deleteStringForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
