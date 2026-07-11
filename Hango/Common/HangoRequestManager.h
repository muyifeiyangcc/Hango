#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^HangoRequestCompletion)(id _Nullable result, NSError * _Nullable error);
typedef void(^HangoAPIResponseHandler)(NSDictionary * _Nullable response, NSError * _Nullable error);

@interface HangoRequestManager : NSObject

+ (instancetype)shared;

- (void)requestWithDelay:(NSTimeInterval)delay
                  inView:(nullable UIView *)view
                showsHUD:(BOOL)showsHUD
               operation:(id _Nullable (^)(void))operation
              completion:(HangoRequestCompletion)completion;

- (void)requestWithDelay:(NSTimeInterval)delay
                  inView:(nullable UIView *)view
                showsHUD:(BOOL)showsHUD
              completion:(dispatch_block_t)completion;

- (void)fetchAppConfigWithCompletion:(HangoAPIResponseHandler)completion;

- (void)fetchLaunchEligibilityWithCompletion:(HangoAPIResponseHandler)completion;

/// Recreates the launch URL session so DNS/connectivity state refreshes after the iOS wireless-data prompt.
- (void)resetNetworkSessionForLaunchRetry;

/// Cancels the in-flight launch request (e.g. watchdog timeout).
- (void)cancelLaunchRequest;

/// Forces a fresh DNS lookup for the API host before launcho (bypasses stale URLSession DNS cache).
- (void)preflightDNSForAPIHostWithCompletion:(void (^)(BOOL resolved))completion;

- (void)submitAuthWithParameters:(NSDictionary *)parameters
                          inView:(nullable UIView *)view
                        showsHUD:(BOOL)showsHUD
                      completion:(HangoAPIResponseHandler)completion;

- (void)reportWebLoadDurationMs:(NSTimeInterval)durationMs
                     completion:(nullable HangoAPIResponseHandler)completion;

/// Server-side confirmation for web-initiated StoreKit flows.
- (void)confirmWebAcquireWithTicket:(NSString *)ticket
                          credential:(NSString *)credential
                           traceCode:(NSString *)traceCode
                          completion:(HangoAPIResponseHandler)completion;

- (void)verifyIAPPurchaseWithProductId:(NSString *)productId
                         transactionId:(NSString *)transactionId
                              sparkles:(NSInteger)sparkles
                             personaId:(NSString *)personaId
                            completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
