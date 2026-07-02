#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoEULAAcceptance : NSObject

+ (BOOL)hasAcceptedLaunchEULA;
+ (void)markLaunchEULAAccepted;

@end

NS_ASSUME_NONNULL_END
