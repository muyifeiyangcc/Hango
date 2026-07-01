#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoIAPManager : NSObject

+ (instancetype)shared;

- (void)start;

- (BOOL)canMakePayments;

- (void)requestProductsWithCompletion:(nullable void (^)(void))completion;

- (NSString *)localizedPriceForProductId:(NSString *)productId fallback:(NSString *)fallback;

- (NSInteger)sparklesForProductId:(NSString *)productId;

- (void)purchaseProductId:(NSString *)productId
                  success:(void (^)(NSInteger sparkles))success
                  failure:(void (^)(NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
