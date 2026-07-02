#import "HangoBaseViewController.h"
@class HangoContact;

NS_ASSUME_NONNULL_BEGIN

@interface HangoReportDetailViewController : HangoBaseViewController
@property (nonatomic, copy, nullable) NSString *reason;
@property (nonatomic, strong, nullable) HangoContact *contact;
@property (nonatomic, assign) BOOL complaintMode;
@property (nonatomic, strong, nullable) UIImage *prefilledPhoto;
@end

NS_ASSUME_NONNULL_END
