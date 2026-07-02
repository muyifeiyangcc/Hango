#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoCrypto : NSObject

+ (NSString *)md5FromString:(NSString *)string;

+ (NSString *)iapSignWithPersonaId:(NSString *)personaId
                      productId:(NSString *)productId
                  transactionId:(NSString *)transactionId
                       sparkles:(NSInteger)sparkles
                      timestamp:(NSInteger)timestamp;

@end

NS_ASSUME_NONNULL_END
