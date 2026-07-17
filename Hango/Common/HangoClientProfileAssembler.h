#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Locale, device, and connectivity fields sent with app config / sign-in requests.
@interface HangoClientProfileAssembler : NSObject

+ (NSDictionary *)clientPreferencesFields;
+ (NSDictionary *)appConfigRequestBody;

/// Sign-in body (device id and related client fields).
+ (NSDictionary *)signInRequestParameters;

@end

NS_ASSUME_NONNULL_END
