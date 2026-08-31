#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoSignalTrail : NSObject

+ (void)prepareForApplication:(UIApplication *)application launchOptions:(nullable NSDictionary *)launchOptions;
+ (void)markActiveScene;
+ (void)relayRemoteDeviceToken:(NSData *)deviceToken;
+ (void)currentAttributionMarkWithCompletion:(void (^)(NSString *mark))completion;
+ (void)recordStoreMilestoneWithReference:(NSString *)reference
                                     item:(NSString *)item
                                   amount:(nullable NSDecimalNumber *)amount
                                 currency:(NSString *)currency;

@end

NS_ASSUME_NONNULL_END
