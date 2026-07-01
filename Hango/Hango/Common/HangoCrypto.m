#import "HangoCrypto.h"
#import <CommonCrypto/CommonCrypto.h>

static NSString * const kHangoIAPSignKey = @"hango_iap_secret_2026";

@implementation HangoCrypto

+ (NSString *)md5FromString:(NSString *)string {
    if (string.length == 0) {
        return @"";
    }
    const char *value = string.UTF8String;
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output.copy;
}

+ (NSString *)iapSignWithPersonaId:(NSString *)personaId
                      productId:(NSString *)productId
                  transactionId:(NSString *)transactionId
                       sparkles:(NSInteger)sparkles
                      timestamp:(NSInteger)timestamp {
    NSString *raw = [NSString stringWithFormat:@"sparkles=%ld&productId=%@&timestamp=%ld&transactionId=%@&personaId=%@%@",
                     (long)sparkles,
                     productId ?: @"",
                     (long)timestamp,
                     transactionId ?: @"",
                     personaId ?: @"",
                     kHangoIAPSignKey];
    return [self md5FromString:raw];
}

@end
