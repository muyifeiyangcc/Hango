#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoEULAAcceptance : NSObject

+ (BOOL)hasAcceptedLaunchEULA;
+ (void)markLaunchEULAAccepted;
+ (void)clearLaunchEULAAccepted;

@end

NS_ASSUME_NONNULL_END
