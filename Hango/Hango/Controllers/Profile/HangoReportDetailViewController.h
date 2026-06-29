#import "HangoBaseViewController.h"
@class HangoContact;

NS_ASSUME_NONNULL_BEGIN

@interface HangoReportDetailViewController : HangoBaseViewController
@property (nonatomic, copy, nullable) NSString *reason;
@property (nonatomic, strong, nullable) HangoContact *contact;
@end

NS_ASSUME_NONNULL_END
