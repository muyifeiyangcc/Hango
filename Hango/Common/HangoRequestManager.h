#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^HangoRequestCompletion)(id _Nullable result, NSError * _Nullable error);

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

- (void)verifyIAPPurchaseWithProductId:(NSString *)productId
                         transactionId:(NSString *)transactionId
                              sparkles:(NSInteger)sparkles
                                personaId:(NSString *)personaId
                            completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
