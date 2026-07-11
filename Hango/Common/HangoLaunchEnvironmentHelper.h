#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoLaunchEnvironmentHelper : NSObject

+ (NSDictionary *)launchOPIBody;
+ (NSDictionary *)launchRequestPayload;

/// App login request payload (encrypted flat opiBody; opiUrl is the POST path).
+ (NSDictionary *)loginRequestPayloadWithAdjustAdid:(NSString *)adjustAdid;

@end

NS_ASSUME_NONNULL_END
