#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoParcel : NSObject

+ (nullable NSString *)foldText:(NSString *)text error:(NSError * _Nullable * _Nullable)error;
+ (NSString *)openBlob:(NSString *)blob;

@end

NS_ASSUME_NONNULL_END
