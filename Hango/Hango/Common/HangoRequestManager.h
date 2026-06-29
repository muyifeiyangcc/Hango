#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^HangoRequestCompletion)(id _Nullable result, NSError * _Nullable error);

@interface HangoRequestManager : NSObject

+ (instancetype)shared;

- (void)requestWithDelay:(NSTimeInterval)delay
                  inView:(nullable UIView *)view
               operation:(id _Nullable (^)(void))operation
              completion:(HangoRequestCompletion)completion;

- (void)requestWithDelay:(NSTimeInterval)delay
                  inView:(nullable UIView *)view
              completion:(dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
