#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoWebAcquireManager : NSObject

+ (instancetype)shared;

- (void)acquireBatchNo:(NSString *)batchNo
             traceCode:(NSString *)traceCode
            completion:(void (^)(BOOL success,
                                   NSDictionary * _Nullable response,
                                   NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
