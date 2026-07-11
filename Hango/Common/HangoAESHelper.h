#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoAESHelper : NSObject

+ (nullable NSString *)encryptString:(NSString *)plaintext error:(NSError * _Nullable * _Nullable)error;
+ (NSString *)decryptString:(NSString *)cipherHex;

@end

NS_ASSUME_NONNULL_END
